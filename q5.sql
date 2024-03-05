-- Lure Them Back

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q5 cascade;

CREATE TABLE q5 (
    patronID CHAR(20) NOT NULL,
    email TEXT NOT NULL,
    usage INT NOT NULL,
    decline INT NOT NULL,
    missed INT NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
DROP VIEW IF EXISTS CheckoutDetails CASCADE;
DROP VIEW IF EXISTS Active2022 CASCADE;
DROP VIEW IF EXISTS Active2023 CASCADE;
DROP VIEW IF EXISTS NotActive2024 CASCADE;
DROP VIEW IF EXISTS CheckoutDetailsValid CASCADE;
DROP VIEW IF EXISTS PatronEmail CASCADE;
DROP VIEW IF EXISTS PatronUsage CASCADE;
DROP VIEW IF EXISTS Checkouts2022 CASCADE;
DROP VIEW IF EXISTS Checkouts2023 CASCADE;
DROP VIEW IF EXISTS PatronDecline CASCADE;
DROP VIEW IF EXISTS PatronMissed CASCADE;

-- Define views for your intermediate steps here:
-- Get details about every checkout
CREATE VIEW CheckoutDetails AS
SELECT c.patron, c.copy, lh.holding, EXTRACT(YEAR FROM c.checkout_time) AS year, EXTRACT(MONTH FROM c.checkout_time) AS month
FROM Checkout c JOIN LibraryHolding lh ON c.copy = lh.barcode;

-- Get every patron who checked out a book in every month of 2022
CREATE VIEW Active2022 AS
SELECT patron
FROM CheckoutDetails
WHERE year = 2022
GROUP BY patron
HAVING count(DISTINCT month) = 12;

-- Get every patron who checked out a book in at least 5 months of 2023
CREATE VIEW Active2023 AS
SELECT patron
FROM CheckoutDetails
WHERE year = 2023
GROUP BY patron
HAVING count(DISTINCT month) >= 5;

-- Get every patron who did not check out a book in 2024
CREATE VIEW NotActive2024 AS
SELECT DISTINCT patron
FROM CheckoutDetails
WHERE patron NOT IN (
    SELECT patron
    FROM CheckoutDetails
    WHERE year = 2024
    GROUP BY patron
    HAVING count(DISTINCT month) <> 0
);

-- Get checkout details of the patrons that meet the above 3 criteria
CREATE VIEW CheckoutDetailsValid AS
SELECT cd.patron, cd.copy, cd.holding, cd.year, cd.month
FROM CheckoutDetails cd
JOIN Active2022 a2 ON cd.patron = a2.patron
JOIN Active2023 a3 ON a2.patron = a3.patron
JOIN NotActive2024 na4 ON a3.patron = na4.patron;

-- Get each patron and their email address
CREATE VIEW PatronEmail AS
SELECT card_number AS patronID, COALESCE(email, 'none') AS email
FROM Patron;

-- Get each patron and their usage (# of different holdings checked out)
CREATE VIEW PatronUsage AS
SELECT patron AS patronID, count(DISTINCT holding) AS usage
FROM CheckoutDetailsValid
GROUP BY patron;

-- Get each patron and the number of checkouts in 2022
CREATE VIEW Checkouts2022 AS
SELECT patron, count(*) AS count2022
FROM CheckoutDetailsValid
WHERE year = 2022
GROUP BY patron;

-- Get each patron and the number of checkouts in 2023
CREATE VIEW Checkouts2023 AS
SELECT patron, count(*) AS count2023
FROM CheckoutDetailsValid
WHERE year = 2023
GROUP BY patron;

-- Get each patron and their decline
CREATE VIEW PatronDecline AS 
SELECT DISTINCT cd.patron AS patronID, COALESCE(c2.count2022, 0) - COALESCE(c3.count2023, 0) AS decline
FROM CheckoutDetailsValid cd
LEFT JOIN Checkouts2022 c2 ON cd.patron = c2.patron
JOIN Checkouts2023 c3 ON c2.patron = c3.patron;

--Get each patron and the amount of months they did not checkout out anything in 2023
CREATE VIEW PatronMissed AS
SELECT patron AS patronID, 12 - count(distinct month) AS missed
FROM CheckoutDetailsValid
WHERE year = 2023
GROUP BY patron;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5
SELECT pe.patronID, pe.email, pu.usage, pd.decline, COALESCE(pm.missed, 0) AS missed
FROM PatronEmail pe
RIGHT JOIN PatronUsage pu ON pe.patronID = pu.patronID
JOIN PatronDecline pd ON pu.patronID = pd.patronID
JOIN PatronMissed pm ON pd.patronID = pm.patronID;