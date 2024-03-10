SET SEARCH_PATH TO Library, public;

DROP VIEW IF EXISTS EligiblePatrons CASCADE;
CREATE VIEW EligiblePatrons AS
SELECT patron
FROM Checkout
JOIN LibraryHolding ON Checkout.copy = LibraryHolding.barcode
JOIN Holding ON LibraryHolding.holding = Holding.id
JOIN LibraryBranch ON LibraryHolding.library = LibraryBranch.code
WHERE LibraryBranch.name = 'Downsview'
  AND Holding.htype = 'books'
  AND checkout_time + INTERVAL '21 days' < CURRENT_DATE
  AND checkout_time + INTERVAL '21 days' >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY patron
HAVING COUNT(*) <= 5;

DROP VIEW IF EXISTS DownsviewBooks CASCADE;
CREATE VIEW DownsviewBooks AS
SELECT barcode
FROM LibraryHolding
JOIN Holding ON LibraryHolding.holding = Holding.id
JOIN LibraryBranch ON LibraryHolding.library = LibraryBranch.code
WHERE LibraryBranch.name = 'Downsview'
  AND htype = 'books';

UPDATE Checkout
SET checkout_time = checkout_time + INTERVAL '14 days'
WHERE patron IN (SELECT patron FROM EligiblePatrons)
    AND copy IN (SELECT barcode FROM PatronBooks);