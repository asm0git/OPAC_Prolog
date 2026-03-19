% -------------------------------------------------
% OPAC MAIN MENU INTERFACE (RBAC)
% -------------------------------------------------
% Role-based access:
%   - User (Borrower): Search/List/Loan
%   - Librarian: Add/Edit/Delete/List/Search
% Note: Credentials are not validated yet; input is accepted as-is.
% -------------------------------------------------

:- ensure_loaded(storage).
:- ensure_loaded(books).
:- ensure_loaded(loans).

% Entry point
start :-
    load_data,
    rbac_menu.

% -------------------------------------------------
% RBAC LOGIN MENU
% -------------------------------------------------

rbac_menu :-
    nl,
    write('RBAC'), nl,
    write('1. Login as User'), nl,
    write('2. Login as Librarian'), nl,
    nl,
    write('Choice: '),
    read(Choice),
    ( Choice =:= 1 ->
        user_login
    ; Choice =:= 2 ->
        librarian_login
    ;
        write('Invalid choice. Try again.'), nl,
        rbac_menu
    ).

user_login :-
    nl,
    write('Student Number: '), read(_StudentNo),
    write('Password: '), read(_Password),
    user_main_menu.

librarian_login :-
    nl,
    write('Staff Number: '), read(_StaffNo),
    write('Password: '), read(_Password),
    librarian_main_menu.

% -------------------------------------------------
% USER MENU
% -------------------------------------------------

user_main_menu :-
    nl,
    write('---- MENU -----'), nl,
    write('1. Search Book'), nl,
    write('2. List all Books'), nl,
    write('3. Loan Book'), nl,
    write('4. Logout'), nl,
    nl,
    write('Choice: '),
    read(Choice),
    ( Choice =:= 1 ->
        search_book_menu(user)
    ; Choice =:= 2 ->
        list_books,
        user_main_menu
    ; Choice =:= 3 ->
        borrow_book,
        user_main_menu
    ; Choice =:= 4 ->
        rbac_menu
    ;
        write('Invalid choice. Try again.'), nl,
        user_main_menu
    ).

% -------------------------------------------------
% LIBRARIAN MENU
% -------------------------------------------------

librarian_main_menu :-
    nl,
    write('----MENU----'), nl,
    write('1. Add Book'), nl,
    write('2. Edit Book'), nl,
    write('3. Delete Book'), nl,
    write('4. List all Books'), nl,
    write('5. Search Book'), nl,
    write('6. Logout'), nl,
    nl,
    write('Choice: '),
    read(Choice),
    ( Choice =:= 1 ->
        add_book,
        librarian_main_menu
    ; Choice =:= 2 ->
        edit_book,
        librarian_main_menu
    ; Choice =:= 3 ->
        delete_book,
        librarian_main_menu
    ; Choice =:= 4 ->
        list_books,
        librarian_main_menu
    ; Choice =:= 5 ->
        search_book_menu(librarian)
    ; Choice =:= 6 ->
        rbac_menu
    ;
        write('Invalid choice. Try again.'), nl,
        librarian_main_menu
    ).

% -------------------------------------------------
% SEARCH BOOK SUBMENU
% -------------------------------------------------

% search_book_menu(+Role)
% Role is either user or librarian, used only to return to the right main menu.
search_book_menu(Role) :-
    nl,
    write('1. Search by Exact Title'), nl,
    write('2. Search by Title Keyword'), nl,
    write('3. Search by Dewey Number'), nl,
    write('4. Back to Main Menu'), nl,
    nl,
    write('Choice: '),
    read(Choice),
    ( Choice =:= 1 ->
        ( search_book_by_title -> true ; write('No match found.'), nl ),
        search_book_menu(Role)
    ; Choice =:= 2 ->
        search_title_keyword,
        search_book_menu(Role)
    ; Choice =:= 3 ->
        ( search_book_by_dewey -> true ; write('No match found.'), nl ),
        search_book_menu(Role)
    ; Choice =:= 4 ->
        back_to_main(Role)
    ;
        write('Invalid choice. Try again.'), nl,
        search_book_menu(Role)
    ).

back_to_main(user) :- user_main_menu.
back_to_main(librarian) :- librarian_main_menu.

% Convenience runner (SWI-Prolog)
run :- start.