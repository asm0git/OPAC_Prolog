-- -------------------------------------------------
-- OPAC SYSTEM - DATABASE SCHEMA (Relational Mapping)
-- Mapped from data.pl & storage.pl to comply with IMAN Requirements
-- -------------------------------------------------

-- 1. DATABASE INITIALIZATION (storage.pl: load_data)
-- Prolog: retractall(book/6), retractall(loan/6), etc.
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS borrowers;
DROP TABLE IF EXISTS librarians;

-- 2. SCHEMA DEFINITION (data.pl Structure)

-- Format: librarian(ID, Name, Position)
CREATE TABLE librarians (
    librarian_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    position VARCHAR(50)
);

-- Format: book(ID, Title, Author, Year, Copies, Dewey)
CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(100),
    year_published INT,
    copies INT DEFAULT 1,
    dewey_decimal DECIMAL(10,2) -- M1 Requirement
);

-- Format: borrower(StudentNumber, Surname, FirstName, MiddleInitial, Department, Password)
CREATE TABLE borrowers (
    student_number INT PRIMARY KEY,
    surname VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_initial CHAR(1),
    department VARCHAR(50),
    password VARCHAR(100) NOT NULL
);

-- Format: loan(ID, BookID, BorrowerID, DateBorrowed, DueDate, DateReturned)
CREATE TABLE loans (
    loan_id INT PRIMARY KEY,
    book_id INT,
    student_number INT,
    date_borrowed DATE,
    due_date DATE,
    date_returned DATE NULL, -- 'NULL' maps to Prolog's 'none'
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (student_number) REFERENCES borrowers(student_number)
);

-- 3. DATA PERSISTENCE (storage.pl: save_data / data.pl Facts)

-- Librarian Records
INSERT INTO librarians VALUES (1, 'Ms. Reyes', 'Head Librarian');
INSERT INTO librarians VALUES (2, 'Mr. Cruz', 'Assistant Librarian');

-- Book Records (M1 Sync)
INSERT INTO books VALUES (1, 'Introduction to Prolog', 'Clocksin & Mellish', 2003, 3, 5);
INSERT INTO books VALUES (2, 'Artificial Intelligence', 'Stuart Russell', 2010, 2, 6);
INSERT INTO books VALUES (3, 'Database Systems', 'Elmasri & Navathe', 2015, 4, 0);
INSERT INTO books VALUES (4, 'Data Structures', 'Seymour Lipschutz', 2018, 5, 5);
INSERT INTO books VALUES (5, 'Computer Networks', 'Andrew Tanenbaum', 2012, 2, 5);

-- Borrower Records
-- No pre-seeded borrowers.

-- Loan Records (M2 Sync - Handling 'none' as NULL)
-- No pre-seeded loans.

-- 4. ATOMIC SAVE / COMMIT (storage.pl: save_data)
COMMIT;