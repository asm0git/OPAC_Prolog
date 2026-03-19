% -------------------------------------------------
% STORAGE.PL (FINAL SQL VERSION - 6DIPROGLANG & 6IMAN COMPLIANT)
% -------------------------------------------------
:- use_module(library(odbc)).

% -------------------------------------------------
% DATABASE CONNECTION MANAGEMENT
% -------------------------------------------------

connect_db :-
    % open(once) prevents errors if connect_db is called multiple times
    odbc_connect('opac_db', _, [alias(opac), open(once)]).

disconnect_db :-
    % Safely close only if the connection exists
    (odbc_current_connection(opac, _) -> odbc_disconnect(opac) ; true).

% -------------------------------------------------
% LOAD DATA FROM SQL → PROLOG (WITH EXPLICIT MAPPING)
% -------------------------------------------------

load_data :-
    write('--- Syncing from SQL Database ---'), nl,
    catch((
        connect_db,

        % 1. Clear current Prolog memory
        retractall(book(_, _, _, _, _, _)),
        retractall(borrower(_, _, _)),
        retractall(loan(_, _, _, _, _, _)),
        retractall(librarian(_, _, _)),

        % 2. Load Books (Explicit columns for stability)
        forall(
            odbc_query(opac, 
                'SELECT book_id, title, author, year_published, copies, dewey_decimal FROM books', 
                row(ID, T, A, Y, C, D)),
            assertz(book(ID, T, A, Y, C, D))
        ),

        % 3. Load Borrowers
        forall(
            odbc_query(opac, 'SELECT borrower_id, name, course FROM borrowers', row(ID, N, C)),
            assertz(borrower(ID, N, C))
        ),

        % 4. Load Loans (Handles SQL NULL mapping to Prolog 'none')
        forall(
            odbc_query(opac, 
                'SELECT loan_id, book_id, borrower_id, date_borrowed, due_date, date_returned FROM loans', 
                row(LID, BID, BrID, DB, DD, DR)),
            ( (DR == @(null) -> Ret = none ; Ret = DR),
              assertz(loan(LID, BID, BrID, DB, DD, Ret)) )
        ),

        % 5. Load Librarians
        forall(
            odbc_query(opac, 'SELECT librarian_id, name, position FROM librarians', row(ID, N, P)),
            assertz(librarian(ID, N, P))
        ),

        disconnect_db,
        write('>> [SUCCESS] SQL data loaded into Prolog memory.'), nl
    ), 
    Error, 
    (
        % Catch and display any ODBC or Logic errors
        format('>> [LOAD ERROR] Failed to sync SQL: ~w~n', [Error]),
        disconnect_db,
        fail % Signal to app.pl that loading failed
    )).

% -------------------------------------------------
% SAVE DATA FROM PROLOG → SQL (WITH TRANSACTION CONTROL)
% -------------------------------------------------

save_data :-
    write('--- Saving to SQL Database ---'), nl,
    connect_db,
    
    % Turn off autocommit to treat the following as a single Atomic Transaction
    odbc_set_connection(opac, autocommit(false)),
    
    catch((
        % 1. Clear SQL Tables before sync
        odbc_query(opac, 'DELETE FROM loans'),
        odbc_query(opac, 'DELETE FROM books'),
        odbc_query(opac, 'DELETE FROM borrowers'),
        odbc_query(opac, 'DELETE FROM librarians'),

        % 2. Sync Books
        forall(book(ID, T, A, Y, C, D),
               odbc_query(opac, 'INSERT INTO books VALUES (?,?,?,?,?,?)', [ID, T, A, Y, C, D])),

        % 3. Sync Borrowers
        forall(borrower(ID, N, C),
               odbc_query(opac, 'INSERT INTO borrowers VALUES (?,?,?)', [ID, N, C])),

        % 4. Sync Loans (Map 'none' back to SQL NULL)
        forall(loan(LID, BID, BrID, DB, DD, Ret),
               ( (Ret == none -> SQLRet = @(null) ; SQLRet = Ret),
                 odbc_query(opac, 'INSERT INTO loans VALUES (?,?,?,?,?,?)', [LID, BID, BrID, DB, DD, SQLRet]) )),

        % 5. Sync Librarians
        forall(librarian(ID, N, P),
               odbc_query(opac, 'INSERT INTO librarians VALUES (?,?,?)', [ID, N, P])),

        % 6. If all successful, Commit
        odbc_commit(opac),
        write('>> [SUCCESS] Database transaction committed.'), nl
    ), 
    Error, 
    (
        % If ANY insert fails, undo everything to prevent partial data (Data Integrity)
        odbc_rollback(opac),
        format('>> [SAVE ERROR] Transaction rolled back: ~w~n', [Error])
    )),
    
    % Restore connection state and close
    odbc_set_connection(opac, autocommit(true)),
    disconnect_db.