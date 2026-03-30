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

-- Format: librarian(StaffNumber, Surname, FirstName, MiddleInitial, Position, Password)
CREATE TABLE librarians (
    staff_number VARCHAR(50) PRIMARY KEY,
    surname VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_initial CHAR(1),
    position VARCHAR(50),
    password VARCHAR(100) NOT NULL
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

-- Format: loan(ID, BookID, BorrowerID, DateBorrowed, DueDate, DateReturned, IsReturned)
CREATE TABLE loans (
    loan_id INT PRIMARY KEY,
    book_id INT,
    student_number INT,
    date_borrowed DATE,
    due_date DATE,
    date_returned DATE NULL,
    is_returned BOOLEAN NOT NULL DEFAULT 0,
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (student_number) REFERENCES borrowers(student_number)
);

-- 3. DATA PERSISTENCE (storage.pl: save_data / data.pl Facts)

-- Librarian Records
INSERT INTO librarians VALUES ('LIB001', 'Reyes', 'Maria', 'S', 'Head Librarian', 'SecurePass1');
INSERT INTO librarians VALUES ('LIB002', 'Cruz', 'Juan', 'P', 'Assistant Librarian', 'SecurePass2');
INSERT INTO librarians VALUES ('LIB003', 'Garcia', 'Elena', 'M', 'Reference Librarian', 'SecurePass3');
INSERT INTO librarians VALUES ('LIB004', 'Dela Cruz', 'Paolo', 'R', 'Circulation Librarian', 'SecurePass4');
INSERT INTO librarians VALUES ('LIB005', 'Santos', 'Liza', 'A', 'Catalog Librarian', 'SecurePass5');
INSERT INTO librarians VALUES ('LIB006', 'Mendoza', 'Carlo', 'N', 'Acquisitions Librarian', 'SecurePass6');
INSERT INTO librarians VALUES ('LIB007', 'Torres', 'Ivy', 'D', 'Reference Librarian', 'SecurePass7');
INSERT INTO librarians VALUES ('LIB008', 'Flores', 'Noel', 'J', 'Library Assistant', 'SecurePass8');
INSERT INTO librarians VALUES ('LIB009', 'Ramos', 'Trisha', 'L', 'Library Assistant', 'SecurePass9');
INSERT INTO librarians VALUES ('LIB010', 'Villanueva', 'Marco', 'B', 'Archivist', 'SecurePass10');
INSERT INTO librarians VALUES ('LIB011', 'Aquino', 'Bea', 'C', 'Catalog Librarian', 'SecurePass11');
INSERT INTO librarians VALUES ('LIB012', 'Navarro', 'Jules', 'F', 'Circulation Librarian', 'SecurePass12');
INSERT INTO librarians VALUES ('LIB013', 'Lopez', 'Karen', 'T', 'Reference Librarian', 'SecurePass13');
INSERT INTO librarians VALUES ('LIB014', 'Domingo', 'Rafael', 'G', 'Library Assistant', 'SecurePass14');
INSERT INTO librarians VALUES ('LIB015', 'Castro', 'Mina', 'H', 'Acquisitions Librarian', 'SecurePass15');

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
INSERT INTO borrowers VALUES
(205000, 'Dela Cruz', 'Juan Miguel', 'R', 'BEd', 'pass205000'),
(205001, 'Santos', 'Maria Luisa', 'A', 'CCJEF', 'pass205001'),
(205002, 'Reyes', 'Mark Anthony', 'L', 'SAS', 'pass205002'),
(205003, 'Garcia', 'Alyssa Mae', 'D', 'SBA', 'pass205003'),
(205004, 'Mendoza', 'Christian Paul', 'T', 'SEA', 'pass205004'),
(205005, 'Flores', 'Jessa Marie', 'N', 'SEd', 'pass205005'),
(205006, 'Torres', 'Carlo James', 'B', 'SHTM', 'pass205006'),
(205007, 'Ramos', 'Angelica Joy', 'P', 'SNAMS', 'pass205007'),
(205008, 'Villanueva', 'Patrick John', 'M', 'SOC', 'pass205008'),
(205009, 'Aquino', 'Kimberly Anne', 'C', 'BEd', 'pass205009'),
(205010, 'Navarro', 'Ronald Jay', 'S', 'CCJEF', 'pass205010'),
(205011, 'Lopez', 'Shaina Mae', 'G', 'SAS', 'pass205011'),
(205012, 'Domingo', 'Jerome Kyle', 'V', 'SBA', 'pass205012'),
(205013, 'Castro', 'Bianca Rose', 'E', 'SEA', 'pass205013'),
(205014, 'Cruz', 'Neil Andrew', 'H', 'SEd', 'pass205014'),
(205015, 'Fernandez', 'Trisha Mae', 'J', 'SHTM', 'pass205015'),
(205016, 'Gonzales', 'Paulo Miguel', 'K', 'SNAMS', 'pass205016'),
(205017, 'Bautista', 'Danica Faith', 'O', 'SOC', 'pass205017'),
(205018, 'Morales', 'Kevin Dale', 'Q', 'BEd', 'pass205018'),
(205019, 'Chavez', 'Rica Mae', 'Y', 'CCJEF', 'pass205019'),
(205020, 'Mercado', 'John Carlo', 'U', 'SAS', 'pass205020'),
(205021, 'Salazar', 'Camille Joy', 'F', 'SBA', 'pass205021'),
(205022, 'Pascual', 'Bryan Lee', 'I', 'SEA', 'pass205022'),
(205023, 'Valdez', 'Mikaela Anne', 'W', 'SEd', 'pass205023'),
(205024, 'De Leon', 'Joshua Mark', 'Z', 'SHTM', 'pass205024'),
(205025, 'Serrano', 'Patricia Mae', 'R', 'SNAMS', 'pass205025'),
(205026, 'Manalo', 'Ethan Paul', 'A', 'SOC', 'pass205026'),
(205027, 'Alcantara', 'Lara Nicole', 'L', 'BEd', 'pass205027'),
(205028, 'Cabral', 'Nathaniel', 'D', 'CCJEF', 'pass205028'),
(205029, 'David', 'Francesca Joy', 'T', 'SAS', 'pass205029'),
(205030, 'Evangelista', 'Miguel Angelo', 'N', 'SBA', 'pass205030'),
(205031, 'Francisco', 'Janelle Marie', 'B', 'SEA', 'pass205031'),
(205032, 'Herrera', 'Ralph Vincent', 'P', 'SEd', 'pass205032'),
(205033, 'Ilagan', 'Nina Camille', 'M', 'SHTM', 'pass205033'),
(205034, 'Javier', 'Sean Patrick', 'C', 'SNAMS', 'pass205034'),
(205035, 'Luna', 'Angel Mae', 'S', 'SOC', 'pass205035'),
(205036, 'Malonzo', 'Adrian Kyle', 'G', 'BEd', 'pass205036'),
(205037, 'Natividad', 'Rhea Mae', 'V', 'CCJEF', 'pass205037'),
(205038, 'Ocampo', 'Bryle John', 'E', 'SAS', 'pass205038'),
(205039, 'Padilla', 'Kristine Anne', 'H', 'SBA', 'pass205039'),
(205040, 'Quintos', 'Derrick Paul', 'J', 'SEA', 'pass205040'),
(205041, 'Rosales', 'Melissa Joy', 'K', 'SEd', 'pass205041'),
(205042, 'Samson', 'Harold James', 'O', 'SHTM', 'pass205042'),
(205043, 'Tan', 'Lianne Marie', 'Q', 'SNAMS', 'pass205043'),
(205044, 'Uy', 'Vincent Mark', 'Y', 'SOC', 'pass205044'),
(205045, 'Vega', 'Princess Mae', 'U', 'BEd', 'pass205045'),
(205046, 'Yap', 'Dominic Paul', 'F', 'CCJEF', 'pass205046'),
(205047, 'Zamora', 'Christine Joy', 'I', 'SAS', 'pass205047'),
(205048, 'Abad', 'Jerson Kyle', 'W', 'SBA', 'pass205048'),
(205049, 'Beltran', 'Kathleen Mae', 'Z', 'SEA', 'pass205049'),
(205050, 'Calderon', 'Renz Allan', 'R', 'SEd', 'pass205050'),
(205051, 'Dizon', 'Catrina Rose', 'A', 'SHTM', 'pass205051'),
(205052, 'Enriquez', 'Paul Marvin', 'L', 'SNAMS', 'pass205052'),
(205053, 'Fajardo', 'Jasmine Mae', 'D', 'SOC', 'pass205053'),
(205054, 'Galang', 'Kevin Lloyd', 'T', 'BEd', 'pass205054'),
(205055, 'Hipolito', 'Andrea Joy', 'N', 'CCJEF', 'pass205055'),
(205056, 'Imperial', 'Lester John', 'B', 'SAS', 'pass205056'),
(205057, 'Jacinto', 'Nicole Anne', 'P', 'SBA', 'pass205057'),
(205058, 'Katigbak', 'Aaron Miguel', 'M', 'SEA', 'pass205058'),
(205059, 'Lansang', 'Mariel Mae', 'C', 'SEd', 'pass205059'),
(205060, 'Macaraig', 'Noel Christian', 'S', 'SHTM', 'pass205060'),
(205061, 'Nolasco', 'Faith Marie', 'G', 'SNAMS', 'pass205061'),
(205062, 'Ortega', 'Jeric Paul', 'V', 'SOC', 'pass205062'),
(205063, 'Pangilinan', 'Aira Mae', 'E', 'BEd', 'pass205063'),
(205064, 'Querubin', 'Rico James', 'H', 'CCJEF', 'pass205064'),
(205065, 'Roces', 'Denise Joy', 'J', 'SAS', 'pass205065'),
(205066, 'Santiago', 'Tristan Kyle', 'K', 'SBA', 'pass205066'),
(205067, 'Tolentino', 'Megan Rose', 'O', 'SEA', 'pass205067'),
(205068, 'Umali', 'Joshua Paul', 'Q', 'SEd', 'pass205068'),
(205069, 'Villareal', 'Kyla Mae', 'Y', 'SHTM', 'pass205069'),
(205070, 'Arriola', 'Bryan Mark', 'U', 'SNAMS', 'pass205070'),
(205071, 'Balingit', 'Sophia Anne', 'F', 'SOC', 'pass205071'),
(205072, 'Canlas', 'Enzo Miguel', 'I', 'BEd', 'pass205072'),
(205073, 'Daclan', 'Rica Joy', 'W', 'CCJEF', 'pass205073'),
(205074, 'Eusebio', 'Nathan Paul', 'Z', 'SAS', 'pass205074'),
(205075, 'Fronda', 'Bea Marie', 'R', 'SBA', 'pass205075'),
(205076, 'Guinto', 'Carlo Ivan', 'A', 'SEA', 'pass205076'),
(205077, 'Hernando', 'Lianne Joy', 'L', 'SEd', 'pass205077'),
(205078, 'Inocencio', 'Marc Daniel', 'D', 'SHTM', 'pass205078'),
(205079, 'Joson', 'Patricia Anne', 'T', 'SNAMS', 'pass205079'),
(205080, 'Llagas', 'Rafael Miguel', 'N', 'SOC', 'pass205080'),
(205081, 'Mabalot', 'Isabel Mae', 'B', 'BEd', 'pass205081'),
(205082, 'Nisperos', 'Gerald John', 'P', 'CCJEF', 'pass205082'),
(205083, 'Olivarez', 'Camille Rose', 'M', 'SAS', 'pass205083'),
(205084, 'Pineda', 'Jason Mark', 'C', 'SBA', 'pass205084'),
(205085, 'Ricarte', 'Trina Joy', 'S', 'SEA', 'pass205085'),
(205086, 'Soriano', 'Kevin Paul', 'G', 'SEd', 'pass205086'),
(205087, 'Tiongson', 'Janelle Mae', 'V', 'SHTM', 'pass205087'),
(205088, 'Vergara', 'Adrian James', 'E', 'SNAMS', 'pass205088'),
(205089, 'Wenceslao', 'Mika Anne', 'H', 'SOC', 'pass205089'),
(205090, 'Alvarez', 'Jerome Mark', 'J', 'BEd', 'pass205090'),
(205091, 'Bernardo', 'Ariana Joy', 'K', 'CCJEF', 'pass205091'),
(205092, 'Cunanan', 'Dylan Paul', 'O', 'SAS', 'pass205092'),
(205093, 'Del Rosario', 'Katrina Mae', 'Q', 'SBA', 'pass205093'),
(205094, 'Estrella', 'Noah Miguel', 'Y', 'SEA', 'pass205094'),
(205095, 'Feliciano', 'Riza Anne', 'U', 'SEd', 'pass205095'),
(205096, 'Gatchalian', 'Paolo James', 'F', 'SHTM', 'pass205096'),
(205097, 'Hilario', 'Jessa Joy', 'I', 'SNAMS', 'pass205097'),
(205098, 'Isidro', 'Caleb John', 'W', 'SOC', 'pass205098'),
(205099, 'Lacson', 'Monique Mae', 'Z', 'BEd', 'pass205099');

-- Loan Records (M2 Sync - Handling 'none' as NULL)
INSERT INTO loans VALUES (1, 1, 205000, '2026-03-01', '2026-03-08', '2026-03-07', 1);
INSERT INTO loans VALUES (2, 2, 205001, '2026-03-02', '2026-03-09', NULL, 0);
INSERT INTO loans VALUES (3, 3, 205002, '2026-03-03', '2026-03-10', '2026-03-09', 1);
INSERT INTO loans VALUES (4, 4, 205003, '2026-03-04', '2026-03-11', NULL, 0);
INSERT INTO loans VALUES (5, 5, 205004, '2026-03-05', '2026-03-12', '2026-03-10', 1);
INSERT INTO loans VALUES (6, 6, 205005, '2026-03-06', '2026-03-13', NULL, 0);
INSERT INTO loans VALUES (7, 7, 205006, '2026-03-07', '2026-03-14', '2026-03-13', 1);
INSERT INTO loans VALUES (8, 8, 205007, '2026-03-08', '2026-03-15', NULL, 0);
INSERT INTO loans VALUES (9, 9, 205008, '2026-03-09', '2026-03-16', '2026-03-15', 1);
INSERT INTO loans VALUES (10, 10, 205009, '2026-03-10', '2026-03-17', NULL, 0);
INSERT INTO loans VALUES (11, 11, 205010, '2026-03-11', '2026-03-18', '2026-03-17', 1);
INSERT INTO loans VALUES (12, 12, 205011, '2026-03-12', '2026-03-19', NULL, 0);
INSERT INTO loans VALUES (13, 13, 205012, '2026-03-13', '2026-03-20', '2026-03-18', 1);
INSERT INTO loans VALUES (14, 14, 205013, '2026-03-14', '2026-03-21', NULL, 0);
INSERT INTO loans VALUES (15, 15, 205014, '2026-03-15', '2026-03-22', '2026-03-21', 1);

-- 4. ATOMIC SAVE / COMMIT (storage.pl: save_data)
COMMIT;