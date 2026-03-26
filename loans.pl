:- dynamic loan/6.
% loan(LoanID, BookID, StudentNumber, DateBorrowed, DueDate, DateReturned).

:- dynamic borrower/6.
% borrower(StudentNumber, Surname, FirstName, MiddleInitial, Department, Password).

%% parse_date(+'YYYY-MM-DD', -Y, -M, -D)
parse_date(DateStr, Y, M, D) :-
    sub_atom(DateStr, 0, 4, _, YA),
    sub_atom(DateStr, 5, 2, _, MA),
    sub_atom(DateStr, 8, 2, _, DA),
    atom_number(YA, Y),
    atom_number(MA, M),
    atom_number(DA, D).

%% make_date(+Y, +M, +D, -'YYYY-MM-DD')
make_date(Y, M, D, DateStr) :-
    format(atom(DateStr), '~`0t~w~4|-~`0t~w~2|-~`0t~w~2|', [Y, M, D]).

%% days_in_month(+Year, +Month, -Days)
days_in_month(_, 1,  31).
days_in_month(Y, 2,  Days) :-
    ( (0 =:= Y mod 4, 0 =\= Y mod 100) ; 0 =:= Y mod 400 )
    -> Days = 29 ; Days = 28.
days_in_month(_, 3,  31).
days_in_month(_, 4,  30).
days_in_month(_, 5,  31).
days_in_month(_, 6,  30).
days_in_month(_, 7,  31).
days_in_month(_, 8,  31).
days_in_month(_, 9,  30).
days_in_month(_, 10, 31).
days_in_month(_, 11, 30).
days_in_month(_, 12, 31).

%% month_days_accumulated(+Year, +Month, -Days)
month_days_accumulated(_, 1, 0) :- !.
month_days_accumulated(Y, M, Total) :-
    M > 1,
    M1 is M - 1,
    days_in_month(Y, M1, D),
    month_days_accumulated(Y, M1, Rest),
    Total is Rest + D.

%% date_to_days(+'YYYY-MM-DD', -TotalDays)
date_to_days(DateStr, Total) :-
    parse_date(DateStr, Y, M, D),
    Y1 is Y - 1,
    LeapYears is Y1 // 4 - Y1 // 100 + Y1 // 400,
    YearDays is Y1 * 365 + LeapYears,
    month_days_accumulated(Y, M, MonthDays),
    Total is YearDays + MonthDays + D.

%% days_between(+'YYYY-MM-DD', +'YYYY-MM-DD', -Diff)
%  Diff = Date2 - Date1. Positive if Date2 is later (overdue).
days_between(Date1, Date2, Diff) :-
    date_to_days(Date1, T1),
    date_to_days(Date2, T2),
    Diff is T2 - T1.

%% date_to_days_start(+Year, -TotalDays)
%  Total days up to Jan 1 of given year.
date_to_days_start(Y, Total) :-
    Y1 is Y - 1,
    LeapYears is Y1 // 4 - Y1 // 100 + Y1 // 400,
    Total is Y1 * 365 + LeapYears + 1.

%% find_year(+Y0, +Total, -Y)
find_year(Y, Total, Y) :-
    date_to_days_start(Y, Start),
    Y2 is Y + 1,
    date_to_days_start(Y2, End),
    Total >= Start, Total < End, !.
find_year(Y0, Total, Y) :-
    Y2 is Y0 + 1,
    date_to_days_start(Y2, End),
    Total >= End, !,
    find_year(Y2, Total, Y).
find_year(Y0, Total, Y) :-
    Y1 is Y0 - 1,
    find_year(Y1, Total, Y).

%% find_month(+Year, +Remaining, +M, -OutM, -OutD)
find_month(Year, Remaining, M, M, D) :-
    days_in_month(Year, M, DIM),
    Remaining < DIM, !,
    D is Remaining + 1.
find_month(Year, Remaining, M, OutM, OutD) :-
    days_in_month(Year, M, DIM),
    Remaining >= DIM, !,
    NewRem is Remaining - DIM,
    M1 is M + 1,
    find_month(Year, NewRem, M1, OutM, OutD).

%% days_from_epoch(+TotalDays, -'YYYY-MM-DD')
days_from_epoch(Total, DateStr) :-
    Y0 is Total // 365,
    find_year(Y0, Total, Y),
    date_to_days_start(Y, YStart),
    Remaining is Total - YStart,
    find_month(Y, Remaining, 1, M, D),
    make_date(Y, M, D, DateStr).

%% add_days_to_date(+'YYYY-MM-DD', +N, -'YYYY-MM-DD')
add_days_to_date(DateStr, N, NewDateStr) :-
    date_to_days(DateStr, Total),
    NewTotal is Total + N,
    days_from_epoch(NewTotal, NewDateStr).

%% get_today(-'YYYY-MM-DD')
get_today(DateStr) :-
    read_date('Enter today''s date (YYYY-MM-DD): ', DateStr).

read_date(Prompt, DateAtom) :-
    repeat,
    write(Prompt),
    read_line_to_string(user_input, Raw),
    normalize_space(string(Clean), Raw),
    atom_string(A, Clean),
    ( valid_date_format(A) ->
        DateAtom = A, !
    ;
        write('[ERROR] Enter a valid date in YYYY-MM-DD format (e.g. 2026-03-19).'), nl,
        fail
    ).

valid_date_format(A) :-
    atom_length(A, 10),
    sub_atom(A, 4, 1, _, '-'),
    sub_atom(A, 7, 1, _, '-'),
    parse_date(A, _, M, D),
    M >= 1, M =< 12,
    D >= 1, D =< 31.

%% next_loan_id(-ID)
next_loan_id(ID) :-
    findall(N, loan(N, _, _, _, _, _), IDs),
    ( IDs = [] -> ID = 1 ; max_list(IDs, Max), ID is Max + 1 ).

% =============================================================
% SQL HELPERS
% =============================================================

sql_insert_loan(LID, BkID, StudentNo, Borrowed, Due) :-
    catch((
        connect_db,
        format(atom(SQL), 'INSERT INTO loans (loan_id, book_id, student_number, date_borrowed, due_date, date_returned) VALUES (~w, ~w, ~w, \'~w\', \'~w\', NULL)', [LID, BkID, StudentNo, Borrowed, Due]),
        odbc_query(opac, SQL),
        disconnect_db
    ), Error, (
        format('[DB ERROR] insert loan: ~w~n', [Error]),
        disconnect_db, fail
    )).

sql_return_loan(LoanID, ReturnDate) :-
    catch((
        connect_db,
        format(atom(SQL), 'UPDATE loans SET date_returned=\'~w\' WHERE loan_id=~w', [ReturnDate, LoanID]),
        odbc_query(opac, SQL),
        disconnect_db
    ), Error, (
        format('[DB ERROR] return loan: ~w~n', [Error]),
        disconnect_db, fail
    )).

sql_update_book_copies(BookID, NewCopies) :-
    catch((
        connect_db,
        format(atom(SQL), 'UPDATE books SET copies=~w WHERE book_id=~w', [NewCopies, BookID]),
        odbc_query(opac, SQL),
        disconnect_db
    ), Error, (
        format('[DB ERROR] update copies: ~w~n', [Error]),
        disconnect_db, fail
    )).

sql_insert_borrower(StudentNo, Surname, FirstName, MiddleInitial, Department, Password) :-
    catch((
        connect_db,
        format(atom(SQL), 'INSERT INTO borrowers (student_number, surname, first_name, middle_initial, department, password) VALUES (~w, \'~w\', \'~w\', \'~w\', \'~w\', \'~w\')', [StudentNo, Surname, FirstName, MiddleInitial, Department, Password]),
        odbc_query(opac, SQL),
        disconnect_db
    ), Error, (
        format('[DB ERROR] insert borrower: ~w~n', [Error]),
        disconnect_db, fail
    )).

% =============================================================
% ADD BORROWER
% =============================================================

add_borrower :-
    nl, write('--- Add Borrower ---'), nl,
    read_student_number('Student Number: ', StudentNo),
    ( borrower(StudentNo, _, _, _, _, _) ->
        format('[ERROR] Student Number ~w already exists.~n', [StudentNo])
    ;
        loan_read_capitalized_name('Surname       : ', Surname),
        loan_read_capitalized_name('First Name    : ', FirstName),
        loan_read_middle_initial('Middle Initial: ', MiddleInitial),
        loan_read_department_upper('Department    : ', Department),
        loan_read_password_min8('Password      : ', Password),
        ( sql_insert_borrower(StudentNo, Surname, FirstName, MiddleInitial, Department, Password) ->
            assertz(borrower(StudentNo, Surname, FirstName, MiddleInitial, Department, Password)),
            write('[INFO] Borrower added successfully.'), nl
        ;
            write('[ERROR] Failed to save borrower to database.'), nl
        )
    ).

% =============================================================
% LIST BORROWERS
% =============================================================

list_borrowers :-
    nl,
    write('=============================================='), nl,
        format('~w~t~12| ~w~t~44| ~w~n', ['Student No', 'Name', 'Department']),
    write('=============================================='), nl,
        ( borrower(StudentNo, Surname, FirstName, MiddleInitial, Department, _),
            borrower_full_name(Surname, FirstName, MiddleInitial, FullName),
            format('~w~t~12| ~w~t~44| ~w~n', [StudentNo, FullName, Department]),
      fail ; true ),
    write('=============================================='), nl.

% =============================================================
% BORROW BOOK
% =============================================================

borrow_book :-
    nl, write('--- Borrow Book ---'), nl,
    read_integer('Enter Book ID    : ', BookID),

    ( \+ book(BookID, _, _, _, _, _) ->
        format('[ERROR] Book ID ~w not found.~n', [BookID])
    ;
        ( loan(_, BookID, _, _, _, none) ->
            write('[ERROR] This book already has an active loan.'), nl
        ;
            book(BookID, Title, Author, Year, Copies, Dewey),
            ( Copies =< 0 ->
                write('[ERROR] No available copies.'), nl
            ;
                read_student_number('Enter Student Number: ', StudentNo),
                ( \+ borrower(StudentNo, _, _, _, _, _) ->
                    format('[ERROR] Student Number ~w not found.~n', [StudentNo])
                ;
                    read_date('Borrow Date (YYYY-MM-DD): ', BorrowDate),
                    add_days_to_date(BorrowDate, 7, DueDate),
                    next_loan_id(LoanID),
                    ( sql_insert_loan(LoanID, BookID, StudentNo, BorrowDate, DueDate) ->
                        assertz(loan(LoanID, BookID, StudentNo, BorrowDate, DueDate, none)),
                        retract(book(BookID, Title, Author, Year, Copies, Dewey)),
                        NewCopies is Copies - 1,
                        assertz(book(BookID, Title, Author, Year, NewCopies, Dewey)),
                        sql_update_book_copies(BookID, NewCopies),
                        format('[INFO] Loan #~w created. Due date: ~w~n', [LoanID, DueDate])
                    ;
                        write('[ERROR] Failed to save loan to database.'), nl
                    )
                )
            )
        )
    ).
    
% =============================================================
% RETURN BOOK
% =============================================================

return_book :-
    nl, write('--- Return Book ---'), nl,
    read_integer('Enter Loan ID: ', LoanID),

    ( loan(LoanID, BookID, BorrowerID, BorrowDate, DueDate, none) ->
        read_date('Return Date (YYYY-MM-DD): ', ReturnDate),
        ( sql_return_loan(LoanID, ReturnDate) ->
            retract(loan(LoanID, BookID, BorrowerID, BorrowDate, DueDate, none)),
            assertz(loan(LoanID, BookID, BorrowerID, BorrowDate, DueDate, ReturnDate)),
            book(BookID, Title, Author, Year, Copies, Dewey),
            retract(book(BookID, Title, Author, Year, Copies, Dewey)),
            NewCopies is Copies + 1,
            assertz(book(BookID, Title, Author, Year, NewCopies, Dewey)),
            sql_update_book_copies(BookID, NewCopies),
            compute_fee_for_loan(DueDate, ReturnDate, Fee),
            ( Fee =:= 0 ->
                write('[INFO] Returned on time. No fee.'), nl
            ;
                days_between(DueDate, ReturnDate, DaysLate),
                format('[INFO] Returned ~w day(s) late. Fee: P~2f~n', [DaysLate, Fee])
            )
        ;
            write('[ERROR] Failed to update loan in database.'), nl
        )
    ;
        ( loan(LoanID, _, _, _, _, Returned), Returned \= none ->
            write('[ERROR] This loan has already been returned.'), nl
        ;
            format('[ERROR] Loan ID ~w not found.~n', [LoanID])
        )
    ).

% =============================================================
% COMPUTE OVERDUE FEE
% =============================================================

%% compute_fee_for_loan(+'YYYY-MM-DD' DueDate, +'YYYY-MM-DD' CheckDate, -Fee)
%  Fee = max(0, DaysLate) * 5
compute_fee_for_loan(DueDate, CheckDate, Fee) :-
    days_between(DueDate, CheckDate, Diff),
    ( Diff > 0 ->
        Fee is Diff * 5.0
    ;
        Fee is 0.0
    ).

%% compute_overdue_fee/0 — interactive
compute_overdue_fee :-
    nl, write('--- Compute Overdue Fee ---'), nl,
    read_integer('Enter Loan ID: ', LoanID),

    ( loan(LoanID, BookID, StudentNo, BorrowDate, DueDate, DateReturned) ->
        borrower(StudentNo, Surname, FirstName, MiddleInitial, _, _),
        borrower_full_name(Surname, FirstName, MiddleInitial, FullName),
        book(BookID, Title, _, _, _, _),
        write('Borrower : '), write(FullName), nl,
        write('Book     : '), write(Title), nl,
        write('Borrowed : '), write(BorrowDate), nl,
        write('Due Date : '), write(DueDate), nl,

        ( DateReturned = none ->
            write('Status   : NOT YET RETURNED'), nl,
            get_today(Today),
            compute_fee_for_loan(DueDate, Today, Fee),
            days_between(DueDate, Today, Diff),
            ( Diff > 0 ->
                format('Overdue  : ~w day(s)~n', [Diff]),
                format('Fee      : P~2f~n', [Fee])
            ;
                write('Fee      : No fee yet (not overdue).'), nl
            )
        ;
            write('Returned : '), write(DateReturned), nl,
            compute_fee_for_loan(DueDate, DateReturned, Fee),
            ( Fee =:= 0 ->
                write('Fee      : P0.00 (returned on time)'), nl
            ;
                days_between(DueDate, DateReturned, DaysLate),
                format('Overdue  : ~w day(s)~n', [DaysLate]),
                format('Fee      : P~2f~n', [Fee])
            )
        )
    ;
        format('[ERROR] Loan ID ~w not found.~n', [LoanID])
    ).

borrower_full_name(Surname, FirstName, MiddleInitial, FullName) :-
    format(atom(FullName), '~w, ~w ~w.', [Surname, FirstName, MiddleInitial]).

read_student_number(Prompt, StudentNo) :-
    repeat,
    read_integer(Prompt, Candidate),
    ( Candidate >= 10000000,
      Candidate =< 99999999 ->
        StudentNo = Candidate,
        !
    ;
        write('[ERROR] Student Number must be exactly 8 digits.'), nl,
        fail
    ).

loan_read_capitalized_name(Prompt, Name) :-
    repeat,
    read_text(Prompt, Raw),
    ( Raw = '' ->
        write('[ERROR] This field cannot be blank.'), nl,
        fail
    ;
        loan_to_title_case(Raw, Name),
        !
    ).

loan_read_middle_initial(Prompt, MiddleInitial) :-
    repeat,
    read_text(Prompt, Raw),
    atom_length(Raw, Len),
    ( Len =:= 1 ->
        upcase_atom(Raw, MiddleInitial),
        !
    ;
        write('[ERROR] Middle initial must be exactly one character.'), nl,
        fail
    ).

loan_read_department_upper(Prompt, Department) :-
    repeat,
    read_text(Prompt, Raw),
    ( Raw = '' ->
        write('[ERROR] Department cannot be blank.'), nl,
        fail
    ;
        upcase_atom(Raw, Department),
        !
    ).

loan_read_password_min8(Prompt, Password) :-
    repeat,
    read_text(Prompt, Raw),
    atom_length(Raw, Len),
    ( Len >= 8 ->
        Password = Raw,
        !
    ;
        write('[ERROR] Password must be at least 8 characters.'), nl,
        fail
    ).

loan_to_title_case(InputAtom, OutputAtom) :-
    atom_string(InputAtom, Input),
    split_string(Input, " ", " ", Words0),
    include(loan_non_empty_string, Words0, Words),
    maplist(loan_capitalize_word, Words, CapWords),
    atomics_to_string(CapWords, " ", Output),
    atom_string(OutputAtom, Output).

loan_non_empty_string(S) :-
    S \= "".

loan_capitalize_word(Word, Capitalized) :-
    string_lower(Word, Lower),
    ( Lower = "" ->
        Capitalized = ""
    ;
        sub_string(Lower, 0, 1, _, First),
        sub_string(Lower, 1, _, 0, Rest),
        string_upper(First, UpperFirst),
        string_concat(UpperFirst, Rest, Capitalized)
    ).

% =============================================================
% LIST ALL LOANS
% =============================================================

list_loans :-
    nl,
    write('================================================================================'), nl,
    format('~w~t~8| ~w~t~16| ~w~t~28| ~w~t~40| ~w~t~52| ~w~n',
           ['LoanID', 'BookID', 'StudentNo', 'Borrowed', 'Due', 'Returned']),
    write('================================================================================'), nl,
    ( loan(LID, BkID, BrID, Borrowed, Due, Ret),
      ( Ret = none -> RetDisplay = '(active)' ; RetDisplay = Ret ),
      format('~w~t~8| ~w~t~16| ~w~t~28| ~w~t~40| ~w~t~52| ~w~n',
             [LID, BkID, BrID, Borrowed, Due, RetDisplay]),
      fail ; true ),
    write('================================================================================'), nl.
