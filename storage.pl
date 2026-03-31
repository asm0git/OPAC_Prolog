% -------------------------------------------------
% STORAGE.PL ( SQL VERSION ) FIXED VER
% Bridge layer between SQL tables and dynamic Prolog facts.
% All app modules read/write facts in memory; this file handles
% loading from SQL at startup and saving back on exit.
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
        retractall(book(_, _, _, _, _, _, _)),
        retractall(borrower(_, _, _, _, _, _)),
        retractall(loan(_, _, _, _, _, _, _)),
        retractall(librarian(_, _, _, _, _, _)),

        % 2. Load Books
        forall(
            odbc_query(opac, 
                'SELECT book_id, title, author, year_published, copies, dewey_decimal, added_by_staff_number FROM books', 
                row(RawID, T, A, RawY, RawC, RawD, RawAddedBy)),
            (
                to_integer_value(RawID, ID),
                to_integer_value(RawY, Y),
                to_integer_value(RawC, C),
                to_number(RawD, D),
                ( sql_null_value(RawAddedBy) ->
                    AddedBy = none
                ; atom(RawAddedBy) ->
                    AddedBy = RawAddedBy
                ; atom_string(AddedBy, RawAddedBy)
                ),
                assertz(book(ID, T, A, Y, C, D, AddedBy))
            )
        ),

        % 3. Load Borrowers
        forall(
            odbc_query(opac, 'SELECT student_number, surname, first_name, middle_initial, department, password FROM borrowers', row(RawStudentNo, Surname, FirstName, MiddleInitial, Dept, P)),
            (
                to_integer_value(RawStudentNo, StudentNo),
                assertz(borrower(StudentNo, Surname, FirstName, MiddleInitial, Dept, P))
            )
        ),

        % 4. Load Loans (uses explicit is_returned boolean)
        forall(
            odbc_query(opac, 
                                'SELECT loan_id, book_id, student_number, date_borrowed, due_date, date_returned, is_returned FROM loans', 
                                row(RawLID, RawBID, RawStudentNo, DB, DD, DR, RawReturnedFlag)),
                        ( to_iso_date(DB, BorrowedISO),
                            to_iso_date(DD, DueISO),
                            ( sql_null_value(DR) ->
                                        Ret = none
                                ; to_iso_date(DR, Ret)
                            ),
                            to_flag_value(RawReturnedFlag, ReturnedFlag),
                            to_integer_value(RawLID, LID),
                            to_integer_value(RawBID, BID),
                            to_integer_value(RawStudentNo, StudentNo),
                            assertz(loan(LID, BID, StudentNo, BorrowedISO, DueISO, Ret, ReturnedFlag)) )
        ),

        % 5. Load Librarians
        forall(
            odbc_query(opac, 'SELECT staff_number, surname, first_name, middle_initial, position, password FROM librarians', row(RawSN, Sur, FN, MI, Pos, Pwd)),
            (
                ( atom(RawSN) -> SN = RawSN ; atom_string(SN, RawSN) ),
                assertz(librarian(SN, Sur, FN, MI, Pos, Pwd))
            )
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
    (catch(connect_db, _, fail) -> true ; (write('>> [SAVE ERROR] Could not connect to database.'), nl, fail)),
    catch(save_data_impl, Error, handle_save_error(Error)).

save_data_impl :-
    % 1. Clear SQL tables
    odbc_query(opac, 'DELETE FROM loans'),
    odbc_query(opac, 'DELETE FROM books'),
    odbc_query(opac, 'DELETE FROM borrowers'),
    odbc_query(opac, 'DELETE FROM librarians'),
    
    % 2. Sync Librarians
    forall(librarian(SN, Sur, FN, MI, Pos, Pwd),
        (format(atom(SQL), 'INSERT INTO librarians (staff_number, surname, first_name, middle_initial, position, password) VALUES (~q, ~q, ~q, ~q, ~q, ~q)', [SN, Sur, FN, MI, Pos, Pwd]),
         odbc_query(opac, SQL))),
    
    % 3. Sync Books
    forall(book(ID, T, A, Y, C, D, AddedBy),
        ((AddedBy == none ->
            format(atom(SQL), 'INSERT INTO books (book_id, title, author, year_published, copies, dewey_decimal, added_by_staff_number) VALUES (~w, ~q, ~q, ~w, ~w, ~w, NULL)', [ID, T, A, Y, C, D])
         ;
            format(atom(SQL), 'INSERT INTO books (book_id, title, author, year_published, copies, dewey_decimal, added_by_staff_number) VALUES (~w, ~q, ~q, ~w, ~w, ~w, ~q)', [ID, T, A, Y, C, D, AddedBy])),
         odbc_query(opac, SQL))),
    
    % 4. Sync Borrowers
    forall(borrower(StudentNo, Surname, FirstName, MiddleInitial, Dept, P),
        (format(atom(SQL), 'INSERT INTO borrowers (student_number, surname, first_name, middle_initial, department, password) VALUES (~w, ~q, ~q, ~q, ~q, ~q)', [StudentNo, Surname, FirstName, MiddleInitial, Dept, P]),
         odbc_query(opac, SQL))),
    
    % 5. Sync Loans
    forall(loan(LID, BID, BrID, DB, DD, Ret, ReturnedFlag),
        (to_iso_date(DB, BorrowedISO),
         to_iso_date(DD, DueISO),
            (Ret == none ->
                (format(atom(SQL), 'INSERT INTO loans (loan_id, book_id, student_number, date_borrowed, due_date, date_returned, is_returned) VALUES (~w, ~w, ~w, \'~w\', \'~w\', NULL, ~w)', [LID, BID, BrID, BorrowedISO, DueISO, ReturnedFlag]),
                 odbc_query(opac, SQL))
             ;
                (to_iso_date(Ret, ReturnISO),
                 format(atom(SQL), 'INSERT INTO loans (loan_id, book_id, student_number, date_borrowed, due_date, date_returned, is_returned) VALUES (~w, ~w, ~w, \'~w\', \'~w\', \'~w\', ~w)', [LID, BID, BrID, BorrowedISO, DueISO, ReturnISO, ReturnedFlag]),
                 odbc_query(opac, SQL))))),
    
    write('>> [SUCCESS] Database updated.'), nl,
    disconnect_db.

handle_save_error(Error) :-
    format('>> [SAVE ERROR] Failed to update database: ~w~n', [Error]),
    disconnect_db,
    fail.

to_number(Value, Number) :-
    % Normalizes ODBC return values (atom/string/number) to a Prolog number.
    ( number(Value) ->
        Number = Value
    ; atom(Value) ->
        atom_number(Value, Number)
    ; string(Value) ->
        number_string(Number, Value)
    ; format(string(Text), '~w', [Value]),
      number_string(Number, Text)
    ).

to_integer_value(Value, Integer) :-
    % Accepts numeric input that may arrive as float and rounds if needed.
    to_number(Value, Number),
    ( integer(Number) ->
        Integer = Number
    ;
        Integer is round(Number)
    ).

to_flag_value(Value, Flag) :-
    % Maps SQL/null-ish values to strict 0/1 flag used by loan/7.
    ( sql_null_value(Value) ->
        Flag = 0
    ; to_integer_value(Value, Raw),
      ( Raw =:= 0 -> Flag = 0 ; Flag = 1 )
    ).

sql_null_value(Value) :-
    % Some ODBC drivers return SQL NULL as the atom '$null$'. Accept that
    % representation as well as other common null-ish strings.
    ( Value == '$null$' ; Value == @(null) ), !.
sql_null_value(Value) :-
    format(string(Text), '~w', [Value]),
    normalize_space(string(Clean), Text),
    string_lower(Clean, Lower),
    member(Lower, ["$null$", "null", "none", "", "0000-00-00", "0000-00-00 00:00:00"]).

to_iso_date(Value, ISO) :-
    % Converts supported SQL/Prolog date representations to YYYY-MM-DD atom.
    ( string(Value) ->
        normalize_space(string(T), Value),
        atom_string(ISO, T)
    ; atom(Value) ->
        atom_string(Value, S),
        normalize_space(string(T), S),
        atom_string(ISO, T)
    ; number(Value) ->
        number_string(Value, NText),
        atom_string(ISO, NText)
    ; compound(Value), Value =.. [date, Y, M, D] ->
        format(atom(ISO), '~|~`0t~d~4+-~|~`0t~d~2+-~|~`0t~d~2+', [Y, M, D])
    ; compound(Value), Value =.. [timestamp, Y, M, D|_] ->
        format(atom(ISO), '~|~`0t~d~4+-~|~`0t~d~2+-~|~`0t~d~2+', [Y, M, D])
    ;
        format(atom(ISO), '~w', [Value])
    ).