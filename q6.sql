-- Devoted Fans
 
-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q6 cascade;

CREATE TABLE q6 (
    patronID Char(20) NOT NULL,
    devotedness INT NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
DROP VIEW IF EXISTS SingleAuthorBooks CASCADE;
DROP VIEW IF EXISTS AtLeastTwo CASCADE;
DROP VIEW IF EXISTS SingleAuthor2 CASCADE;
DROP VIEW IF EXISTS BooksCheckedOut CASCADE;
DROP VIEW IF EXISTS PatronAuthor CASCADE;
DROP VIEW IF EXISTS PatronAuthorCount CASCADE;
DROP VIEW IF EXISTS AllButOne CASCADE;
DROP VIEW IF EXISTS AuthorReviews CASCADE;
DROP VIEW IF EXISTS ReviewedAll CASCADE;
DROP VIEW IF EXISTS HighReviews CASCADE;
DROP VIEW IF EXISTS AllConds CASCADE;

-- Define views for your intermediate steps here:
-- Get all books and authors for books that have a single author
CREATE VIEW SingleAuthorBooks AS
SELECT Distinct id, contributor
FROM (
    SELECT id
    FROM Holding JOIN HoldingContributor ON id = holding
    WHERE htype = 'books'
    GROUP BY id
    HAVING count(contributor) = 1
) AS Books JOIN HoldingContributor ON holding = id;

-- Get all single authors who have made more than 1 book
CREATE VIEW AtLeastTwo AS
SELECT contributor
FROM SingleAuthorBooks
GROUP BY contributor
HAVING count(id) > 1;

-- Get all book ids and authors who have more than one book only by themselves
CREATE VIEW SingleAuthor2 AS
SELECT *
FROM SingleAuthorBooks
WHERE contributor IN (
    SELECT * FROM AtLeastTwo
);

-- Get every book each patron has checked out
CREATE VIEW BooksCheckedOut AS
SELECT Distinct patron, holding
FROM Checkout c JOIN LibraryHolding lh ON c.copy = lh.barcode;

-- For each patron get each book they checked out along with the author of that book
CREATE VIEW PatronAuthor AS
SELECT patron, contributor, holding
FROM BooksCheckedOut n JOIN SingleAuthor2 s ON n.holding = s.id;

-- Get each author and the number of books from them that each patron has checked out
CREATE VIEW PatronAuthorCount AS
SELECT patron, contributor, count(holding)
FROM BooksCheckedOut n JOIN SingleAuthor2 s ON n.holding = s.id
GROUP BY patron, contributor;

-- Get every patron who has signed out all but one of the corresponding authors books
CREATE VIEW AllButOne AS
SELECT pa.patron, pa.contributor
FROM PatronAuthorCount pa
WHERE pa.count >= (
    SELECT count(*) - 1
    FROM SingleAuthor2 sa2
    WHERE pa.contributor = sa2.contributor
);

-- Get all reviews each patron left for each author
CREATE VIEW AuthorReviews AS
SELECT DISTINCT pa.patron, pa.contributor, pa.holding, r.stars
FROM PatronAuthor pa JOIN Review r ON pa.holding = r.holding;

-- Get every patron who has reviewed all of the corresponding authors book that they have checked out
CREATE VIEW ReviewedAll AS
SELECT r.patron, r.contributor
FROM (
    SELECT patron, contributor, count(holding)
    FROM AuthorReviews
    GROUP BY patron, contributor
) r
WHERE r.count = (
    SELECT count
    FROM PatronAuthorCount pac
    WHERE r.patron = pac.patron
    AND r.contributor = pac.contributor
);

-- All patrons who have an avg score for the corresponding author greater than 4
CREATE VIEW HighReviews AS
SELECT patron, contributor
FROM AuthorReviews
GROUP BY patron, contributor
HAVING avg(stars) >= 4.0;

-- All conditions joined together with the patron and corresponding author
CREATE VIEW AllConds AS
(SELECT * FROM AllButOne)
INTERSECT
(SELECT * FROM ReviewedAll)
INTERSECT
(SELECT * FROM HighReviews);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q6
SELECT p.card_number, count(contributor)
FROM Patron p LEFT JOIN AllConds ac ON p.card_number = ac.patron
GROUP BY p.card_number;
