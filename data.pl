% -------------------------------------------------
% DATA.PL
% Prolog Database (Facts Only)
% -------------------------------------------------

:- dynamic book/6.
:- dynamic borrower/3.
:- dynamic loan/6.
:- dynamic librarian/3.   % Optional: for future role-based access

% -------------------------------------------------
% LIBRARIAN RECORDS (Optional Role-Based Access)
% librarian(LibrarianID, Name, Position)
% -------------------------------------------------
librarian(1, 'Ms. Reyes', 'Head Librarian').
librarian(2, 'Mr. Cruz', 'Assistant Librarian').

% -------------------------------------------------
% BOOK RECORDS
% book(BookID, Title, Author, Year, Copies, Dewey)
% -------------------------------------------------
book(1, 'Introduction to Prolog', 'Clocksin & Mellish', 2003, 3, 5).
book(2, 'Artificial Intelligence', 'Stuart Russell', 2010, 2, 6).
book(3, 'Database Systems', 'Elmasri & Navathe', 2015, 4, 0).
book(4, 'Data Structures', 'Seymour Lipschutz', 2018, 5, 5).
book(5, 'Computer Networks', 'Andrew Tanenbaum', 2012, 2, 5).

% -------------------------------------------------
% BORROWER RECORDS
% borrower(BorrowerID, Name, Course)
% -------------------------------------------------
borrower(1, 'Juan Dela Cruz', 'BSCS').
borrower(2, 'Maria Santos', 'BSIT').
borrower(3, 'Pedro Reyes', 'BSIT').
borrower(4, 'Ana Lopez', 'BSCS').

% -------------------------------------------------
% LOAN RECORDS
% loan(LoanID, BookID, BorrowerID, DateBorrowed, DueDate, DateReturned)
% DateReturned = none → not yet returned
% -------------------------------------------------

% ACTIVE LOAN (not returned yet)
loan(1, 1, 1, '2026-03-01', '2026-03-08', none).
loan(2, 4, 3, '2026-03-03', '2026-03-10', none).

% RETURNED ON TIME
loan(3, 2, 2, '2026-03-05', '2026-03-12', '2026-03-11').

% RETURNED LATE (for testing overdue fee calculation)
loan(4, 3, 1, '2026-03-01', '2026-03-05', '2026-03-10').
loan(5, 5, 4, '2026-03-02', '2026-03-09', '2026-03-12').