:- initialization(start).

start :-
    main_menu.

% ===== MAIN MENU =====
main_menu :-
    nl,
    write('RBAC'), nl,
    write('1. Login as User'), nl,
    write('2. Login as Librarian'), nl,
    write('Choice: '),
    read(Choice),
    handle_main_choice(Choice).

handle_main_choice(1) :-
    nl,
    write('Student Number: '), read(_),
    write('Password: '), read(_),
    user_menu.

handle_main_choice(2) :-
    nl,
    write('Staff Number: '), read(_),
    write('Password: '), read(_),
    librarian_menu.

handle_main_choice(_) :-
    write('Invalid choice.'), nl,
    main_menu.

% ===== USER MENU =====
user_menu :-
    nl,
    write('---- MENU -----'), nl,
    write('1. Search Book'), nl,
    write('2. List all Books'), nl,
    write('3. Loan Book'), nl,
    write('4. Logout'), nl,
    write('Choice: '),
    read(Choice),
    handle_user_choice(Choice).

handle_user_choice(1) :-
    search_menu,
    user_menu.

handle_user_choice(2) :-
    write('Listing all books...'), nl,
    user_menu.

handle_user_choice(3) :-
    write('Loaning book...'), nl,
    user_menu.

handle_user_choice(4) :-
    main_menu.

handle_user_choice(_) :-
    write('Invalid choice.'), nl,
    user_menu.

% ===== LIBRARIAN MENU =====
librarian_menu :-
    nl,
    write('---- MENU -----'), nl,
    write('1. Add Book'), nl,
    write('2. Edit Book'), nl,
    write('3. Delete Book'), nl,
    write('4. List all Books'), nl,
    write('5. Search Book'), nl,
    write('6. Logout'), nl,
    write('Choice: '),
    read(Choice),
    handle_librarian_choice(Choice).

handle_librarian_choice(1) :-
    write('Adding book...'), nl,
    librarian_menu.

handle_librarian_choice(2) :-
    write('Editing book...'), nl,
    librarian_menu.

handle_librarian_choice(3) :-
    write('Deleting book...'), nl,
    librarian_menu.

handle_librarian_choice(4) :-
    write('Listing all books...'), nl,
    librarian_menu.

handle_librarian_choice(5) :-
    search_menu,
    librarian_menu.

handle_librarian_choice(6) :-
    main_menu.

handle_librarian_choice(_) :-
    write('Invalid choice.'), nl,
    librarian_menu.

% ===== SEARCH MENU =====
search_menu :-
    nl,
    write('---- SEARCH MENU -----'), nl,
    write('1. Search by Exact Title'), nl,
    write('2. Search by Title Keyword'), nl,
    write('3. Search by Dewey Number'), nl,
    write('4. Back to Main Menu'), nl,
    write('Choice: '),
    read(Choice),
    handle_search_choice(Choice).

handle_search_choice(1) :-
    write('Searching by exact title...'), nl.

handle_search_choice(2) :-
    write('Searching by keyword...'), nl.

handle_search_choice(3) :-
    write('Searching by Dewey number...'), nl.

handle_search_choice(4).

handle_search_choice(_) :-
    write('Invalid choice.'), nl,
    search_menu.