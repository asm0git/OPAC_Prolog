:- initialization(start).

% MASTER SCHEMA (Required for SQL integration)
:- dynamic book/6.
:- dynamic borrower/6.
:- dynamic loan/6.
:- dynamic librarian/3.

:- ensure_loaded(storage).
:- ensure_loaded(books).
:- ensure_loaded(loans).
:- use_module(library(readutil)).
:- use_module(library(aggregate)).

start :-
    load_data,
    main_menu.

main_menu :-
    repeat,
    draw_main_header,
    write('1. Login as User'), nl,
    write('2. Login as Librarian'), nl,
    write('3. Exit'), nl,
    read_menu_choice(1, 3, Choice),
    handle_main_choice(Choice, Action),
    ( Action = exit -> ! ; fail ).

handle_main_choice(1, continue) :-
    login('USER'),
    user_menu, !.
handle_main_choice(2, continue) :-
    login('LIBRARIAN'),
    librarian_menu, !.
handle_main_choice(3, exit) :-
    (save_data -> info('Data saved. Goodbye!') ; info('Failed to save data. Goodbye!')).

login('USER') :-
    draw_header('USER'),
    read_student_number('Student Number: ', StudentNo),
    ( borrower(StudentNo, _, _, _, _, StoredPassword) ->
        read_text('Password : ', RawPassword),
        as_string(RawPassword, Password),
        as_string(StoredPassword, StoredPasswordText),
        ( Password == StoredPasswordText ->
            info('Login successful.')
        ;
            info('Incorrect password. Login failed.'),
            fail
        )
    ;
        info('This student number is new.'),
        ask_yes_no('Do you wish to register? (y/n): ', Answer),
        ( Answer = yes ->
            register_new_user(StudentNo)
        ;
            info('Registration cancelled.'),
            fail
        )
    ).

login('LIBRARIAN') :-
    draw_header('LIBRARIAN'),
    read_text('ID Number: ', _),
    read_text('Password : ', _),
    info('Login successful.').

register_new_user(StudentNo) :-
    read_text('Surname       : ', Surname),
    read_text('First Name    : ', FirstName),
    read_text('Middle Initial: ', MiddleInitial),
    read_text('Department    : ', Department),
    read_text('Password      : ', RawPassword),
    as_string(RawPassword, Password),
    ( sql_insert_borrower(StudentNo, Surname, FirstName, MiddleInitial, Department, Password) ->
        assertz(borrower(StudentNo, Surname, FirstName, MiddleInitial, Department, Password)),
        info('Registration successful. Login successful.')
    ;
        info('Failed to register account.'),
        fail
    ).

user_menu :-
    repeat,
    draw_header('USER MENU'),
    write('1. Search Books'), nl,
    write('2. List All Books'), nl,
    write('3. Loans'), nl,
    write('4. Logout'), nl,
    read_menu_choice(1, 4, Choice),
    handle_user_choice(Choice, Action),
    ( Action = back -> ! ; fail ).

handle_user_choice(1, continue) :- search_menu, !.
handle_user_choice(2, continue) :- list_books, pause.
handle_user_choice(3, continue) :- loans_menu.
handle_user_choice(4, back) :- info('Logged out from user account.').

librarian_menu :-
    repeat,
    draw_header('LIBRARIAN MENU'),
    write('1. Add Book'), nl,
    write('2. Edit Book'), nl,
    write('3. Delete Book'), nl,
    write('4. List All Books'), nl,
    write('5. Search Books'), nl,
    write('6. Loans'), nl,
    write('7. Logout'), nl,
    read_menu_choice(1, 7, Choice),
    handle_librarian_choice(Choice, Action),
    ( Action = back -> ! ; fail ).

handle_librarian_choice(1, continue) :- add_book, pause.
handle_librarian_choice(2, continue) :- edit_book, pause.
handle_librarian_choice(3, continue) :- delete_book, pause.
handle_librarian_choice(4, continue) :- list_books, pause.
handle_librarian_choice(5, continue) :- search_menu.
handle_librarian_choice(6, continue) :- loans_menu.
handle_librarian_choice(7, back) :- info('Logged out from librarian account.').

search_menu :-
    repeat,
    draw_header('SEARCH BOOKS'),
    write('1. Search by Exact Title'), nl,
    write('2. Search by Title Keyword'), nl,
    write('3. Search by Dewey Number'), nl,
    write('4. Back'), nl,
    read_menu_choice(1, 4, Choice),
    handle_search_choice(Choice, Action),
    ( Action = back -> ! ; fail ).

handle_search_choice(1, continue) :- search_book_by_title, pause.
handle_search_choice(2, continue) :- search_title_keyword, pause.
handle_search_choice(3, continue) :- search_book_by_dewey, pause.
handle_search_choice(4, back).

loans_menu :-
    repeat,
    draw_header('LOANS MENU'),
    write('1. Borrow Book'), nl,
    write('2. Return Book'), nl,
    write('3. List All Loans'), nl,
    write('4. Compute Overdue Fee'), nl,
    write('5. Back'), nl,
    read_menu_choice(1, 5, Choice),
    handle_loans_choice(Choice, Action),
    ( Action = back -> ! ; fail ).

handle_loans_choice(1, continue) :- borrow_book, pause.
handle_loans_choice(2, continue) :- return_book, pause.
handle_loans_choice(3, continue) :- list_loans, pause.
handle_loans_choice(4, continue) :- compute_overdue_fee, pause.
handle_loans_choice(5, back).

read_menu_choice(Min, Max, Choice) :-
    repeat,
    format('Choose [~w-~w]: ', [Min, Max]),
    read_line_to_string(user_input, Input),
    normalize_space(string(Clean), Input),
    ( Clean = "" ->
        info('Please enter a number.'),
        fail
    ; catch(number_string(N, Clean), _, fail),
      integer(N),
      N >= Min,
      N =< Max ->
        Choice = N,
        !
    ;
        info('Invalid choice. Please try again.'),
        fail
    ).

read_text(Prompt, Text) :-
    write(Prompt),
    read_line_to_string(user_input, Raw),
    normalize_space(string(Text), Raw).

read_student_number(Prompt, StudentNo) :-
    repeat,
    read_integer(Prompt, Candidate),
    ( Candidate >= 10000000,
      Candidate =< 99999999 ->
        StudentNo = Candidate,
        !
    ;
        info('Student number must be exactly 8 digits.'),
        fail
    ).

ask_yes_no(Prompt, Answer) :-
    repeat,
    write(Prompt),
    read_line_to_string(user_input, Raw),
    normalize_space(string(Clean), Raw),
    string_lower(Clean, Lower),
    ( member(Lower, ["y", "yes"]) ->
        Answer = yes,
        !
    ; member(Lower, ["n", "no"]) ->
        Answer = no,
        !
    ;
        info('Please answer y or n.'),
        fail
    ).

as_string(Value, Text) :-
    ( string(Value) ->
        Text = Value
    ; atom(Value) ->
        atom_string(Value, Text)
    ; number(Value) ->
        number_string(Value, Text)
    ; format(string(Text), '~w', [Value])
    ).

draw_header(Title) :-
    nl,
    write('==============================================='), nl,
    write(Title), nl,
    write('==============================================='), nl.

draw_main_header :-
    draw_header('OPAC - MAIN MENU'),
    runtime_stats(Books, ActiveLoans, Mode),
    format('Books: ~w | Active Loans: ~w | Mode: ~w~n', [Books, ActiveLoans, Mode]),
    write('-----------------------------------------------'), nl.

runtime_stats(Books, ActiveLoans, parallel) :-
    supports_parallel,
    !,
    parallel_runtime_stats(Books, ActiveLoans).
runtime_stats(Books, ActiveLoans, sequential) :-
    sequential_runtime_stats(Books, ActiveLoans).

supports_parallel :-
    current_predicate(thread_create/3),
    current_predicate(thread_join/2),
    current_predicate(message_queue_create/1),
    current_prolog_flag(threads, true).

parallel_runtime_stats(Books, ActiveLoans) :-
    message_queue_create(Q),
    thread_create(send_book_count(Q), TB, []),
    thread_create(send_active_loan_count(Q), TL, []),
    collect_stats(2, Q, 0, 0, Books, ActiveLoans),
    thread_join(TB, _),
    thread_join(TL, _),
    message_queue_destroy(Q).

collect_stats(0, _, Books, Loans, Books, Loans) :- !.
collect_stats(N, Q, AccBooks, AccLoans, Books, Loans) :-
    thread_get_message(Q, metric(Type, Value)),
    ( Type = books ->
        NextBooks = Value,
        NextLoans = AccLoans
    ; Type = active_loans ->
        NextBooks = AccBooks,
        NextLoans = Value
    ;
        NextBooks = AccBooks,
        NextLoans = AccLoans
    ),
    N1 is N - 1,
    collect_stats(N1, Q, NextBooks, NextLoans, Books, Loans).

send_book_count(Q) :-
    aggregate_all(count, book(_, _, _, _, _, _), Count),
    thread_send_message(Q, metric(books, Count)).

send_active_loan_count(Q) :-
    aggregate_all(count, loan(_, _, _, _, _, none), Count),
    thread_send_message(Q, metric(active_loans, Count)).

sequential_runtime_stats(Books, ActiveLoans) :-
    aggregate_all(count, book(_, _, _, _, _, _), Books),
    aggregate_all(count, loan(_, _, _, _, _, none), ActiveLoans).

info(Message) :-
    format('~n[INFO] ~w~n', [Message]).

pause :-
    nl,
    write('Press Enter to continue...'),
    read_line_to_string(user_input, _).