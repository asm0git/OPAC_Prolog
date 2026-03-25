save_data(0) :- 
    % Start transaction with autocommit false
    mysql_query('SET autocommit=0'),
    
    % Sample data insertions, these should reflect actual data to be inserted
    ( 
        % Insert for books
        mysql_query('INSERT INTO books (bk_id, title, author, year_published, copies, dewey_decimal) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE title = VALUES(title), author = VALUES(author), year_published = VALUES(year_published), copies = VALUES(copies), dewey_decimal = VALUES(dewey_decimal)', [BkID, Title, Author, YearPublished, Copies, DeweyDecimal]),
        
        % Insert for borrowers
        mysql_query('INSERT INTO borrowers (borrower_id, name, course) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name), course = VALUES(course)', [BorrowerID, Name, Course]),
        
        % Insert for librarians
        mysql_query('INSERT INTO librarians (librarian_id, name, position) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name), position = VALUES(position)', [LibrarianID, Name, Position]),
        
        % Insert for loans
        mysql_query('INSERT INTO loans (loan_id, book_id, borrower_id, date_borrowed, due_date, date_returned) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE book_id = VALUES(book_id), borrower_id = VALUES(borrower_id), date_borrowed = VALUES(date_borrowed), due_date = VALUES(due_date), date_returned = VALUES(date_returned)', [LoanID, BookID, BorrowerID, DateBorrowed, DueDate, DateReturned]),
        
        % Commit transaction
        mysql_query('COMMIT')
    -> true;
    
    % Rollback on error
    ( 
        mysql_query('ROLLBACK'), 
        fail
    ),
    
    % Restore autocommit true and disconnect
    mysql_query('SET autocommit=1'),
    mysql_disconnect().