% -------------------------------------------------
% BOOKS.PL
% Catalog management and search features.
%
% This file handles:
% 1) Book CRUD operations (add/edit/delete)
% 2) Input validation for book fields
% 3) Title and Dewey-based search flows
% 4) SQL persistence for book records
% -------------------------------------------------

% -------------------------------------------------
% BOOK STATUS
% -------------------------------------------------

%% book_status(+BookID, +Copies, -Status)
book_status(_, Copies, 'Unavailable') :-
    Copies =:= 0, !.
book_status(BookID, _, 'Borrowed') :-
    loan(_, BookID, _, _, _, _, 0), !.
book_status(_, _, 'Available').

% -------------------------------------------------
% NEXT BOOK ID (AUTO-INCREMENT)
% -------------------------------------------------

%% next_book_id(-ID)
next_book_id(ID) :-
    findall(N, book(N, _, _, _, _, _, _), IDs),
    ( IDs = [] -> ID = 1 ; max_list(IDs, Max), ID is Max + 1 ).

% -------------------------------------------------
% BOOK INPUT VALIDATION
% -------------------------------------------------

%% read_valid_author(+Prompt, -Author)
read_valid_author(Prompt, Author) :-
    repeat,
    read_text(Prompt, Raw),
    ( Raw = '' ->
        write('[ERROR] Author cannot be blank.'), nl,
        fail
    ;
        Author = Raw, !
    ).

%% read_valid_year(+Prompt, -Year)
read_valid_year(Prompt, Year) :-
    repeat,
    read_integer(Prompt, Candidate),
    ( Candidate < 1450 ; Candidate > 2100 ->
        write('[ERROR] Year must be between 1450 and 2100.'), nl,
        fail
    ;
        Year = Candidate, !
    ).

%% read_valid_copies(+Prompt, -Copies)
read_valid_copies(Prompt, Copies) :-
    repeat,
    read_integer(Prompt, Candidate),
    ( Candidate < 1 ->
        write('[ERROR] Copies must be at least 1.'), nl,
        fail
    ;
        Copies = Candidate, !
    ).

%% read_valid_dewey(+Prompt, -Dewey)
read_valid_dewey(Prompt, Dewey) :-
    repeat,
    read_number(Prompt, Candidate),
    ( Candidate < 0 ; Candidate > 999.99 ->
        write('[ERROR] Dewey Decimal must be between 0.00 and 999.99.'), nl,
        fail
    ;
        Dewey = Candidate, !
    ).

% -------------------------------------------------
% ADD BOOK
% -------------------------------------------------

add_book :-
    nl, write('--- Add New Book ---'), nl,
    ( current_librarian_staff_number(StaffNumber) ->
        true
    ;
        write('[ERROR] Only logged-in librarians can add books.'), nl,
        fail
    ),
    read_text('Title        : ', Title),
    ( Title = '' ->
        write('[ERROR] Title cannot be blank.'), nl
    ;
        read_valid_author('Author       : ', Author),
        read_valid_year('Year         : ', Year),
        read_valid_copies('Copies       : ', Copies),
        read_valid_dewey('Dewey Number : ', Dewey),
        next_book_id(ID),
        ( sql_insert_book(ID, Title, Author, Year, Copies, Dewey, StaffNumber) ->
            assertz(book(ID, Title, Author, Year, Copies, Dewey, StaffNumber)),
            format('[INFO] Book added successfully. Book ID: ~w~n', [ID])
        ;
            write('[ERROR] Failed to save book to database.'), nl
        )
    ).

sql_insert_book(ID, Title, Author, Year, Copies, Dewey, StaffNumber) :-
    % Persist new book row first; memory fact is asserted by caller on success.
    catch((
        connect_db,
        format(atom(SQL), 'INSERT INTO books (book_id, title, author, year_published, copies, dewey_decimal, added_by_staff_number) VALUES (~w, ~q, ~q, ~w, ~w, ~w, ~q)', [ID, Title, Author, Year, Copies, Dewey, StaffNumber]),
        odbc_query(opac, SQL)
    ), Error, (
        format('[DB ERROR] add book: ~w~n', [Error]),
        disconnect_db, fail
    )),
    % Disconnect only after successful insert (not in critical path of catch).
    catch(disconnect_db, _, true).

% -------------------------------------------------
% EDIT BOOK
% -------------------------------------------------

%% read_num_or_keep(+Prompt, +Old, -New)  —  '-' keeps current value, empty input requires re-entry
read_num_or_keep(Prompt, Old, New) :-
    repeat,
    write(Prompt),
    read_line_to_string(user_input, Raw),
    normalize_space(string(Clean), Raw),
    ( Clean = "-" -> 
        New = Old, !
    ; Clean = "" ->
        write('[ERROR] Please enter a value or "-" to keep current.'), nl,
        fail
    ; catch(number_string(N, Clean), _, fail) ->
        New = N, !
    ;
        write('[ERROR] Invalid number. Please try again.'), nl,
        fail
    ).

edit_book :-
    nl, write('--- Edit Book ---'), nl,
    read_integer('Enter Book ID: ', ID),
    ( book(ID, OldTitle, OldAuthor, OldYear, OldCopies, OldDewey, AddedByStaffNo) ->
        format('Current: ~w | ~w | ~w | copies: ~w | dewey: ~w~n',
               [OldTitle, OldAuthor, OldYear, OldCopies, OldDewey]),
        nl, write('(Enter "-" to keep current value)'), nl,
        read_text_or_keep('New Title        : ', OldTitle,   NewTitle),
        read_text_or_keep('New Author       : ', OldAuthor,  NewAuthor),
        read_int_or_keep('New Year         : ', OldYear,    NewYear),
        read_int_or_keep('New Copies       : ', OldCopies,  NewCopies),
        read_num_or_keep('New Dewey Number : ', OldDewey,   NewDewey),
        % Keep in-memory and SQL data synchronized after successful update.
        ( sql_update_book(ID, NewTitle, NewAuthor, NewYear, NewCopies, NewDewey) ->
            retract(book(ID, OldTitle, OldAuthor, OldYear, OldCopies, OldDewey, AddedByStaffNo)),
            assertz(book(ID, NewTitle, NewAuthor, NewYear, NewCopies, NewDewey, AddedByStaffNo)),
            write('[INFO] Book updated successfully.'), nl
        ;
            write('[ERROR] Failed to update book in database.'), nl
        )
    ;
        format('[ERROR] Book ID ~w not found.~n', [ID])
    ).

sql_update_book(ID, Title, Author, Year, Copies, Dewey) :-
    catch((
        connect_db,
        format(atom(SQL), 'UPDATE books SET title=~q, author=~q, year_published=~w, copies=~w, dewey_decimal=~w WHERE book_id=~w', [Title, Author, Year, Copies, Dewey, ID]),
        odbc_query(opac, SQL)
    ), Error, (
        format('[DB ERROR] edit book: ~w~n', [Error]),
        disconnect_db, fail
    )),
    % Disconnect only after successful update (not in critical path of catch).
    catch(disconnect_db, _, true).

% -------------------------------------------------
% DELETE BOOK  (safe — blocked if active loan exists)
% -------------------------------------------------

delete_book :-
    nl, write('--- Delete Book ---'), nl,
    read_integer('Enter Book ID: ', ID),
    ( \+ book(ID, _, _, _, _, _, _) ->
        format('[ERROR] Book ID ~w not found.~n', [ID])
    ; loan(_, ID, _, _, _, _, 0) ->
        write('[ERROR] Cannot delete: this book has an active loan.'), nl
    ;
        book(ID, Title, _, _, _, _, _),
        format('Confirm delete "~w"? (yes/no): ', [Title]),
        read_line_to_string(user_input, Ans),
        normalize_space(string(AnsClean), Ans),
        ( AnsClean = "yes" ->
            ( sql_delete_book(ID) ->
                % Remove fact only after SQL delete succeeds.
                retract(book(ID, _, _, _, _, _, _)),
                write('[INFO] Book deleted successfully.'), nl
            ;
                write('[ERROR] Failed to delete book from database.'), nl
            )
        ;
            write('[INFO] Delete cancelled.'), nl
        )
    ).

sql_delete_book(ID) :-
    catch((
        connect_db,
        format(atom(SQL), 'DELETE FROM books WHERE book_id=~w', [ID]),
        odbc_query(opac, SQL)
    ), Error, (
        format('[DB ERROR] delete book: ~w~n', [Error]),
        disconnect_db, fail
    )),
    % Disconnect only after successful delete (not in critical path of catch).
    catch(disconnect_db, _, true).

% -------------------------------------------------
% LIST ALL BOOKS
% -------------------------------------------------

list_books :-
    nl,
    % Reuse shared table printer for consistent catalog formatting.
    print_book_table('(No books on record.)',
        forall(
            book(ID, Title, Author, Year, Copies, Dewey, _),
            print_book_row(ID, Title, Author, Year, Copies, Dewey)
        )).

list_books_librarian :-
    nl,
    librarian_book_sep,
    format('~w~t~8| ~w~t~46| ~w~t~68| ~w~t~74| ~w~t~82| ~w~t~90| ~w~t~108| ~w~t~138| ~w~n',
           ['ID', 'Title', 'Author', 'Year', 'Copies', 'Dewey', 'Status', 'Added By', 'Added By ID']),
    librarian_book_sep,
    ( book(_, _, _, _, _, _, _) ->
        forall(
            book(ID, Title, Author, Year, Copies, Dewey, AddedByStaffNo),
            print_librarian_book_row(ID, Title, Author, Year, Copies, Dewey, AddedByStaffNo)
        )
    ;
        write('(No books on record.)'), nl
    ),
    librarian_book_sep.

% -------------------------------------------------
% SEARCH: EXACT TITLE
% -------------------------------------------------

search_book_by_title :-
    nl,
    read_text('Enter exact title: ', QueryTitle),
    title_key(QueryTitle, QueryKey),
    findall(row(ID, Title, Author, Year, Copies, Dewey),
            ( book(ID, Title, Author, Year, Copies, Dewey, _),
                            % Compare normalized keys so case/spacing variations still match.
              title_key(Title, BookKey),
              QueryKey == BookKey ),
            Rows),
    ( Rows = [] ->
        write('[INFO] No book found.'), nl
    ;
        print_full_details_rows(Rows)
    ).

% -------------------------------------------------
% SEARCH: TITLE KEYWORD (partial, case-insensitive)
% -------------------------------------------------

search_title_keyword :-
    nl,
    read_text('Enter keyword: ', Keyword),
    downcase_atom(Keyword, KeywordLower),
    findall(row(ID, Title, Author, Year, Copies, Dewey),
            ( book(ID, Title, Author, Year, Copies, Dewey, _),
              downcase_atom(Title, TitleLower),
              sub_atom(TitleLower, _, _, _, KeywordLower) ),
            Rows),
    ( Rows = [] ->
        write('[INFO] No book found.'), nl
    ;
        print_full_details_rows(Rows)
    ).

% -------------------------------------------------
% SEARCH: BY DEWEY NUMBER
% -------------------------------------------------

search_book_by_dewey :-
    nl,
    show_dewey_reference,
    dewey_search_loop.

dewey_search_loop :-
    read_number('Enter Dewey number, or -1 to return to Search Menu: ', DeweyInput),
        ( DeweyInput =:= -1 ->
                true
        ; query_books_by_exact_dewey(DeweyInput, ExactRows),
      ExactRows \= [] ->
                % Exact matches are shown immediately; prefix lookup is used only as fallback.
        write('[INFO] Exact Dewey match found:'), nl,
                print_compact_details_rows(ExactRows),
                dewey_search_loop
    ;
      query_books_by_dewey_prefix(DeweyInput, PrefixRows),
      ( PrefixRows \= [] ->
            write('[INFO] Matching books (Dewey starts with input):'), nl,
            print_dewey_shortlist(PrefixRows),
            handle_shortlist_selection(PrefixRows)
      ;
            write('[INFO] No book was found under that Dewey number.'), nl,
                        dewey_search_loop
      )
    ).

query_books_by_exact_dewey(DeweyInput, Rows) :-
    catch((
        connect_db,
        format(atom(SQL),
               'SELECT book_id, title, author, year_published, copies, dewey_decimal FROM books WHERE dewey_decimal = ~w ORDER BY book_id',
               [DeweyInput]),
        findall(row(ID, T, A, Y, C, D), odbc_query(opac, SQL, row(ID, T, A, Y, C, D)), Rows),
        disconnect_db
    ), _, (
        disconnect_db,
        Rows = []
    )).

query_books_by_dewey_prefix(DeweyInput, Rows) :-
    number_string(DeweyInput, DeweyText0),
    normalize_space(string(DeweyText), DeweyText0),
    % Accept both whole-class input (e.g., 5) and decimal-prefix input (e.g., 5.2).
    ( sub_string(DeweyText, _, _, _, '.') ->
        format(atom(PrefixLike), '~w%', [DeweyText])
    ;
        format(atom(PrefixLike), '~w.%', [DeweyText])
    ),
    catch((
        connect_db,
        format(atom(SQL),
               'SELECT book_id, title, author, year_published, copies, dewey_decimal FROM books WHERE CAST(dewey_decimal AS CHAR) LIKE \'~w\' ORDER BY dewey_decimal, book_id',
               [PrefixLike]),
        findall(row(ID, T, A, Y, C, D), odbc_query(opac, SQL, row(ID, T, A, Y, C, D)), Rows),
        disconnect_db
    ), _, (
        disconnect_db,
        Rows = []
    )).

print_dewey_shortlist(Rows) :-
    write('=============================================================='), nl,
    format('~w~t~8| ~w~t~42| ~w~t~62| ~w~n', ['ID', 'Title', 'Author', 'Dewey']), nl,
    write('=============================================================='), nl,
    forall(member(row(ID, T, A, _, _, D), Rows),
           format('~w~t~8| ~w~t~42| ~w~t~62| ~w~n', [ID, T, A, D])),
    write('=============================================================='), nl.

handle_shortlist_selection(Rows) :-
    nl,
    write('Enter Book ID to view details, or -1 to return to Search Menu: '),
    read_line_to_string(user_input, Raw),
    normalize_space(string(Clean), Raw),
    ( catch(number_string(Choice, Clean), _, fail), integer(Choice) ->
        ( Choice =:= -1 ->
            true
        ; member(row(Choice, _, _, _, _, _), Rows) ->
            show_full_details_by_id(Choice),
            dewey_search_loop
        ;
            write('[INFO] Book ID not in the list. Try again.'), nl,
            handle_shortlist_selection(Rows)
        )
    ;
        write('[INFO] Please enter a valid number.'), nl,
        handle_shortlist_selection(Rows)
    ).

show_full_details_by_id(BookID) :-
    catch((
        connect_db,
        format(atom(SQL),
               'SELECT book_id, title, author, year_published, copies, dewey_decimal FROM books WHERE book_id = ~w',
               [BookID]),
        ( odbc_query(opac, SQL, row(ID, T, A, Y, C, D)) ->
            print_compact_details_rows([row(ID, T, A, Y, C, D)])
        ;
            write('[INFO] Book not found.'), nl
        ),
        disconnect_db
    ), _, (
        disconnect_db,
        write('[INFO] Failed to load full details.'), nl
    )).

print_full_details_rows(Rows) :-
    print_book_table('(No matching book found.)',
        forall(
            member(row(ID, T, A, Y, C, D), Rows),
            ( to_number_or_self(D, DeweyNum),
              print_book_row(ID, T, A, Y, C, DeweyNum) )
        )).

        print_compact_details_rows(Rows) :-
            write('================================================================================'), nl,
            format('~w~t~8| ~w~t~42| ~w~t~62| ~w~t~70| ~w~t~78| ~w~n',
                ['ID', 'Title', 'Author', 'Year', 'Copies', 'Dewey']), nl,
            write('================================================================================'), nl,
            forall(
             member(row(ID, T, A, Y, C, D), Rows),
             ( to_number_or_self(D, DeweyNum),
               format('~w~t~8| ~w~t~42| ~w~t~62| ~w~t~70| ~w~t~78| ~w~n',
                   [ID, T, A, Y, C, DeweyNum]) )
            ),
            write('================================================================================'), nl.

to_number_or_self(Value, Number) :-
    ( number(Value) ->
        Number = Value
    ; atom(Value), catch(atom_number(Value, N), _, fail) ->
        Number = N
    ; string(Value), catch(number_string(N, Value), _, fail) ->
        Number = N
    ;
        Number = Value
    ).

show_dewey_reference :-
    write('Dewey Categories Reference:'), nl,
    write('  000-099  Computer Science'), nl,
    write('  100-199  Philosophy'), nl,
    write('  200-299  Religion'), nl,
    write('  300-399  Social Sciences'), nl,
    write('  400-499  Language'), nl,
    write('  500-599  Science'), nl,
    write('  600-699  Technology'), nl,
    write('  700-799  Arts'), nl,
    write('  800-899  Literature'), nl,
    write('  900-999  History'), nl,
    nl.

% -------------------------------------------------
% SEARCH: BY DEWEY CATEGORY RANGE
% -------------------------------------------------

list_books_by_category :-
    nl,
    read_number('Enter Dewey category base (e.g. 500): ', Base),
    CategoryEnd is Base + 100,
    format('Books in category ~w-~w:~n', [Base, CategoryEnd]),
    print_book_table('(No books in that category range.)',
        forall(
                        ( book(ID, Title, Author, Year, Copies, Dewey, _),
              Dewey >= Base, Dewey < CategoryEnd ),
            print_book_row(ID, Title, Author, Year, Copies, Dewey)
        )).

% -------------------------------------------------
% DEWEY DECIMAL CATEGORY MAPPING
% -------------------------------------------------
dewey_category(D, 'Computer Science') :- D >= 0,   D < 100.
dewey_category(D, 'Philosophy')       :- D >= 100, D < 200.
dewey_category(D, 'Religion')         :- D >= 200, D < 300.
dewey_category(D, 'Social Sciences')  :- D >= 300, D < 400.
dewey_category(D, 'Language')         :- D >= 400, D < 500.
dewey_category(D, 'Science')          :- D >= 500, D < 600.
dewey_category(D, 'Technology')       :- D >= 600, D < 700.
dewey_category(D, 'Arts')             :- D >= 700, D < 800.
dewey_category(D, 'Literature')       :- D >= 800, D < 900.
dewey_category(D, 'History')          :- D >= 900, D < 1000.
dewey_category(_, 'Uncategorised').

% -------------------------------------------------
% INPUT HELPERS
% -------------------------------------------------

%% read_text(+Prompt, -Atom)
read_text(Prompt, Atom) :-
    write(Prompt),
    read_line_to_string(user_input, Raw),
    normalize_space(string(Trimmed), Raw),
    atom_string(Atom, Trimmed).

%% read_integer(+Prompt, -N)  —  loops until valid whole number
read_integer(Prompt, N) :-
    repeat,
    write(Prompt),
    read_line_to_string(user_input, Raw),
    normalize_space(string(Clean), Raw),
    ( catch(number_string(N0, Clean), _, fail), integer(N0) ->
        N = N0, !
    ;
        write('[ERROR] Please enter a whole number.'), nl,
        fail
    ).

%% read_number(+Prompt, -N)  —  loops until valid number (int or float)
read_number(Prompt, N) :-
    repeat,
    write(Prompt),
    read_line_to_string(user_input, Raw),
    normalize_space(string(Clean), Raw),
    ( catch(number_string(N0, Clean), _, fail) ->
        N = N0, !
    ;
        write('[ERROR] Please enter a valid number.'), nl,
        fail
    ).

title_key(Value, Key) :-
    format(string(Text), '~w', [Value]),
    normalize_space(string(Trimmed), Text),
    string_lower(Trimmed, Key).

%% read_text_or_keep(+Prompt, +Old, -New)  —  '-' keeps current value, empty input requires re-entry
read_text_or_keep(Prompt, Old, New) :-
    repeat,
    write(Prompt),
    read_line_to_string(user_input, Raw),
    normalize_space(string(Clean), Raw),
    ( Clean = "-" -> 
        atom_string(New, Old), !
    ; Clean = "" ->
        write('[ERROR] Please enter a value or "-" to keep current.'), nl,
        fail
    ;
        atom_string(New, Clean), !
    ).

%% read_int_or_keep(+Prompt, +Old, -New)  —  '-' keeps current value, empty input requires re-entry
read_int_or_keep(Prompt, Old, New) :-
    repeat,
    write(Prompt),
    read_line_to_string(user_input, Raw),
    normalize_space(string(Clean), Raw),
    ( Clean = "-" -> 
        New = Old, !
    ; Clean = "" ->
        write('[ERROR] Please enter a value or "-" to keep current.'), nl,
        fail
    ; catch(number_string(N, Clean), _, fail), integer(N) -> 
        New = N, !
    ;
        write('[ERROR] Invalid integer. Please try again.'), nl,
        fail
    ).

% -------------------------------------------------
% DISPLAY HELPERS
% -------------------------------------------------

%% book_sep/0  —  full-width separator that covers all columns
book_sep :-
    write('================================================================================================================================'), nl.
 
%% book_header/0  —  separator + column labels + separator
book_header :-
    book_sep,
    format('~w~t~8| ~w~t~46| ~w~t~68| ~w~t~74| ~w~t~82| ~w~t~90| ~w~t~110| ~w~n',
           ['ID', 'Title', 'Author', 'Year', 'Copies', 'Dewey', 'Category', 'Status']),
    book_sep.

%% print_book_row(+ID, +Title, +Author, +Year, +Copies, +Dewey)
print_book_row(ID, Title, Author, Year, Copies, Dewey) :-
    dewey_category(Dewey, Category),
    book_status(ID, Copies, Status),
    format('~w~t~8| ~w~t~46| ~w~t~68| ~w~t~74| ~w~t~82| ~w~t~90| ~w~t~110| ~w~n',
           [ID, Title, Author, Year, Copies, Dewey, Category, Status]).

librarian_book_sep :-
    write('========================================================================================================================================================'), nl.

print_librarian_book_row(ID, Title, Author, Year, Copies, Dewey, AddedByStaffNo) :-
    book_status(ID, Copies, Status),
    librarian_label_for_book(AddedByStaffNo, AddedByName),
    format('~w~t~8| ~w~t~46| ~w~t~68| ~w~t~74| ~w~t~82| ~w~t~90| ~w~t~108| ~w~t~138| ~w~n',
           [ID, Title, Author, Year, Copies, Dewey, Status, AddedByName, AddedByStaffNo]).

librarian_label_for_book(StaffNo, Label) :-
    ( StaffNo == none ->
        Label = '(unknown)'
    ; librarian(StaffNo, Surname, FirstName, _, _, _) ->
        format(atom(Label), '~w, ~w', [Surname, FirstName])
    ;
        Label = '(unknown)'
    ).

%% print_book_table(+EmptyMsg, +RowGoal)
%  Prints header, runs RowGoal to print rows, then a closing separator.
%  If RowGoal produces no rows, EmptyMsg is shown instead.
print_book_table(EmptyMsg, RowGoal) :-
    book_header,
    ( RowGoal -> true ; write(EmptyMsg), nl ),
    book_sep.
