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
INSERT INTO books VALUES (1, 'Foundations of Computing', 'R. Halvorsen', 2016, 4, 5.00);
INSERT INTO books VALUES (2, 'Programming Logic Essentials', 'D. Pineda', 2019, 3, 5.10);
INSERT INTO books VALUES (3, 'Algorithms in Practice', 'M. Ortega', 2020, 5, 5.20);
INSERT INTO books VALUES (4, 'Data Structures Workshop', 'L. Howard', 2018, 4, 5.30);
INSERT INTO books VALUES (5, 'Machine Learning Basics', 'T. Brooks', 2021, 3, 6.20);

INSERT INTO books VALUES (6, 'Modern Ethics Overview', 'P. Lambert', 2015, 2, 170.00);
INSERT INTO books VALUES (7, 'Introduction to Logic', 'A. Conway', 2017, 3, 160.00);
INSERT INTO books VALUES (8, 'Critical Thinking Guide', 'F. Murray', 2014, 4, 153.00);
INSERT INTO books VALUES (9, 'Philosophy of Mind', 'C. Novak', 2022, 2, 128.00);
INSERT INTO books VALUES (10, 'A History of Philosophy', 'J. Pritchard', 2013, 3, 109.00);

INSERT INTO books VALUES (11, 'World Religions Survey', 'S. Ahmed', 2011, 4, 200.00);
INSERT INTO books VALUES (12, 'Comparative Religion', 'R. Velasco', 2019, 3, 291.00);
INSERT INTO books VALUES (13, 'Faith and Society', 'N. Harper', 2016, 2, 261.00);
INSERT INTO books VALUES (14, 'Sacred Texts Reader', 'E. Tan', 2018, 3, 220.00);
INSERT INTO books VALUES (15, 'Religious Traditions', 'M. Duarte', 2020, 4, 230.00);

INSERT INTO books VALUES (16, 'Understanding Economics', 'K. Simmons', 2017, 5, 330.00);
INSERT INTO books VALUES (17, 'Principles of Sociology', 'I. Baxter', 2015, 3, 301.00);
INSERT INTO books VALUES (18, 'Political Science Today', 'H. Delaney', 2021, 3, 320.00);
INSERT INTO books VALUES (19, 'Public Administration', 'B. Alonzo', 2014, 2, 351.00);
INSERT INTO books VALUES (20, 'Law and Governance', 'J. Cortez', 2018, 3, 340.00);

INSERT INTO books VALUES (21, 'English Grammar Basics', 'D. Villar', 2012, 4, 425.00);
INSERT INTO books VALUES (22, 'Academic Writing Skills', 'T. Lin', 2019, 5, 428.00);
INSERT INTO books VALUES (23, 'Language and Communication', 'P. Santos', 2017, 3, 410.00);
INSERT INTO books VALUES (24, 'Speech and Rhetoric', 'G. Molina', 2016, 2, 401.00);
INSERT INTO books VALUES (25, 'Translation Techniques', 'L. Rahman', 2022, 2, 418.00);

INSERT INTO books VALUES (26, 'General Biology', 'A. Kim', 2020, 6, 570.00);
INSERT INTO books VALUES (27, 'Organic Chemistry Primer', 'N. Ellis', 2018, 4, 547.00);
INSERT INTO books VALUES (28, 'Physics for Beginners', 'R. Gao', 2015, 5, 530.00);
INSERT INTO books VALUES (29, 'Earth Science Handbook', 'S. Ibrahim', 2013, 3, 550.00);
INSERT INTO books VALUES (30, 'Environmental Science', 'M. Navarro', 2021, 4, 577.00);

INSERT INTO books VALUES (31, 'Software Engineering', 'I. Pressman', 2019, 5, 658.40);
INSERT INTO books VALUES (32, 'Database Design Concepts', 'E. Robins', 2017, 4, 658.45);
INSERT INTO books VALUES (33, 'Project Management', 'C. Winston', 2016, 3, 658.40);
INSERT INTO books VALUES (34, 'Networking Fundamentals', 'A. Dean', 2020, 4, 621.38);
INSERT INTO books VALUES (35, 'Cybersecurity Essentials', 'V. Marsh', 2022, 3, 5.80);

INSERT INTO books VALUES (36, 'Art Appreciation', 'R. Flores', 2011, 2, 700.00);
INSERT INTO books VALUES (37, 'Graphic Design Basics', 'K. Reed', 2018, 3, 741.00);
INSERT INTO books VALUES (38, 'Music Theory I', 'J. Hall', 2014, 3, 781.00);
INSERT INTO books VALUES (39, 'History of Painting', 'C. Araujo', 2015, 2, 759.00);
INSERT INTO books VALUES (40, 'Digital Photography', 'B. Knox', 2021, 4, 770.00);

INSERT INTO books VALUES (41, 'World Literature Reader', 'M. Soriano', 2010, 4, 800.00);
INSERT INTO books VALUES (42, 'Poetry Across Cultures', 'H. Lee', 2016, 3, 808.10);
INSERT INTO books VALUES (43, 'Modern Fiction Studies', 'F. Oliver', 2019, 2, 813.00);
INSERT INTO books VALUES (44, 'Drama and Performance', 'S. Quinn', 2013, 3, 822.00);
INSERT INTO books VALUES (45, 'Short Story Anthology', 'T. Reyes', 2020, 5, 808.83);

INSERT INTO books VALUES (46, 'World History Essentials', 'L. Jacobs', 2012, 4, 909.00);
INSERT INTO books VALUES (47, 'Philippine History', 'A. Mendoza', 2018, 3, 959.90);
INSERT INTO books VALUES (48, 'History of Civilizations', 'P. Nolan', 2017, 2, 930.00);
INSERT INTO books VALUES (49, 'Asian History Survey', 'D. Park', 2021, 3, 950.00);
INSERT INTO books VALUES (50, 'Historical Methods', 'R. Cheng', 2014, 2, 907.20);

-- Borrower Records
-- No pre-seeded borrowers.

-- Loan Records (M2 Sync - Handling 'none' as NULL)
-- No pre-seeded loans.

-- 4. ATOMIC SAVE / COMMIT (storage.pl: save_data)
COMMIT;