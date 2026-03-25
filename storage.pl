% -------------------------------------------------
% STORAGE.PL ( SQL VERSION )
% -------------------------------------------------
:- use_module(library(odbc)).

% -------------------------------------------------
% DATABASE CONNECTION MANAGEMENT
% -------------------------------------------------

connect_db :-
    % open(once) prevents errors if connect_db is called multiple times
    odbc_connect('opac_db', _, [alias(opac), open(once)]).

disconnect_db :-
    % Safely close ONLY if the connection actually exists (prevents existence_error crashes)
    ( catch(odbc_current_connection(opac, _), _, fail) -> 
        odbc_disconnect(opac) 
    ; true ).

% -------------------------------------------------
% LOAD DATA FROM SQL → PROLOG
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

        % 2. Load Books
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
        % Catch and display any ODBC or Logic errors, safely disconnect without crashing
        format('>> [LOAD ERROR] Failed to sync SQL: ~w~n', [Error]),
        disconnect_db
        % Note: 'fail' removed here so app.pl main_menu still loads even if DB is offline.
    )).

% -------------------------------------------------
% SAVE DATA FROM PROLOG → SQL (WITH TRANSACTION CONTROL)
% -------------------------------------------------

save_data :-
    write('--- Saving to SQL Database ---'), nl,
    ( catch(connect_db, _, fail) -> true ; write('>> [SAVE ERROR] Could not connect to database.'), nl, fail ),
    
    % Turn off autocommit to treat the following as a single Atomic Transaction
    catch(odbc_set_connection(opac, autocommit(false)), _, true),
    
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
               ( Ret == none ->
                   odbc_query(opac, 'INSERT INTO loans VALUES (?,?,?,?,?,NULL)', [LID, BID, BrID, DB, DD])
                 ; odbc_query(opac, 'INSERT INTO loans VALUES (?,?,?,?,?,?)', [LID, BID, BrID, DB, DD, Ret])
               )),

        % 5. Sync Librarians
        forall(librarian(ID, N, P),
               odbc_query(opac, 'INSERT INTO librarians VALUES (?,?,?)', [ID, N, P])),

        % 6. If all successful, Commit
        odbc_commit(opac),
        write('>> [SUCCESS] Database transaction committed.'), nl,
        catch(odbc_set_connection(opac, autocommit(true)), _, true),
        disconnect_db
    ), 
    Error, 
    (
        % If ANY insert fails, undo everything to prevent partial data (Data Integrity)
        catch(odbc_rollback(opac), _, true),
        format('>> [SAVE ERROR] Transaction rolled back: ~w~n', [Error]),
        catch(odbc_set_connection(opac, autocommit(true)), _, true),
        disconnect_db,
        fail  % Fail the save_data predicate on error
    )).