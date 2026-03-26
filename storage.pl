% -------------------------------------------------
% STORAGE.PL ( SQL VERSION ) FIXED VER
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
        retractall(borrower(_, _, _, _, _, _)),
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
            odbc_query(opac, 'SELECT student_number, surname, first_name, middle_initial, department, password FROM borrowers', row(StudentNo, Surname, FirstName, MiddleInitial, Dept, P)),
            assertz(borrower(StudentNo, Surname, FirstName, MiddleInitial, Dept, P))
        ),

        % 4. Load Loans (Handles SQL NULL mapping to Prolog 'none')
        forall(
            odbc_query(opac, 
                                'SELECT loan_id, book_id, student_number, date_borrowed, due_date, date_returned FROM loans', 
                                row(LID, BID, StudentNo, DB, DD, DR)),
            ( (DR == @(null) -> Ret = none ; Ret = DR),
                            assertz(loan(LID, BID, StudentNo, DB, DD, Ret)) )
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
    
    catch((
        % 1. Clear SQL Tables before sync
        odbc_query(opac, 'DELETE FROM loans'),
        odbc_query(opac, 'DELETE FROM books'),
        odbc_query(opac, 'DELETE FROM borrowers'),
        odbc_query(opac, 'DELETE FROM librarians'),

        % 2. Sync Books
        forall(book(ID, T, A, Y, C, D),
               ( format(atom(SQL), 'INSERT INTO books VALUES (~w, \'~w\', \'~w\', ~w, ~w, ~w)', [ID, T, A, Y, C, D]),
                 odbc_query(opac, SQL) )),

         % 3. Sync Borrowers
         forall(borrower(StudentNo, Surname, FirstName, MiddleInitial, Dept, P),
             ( format(atom(SQL), 'INSERT INTO borrowers (student_number, surname, first_name, middle_initial, department, password) VALUES (~w, \'~w\', \'~w\', \'~w\', \'~w\', \'~w\')', [StudentNo, Surname, FirstName, MiddleInitial, Dept, P]),
                 odbc_query(opac, SQL) )),

        % 4. Sync Loans (Map 'none' back to SQL NULL)
        forall(loan(LID, BID, BrID, DB, DD, Ret),
               ( Ret == none ->
                   format(atom(SQL), 'INSERT INTO loans VALUES (~w, ~w, ~w, \'~w\', \'~w\', NULL)', [LID, BID, BrID, DB, DD]),
                   odbc_query(opac, SQL)
                 ; format(atom(SQL), 'INSERT INTO loans VALUES (~w, ~w, ~w, \'~w\', \'~w\', \'~w\')', [LID, BID, BrID, DB, DD, Ret]),
                   odbc_query(opac, SQL)
               )),

        % 5. Sync Librarians
        forall(librarian(ID, N, P),
               ( format(atom(SQL), 'INSERT INTO librarians VALUES (~w, \'~w\', \'~w\')', [ID, N, P]),
                 odbc_query(opac, SQL) )),

        % 6. If all successful
        write('>> [SUCCESS] Database updated.'), nl,
        disconnect_db
    ), 
    Error, 
    (
        format('>> [SAVE ERROR] Failed to update database: ~w~n', [Error]),
        disconnect_db,
        fail  % Fail the save_data predicate on error
    )).