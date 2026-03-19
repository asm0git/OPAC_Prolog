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
    dewey_decimal INT -- M1 Requirement
);

-- Format: borrower(ID, Name, Course)
CREATE TABLE borrowers (
    borrower_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    course VARCHAR(50)
);

-- Format: loan(ID, BookID, BorrowerID, DateBorrowed, DueDate, DateReturned)
CREATE TABLE loans (
    loan_id INT PRIMARY KEY,
    book_id INT,
    borrower_id INT,
    date_borrowed DATE,
    due_date DATE,
    date_returned DATE NULL, -- 'NULL' maps to Prolog's 'none'
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (borrower_id) REFERENCES borrowers(borrower_id)
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
INSERT INTO borrowers VALUES (1, 'Juan Dela Cruz', 'BSCS');
INSERT INTO borrowers VALUES (2, 'Maria Santos', 'BSIT');
INSERT INTO borrowers VALUES (3, 'Pedro Reyes', 'BSIT');
INSERT INTO borrowers VALUES (4, 'Ana Lopez', 'BSCS');

-- Loan Records (M2 Sync - Handling 'none' as NULL)
INSERT INTO loans VALUES (1, 1, 1, '2026-03-01', '2026-03-08', NULL); 
INSERT INTO loans VALUES (2, 4, 3, '2026-03-03', '2026-03-10', NULL);
INSERT INTO loans VALUES (3, 2, 2, '2026-03-05', '2026-03-12', '2026-03-11');
INSERT INTO loans VALUES (4, 3, 1, '2026-03-01', '2026-03-05', '2026-03-10');
INSERT INTO loans VALUES (5, 5, 4, '2026-03-02', '2026-03-09', '2026-03-12');

-- 4. ATOMIC SAVE / COMMIT (storage.pl: save_data)
COMMIT;