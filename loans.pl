
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

sql_insert_loan(LID, BkID, BrID, Borrowed, Due) :-
    catch((
        connect_db,
        atom_string(BorrowedStr, Borrowed),
        atom_string(DueStr, Due),
        odbc_query(opac,
            'INSERT INTO loans (loan_id, book_id, borrower_id, date_borrowed, due_date, date_returned) VALUES (?,?,?,?,?,NULL)',
            [LID, BkID, BrID, BorrowedStr, DueStr]),
        disconnect_db
    ), Error, (
        format('[DB ERROR] insert loan: ~w~n', [Error]),
        disconnect_db, fail
    )).

sql_return_loan(LoanID, ReturnDate) :-
    catch((
        connect_db,
        atom_string(RetStr, ReturnDate),
        odbc_query(opac,
            'UPDATE loans SET date_returned=? WHERE loan_id=?',
            [RetStr, LoanID]),
        disconnect_db
    ), Error, (
        format('[DB ERROR] return loan: ~w~n', [Error]),
        disconnect_db, fail
    )).

sql_update_book_copies(BookID, NewCopies) :-
    catch((
        connect_db,
        odbc_query(opac,
            'UPDATE books SET copies=? WHERE book_id=?',
            [NewCopies, BookID]),
        disconnect_db
    ), Error, (
        format('[DB ERROR] update copies: ~w~n', [Error]),
        disconnect_db, fail
    )).

sql_insert_borrower(BID, Name, Course) :-
    catch((
        connect_db,
        odbc_query(opac,
            'INSERT INTO borrowers (borrower_id, name, course) VALUES (?,?,?)',
            [BID, Name, Course]),
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
    read_integer('Borrower ID  : ', BID),
    ( borrower(BID, _, _) ->
        format('[ERROR] Borrower ID ~w already exists.~n', [BID])
    ;
        read_text('Name         : ', Name),
        ( Name = '' ->
            write('[ERROR] Name cannot be blank.'), nl
        ;
            read_text('Course       : ', Course),
            ( sql_insert_borrower(BID, Name, Course) ->
                assertz(borrower(BID, Name, Course)),
                write('[INFO] Borrower added successfully.'), nl
            ;
                write('[ERROR] Failed to save borrower to database.'), nl
            )
        )
    ).

% =============================================================
% LIST BORROWERS
% =============================================================

list_borrowers :-
    nl,
    write('=============================================='), nl,
    format('~w~t~8| ~w~t~38| ~w~n', ['ID', 'Name', 'Course']),
    write('=============================================='), nl,
    ( borrower(BID, Name, Course),
      format('~w~t~8| ~w~t~38| ~w~n', [BID, Name, Course]),
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
                read_integer('Enter Borrower ID: ', BorrowerID),
                ( \+ borrower(BorrowerID, _, _) ->
                    format('[ERROR] Borrower ID ~w not found.~n', [BorrowerID])
                ;
                    read_date('Borrow Date (YYYY-MM-DD): ', BorrowDate),
                    add_days_to_date(BorrowDate, 7, DueDate),
                    next_loan_id(LoanID),
                    ( sql_insert_loan(LoanID, BookID, BorrowerID, BorrowDate, DueDate) ->
                        assertz(loan(LoanID, BookID, BorrowerID, BorrowDate, DueDate, none)),
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
    write('--- Return Book ---'), nl,
    write('Enter Loan ID: '), read(LoanID),

    ( loan(LoanID, BookID, BorrowerID, BorrowDate, DueDate, none) ->
        write('Return Date (YYYY-MM-DD): '), read(ReturnDate),

        retract(loan(LoanID, BookID, BorrowerID, BorrowDate, DueDate, none)),
        assertz(loan(LoanID, BookID, BorrowerID, BorrowDate, DueDate, ReturnDate)),

        % Restore copy count
        book(BookID, Title, Author, Year, Copies, Dewey),
        retract(book(BookID, Title, Author, Year, Copies, Dewey)),
        NewCopies is Copies + 1,
        assertz(book(BookID, Title, Author, Year, NewCopies, Dewey)),

        compute_fee_for_loan(DueDate, ReturnDate, Fee),
        ( Fee =:= 0 ->
            write('Returned on time. No fee.'), nl
        ;
            days_between(DueDate, ReturnDate, DaysLate),
            format('Returned ~w day(s) late. Fee: P~2f~n', [DaysLate, Fee])
        )
    ;
        ( loan(LoanID, _, _, _, _, Returned), Returned \= none ->
            write('This loan has already been returned.'), nl
        ;
            write('Loan ID not found.'), nl
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
    write('--- Compute Overdue Fee ---'), nl,
    write('Enter Loan ID: '), read(LoanID),

    ( loan(LoanID, BookID, BorrowerID, BorrowDate, DueDate, DateReturned) ->
        borrower(BorrowerID, Name, _),
        book(BookID, Title, _, _, _, _),
        write('Borrower : '), write(Name), nl,
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
        write('Loan ID not found.'), nl
    ).

% =============================================================
% LIST ALL LOANS
% =============================================================

list_loans :-
    write('----------------------------------------------------------------'), nl,
    write('LoanID | BookID | BorrowerID | Borrowed   | Due        | Returned'), nl,
    write('----------------------------------------------------------------'), nl,
    ( loan(LID, BkID, BrID, Borrowed, Due, Ret),
      format('~w      | ~w      | ~w          | ~w | ~w | ', [LID, BkID, BrID, Borrowed, Due]),
      ( Ret = none -> write('(active)') ; write(Ret) ),
      nl, fail ; true ),
    write('----------------------------------------------------------------'), nl.
