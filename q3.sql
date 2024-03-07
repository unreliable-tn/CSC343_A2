-- Promotion

-- You must not change the next 2 lines, the domain definition, or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q3 cascade;

DROP DOMAIN IF EXISTS patronCategory;
create domain patronCategory as varchar(10)
  check (value in ('inactive', 'reader', 'doer', 'keener'));

create table q3 (
    patronID Char(20) NOT NULL,
    category patronCategory
);

-- Do items first
DROP VIEW IF EXISTS ItemUsers CASCADE;
CREATE VIEW ItemUsers AS
SELECT 
    P.card_number AS patronID,
    LB.code,
    SO.NumCheckout AS NumCheckout
FROM 
    Patron P
CROSS JOIN 
    LibraryBranch LB
LEFT JOIN 
    (SELECT 
         C.patron, 
         LH.library, 
         COUNT(*) AS NumCheckout
     FROM 
         Checkout C
     JOIN LibraryHolding LH ON C.copy = LH.barcode
     GROUP BY C.patron, LH.library) AS SO ON P.card_number = SO.patron AND LB.code = SO.library
WHERE 
    SO.NumCheckout > 0
ORDER BY patronID;

DROP VIEW IF EXISTS EventUsers CASCADE;
CREATE VIEW EventUsers AS
SELECT 
    P.card_number AS patronID,
    LB.code,
    ER.NumRegistration AS NumRegistration
FROM 
    Patron P
CROSS JOIN 
    LibraryBranch LB
LEFT JOIN 
    (SELECT 
         ES.patron, 
         LR.library,
         COUNT(*) AS NumRegistration
     FROM 
         EventSignUp ES
     JOIN LibraryEvent LE ON ES.event = LE.id
     JOIN LibraryRoom LR ON LE.room = LR.id
     GROUP BY ES.patron, LR.library) AS ER ON P.card_number = ER.patron AND LB.code = ER.library
WHERE 
    ER.NumRegistration > 0
ORDER BY patronID;

DROP VIEW IF EXISTS AllUserLibrary CASCADE;
CREATE VIEW AllUserLibrary AS
SELECT patronID, code FROM ItemUsers
UNION
SELECT patronID, code FROM EventUsers
ORDER BY patronID;

DROP VIEW IF EXISTS ItemUsersSum CASCADE;
CREATE VIEW ItemUsersSum AS
SELECT 
  patronID,
  SUM(NumCheckout) AS TotalCheckout
FROM ItemUsers GROUP BY patronID;

DROP VIEW IF EXISTS IUserLibSearch CASCADE;
CREATE VIEW IUserLibSearch AS
SELECT ItemUsersSum.patronID, code
FROM AllUserLibrary JOIN ItemUsersSum ON AllUserLibrary.patronID = ItemUsersSum.patronID;

DROP VIEW IF EXISTS IUsersLib CASCADE;
CREATE VIEW IUsersLib AS
SELECT
    ItemUsers.patronID AS patronID,
    ItemUsers.code
FROM 
    ItemUsers 
LEFT JOIN 
    EventUsers
ON 
    ItemUsers.patronID = EventUsers.patronID;

DROP VIEW IF EXISTS EventUsersSum CASCADE;
CREATE VIEW EventUsersSum AS
SELECT 
  patronID,
  SUM(NumRegistration) AS TotalRegistration
FROM EventUsers GROUP BY patronID;

DROP VIEW IF EXISTS EUserLibSearch CASCADE;
CREATE VIEW EUserLibSearch AS
SELECT EventUsersSum.patronID, code
FROM AllUserLibrary JOIN EventUsersSum ON AllUserLibrary.patronID = EventUsersSum.patronID;

DROP VIEW IF EXISTS EUsersLib CASCADE;
CREATE VIEW EUsersLib AS
SELECT
    EventUsers.patronID AS patronID,
    EventUsers.code
FROM 
    EventUsers
LEFT JOIN 
    ItemUsers 
ON 
    ItemUsers.patronID = EventUsers.patronID;

DROP VIEW IF EXISTS AllUsers CASCADE;
CREATE VIEW AllUsers AS
SELECT
    COALESCE(ItemUsersSum.patronID, EventUsersSum.patronID) AS patronID,
    COALESCE(ItemUsersSum.TotalCheckout, 0) AS TotalCheckout,
    COALESCE(EventUsersSum.TotalRegistration, 0) AS TotalRegistration
FROM 
    ItemUsersSum 
FULL JOIN 
    EventUsersSum 
ON 
    ItemUsersSum.patronID = EventUsersSum.patronID;

DROP VIEW IF EXISTS CommonItemUsers CASCADE;
CREATE VIEW CommonItemUsers AS
SELECT DISTINCT
  IULS1.patronID AS Target,
  IULS2.patronID AS Commoner
FROM IUserLibSearch IULS1
JOIN IUsersLib IULS2 ON IULS1.code = IULS2.code
ORDER BY Target, Commoner;

DROP VIEW IF EXISTS CommonEventUsers CASCADE;
CREATE VIEW CommonEventUsers AS
SELECT DISTINCT
  EU1.patronID AS Target,
  EU2.patronID AS Commoner
FROM EUserLibSearch EU1
JOIN EUsersLib EU2 ON EU1.code = EU2.code
ORDER BY Target, Commoner;

DROP VIEW IF EXISTS ItemUsersAvg CASCADE;
CREATE VIEW ItemUsersAvg AS
SELECT 
    AU.patronID AS patronID, 
    COALESCE(AVG(AU2.TotalCheckout), 0) AS AvgCommonerCheckout
FROM 
    AllUsers AU
LEFT JOIN 
    CommonItemUsers CIU ON AU.patronID = CIU.Target
LEFT JOIN 
    AllUsers AU2 ON CIU.Commoner = AU2.patronID
GROUP BY 
    AU.patronID
ORDER BY patronID;

DROP VIEW IF EXISTS ItemUsersCat CASCADE;
CREATE VIEW ItemUsersCat AS
SELECT
    patronID,
    TotalCheckout,
    AvgCommonerCheckout,
    CASE
        WHEN TotalCheckout > 0.75 * AvgCommonerCheckout THEN 'high'
        WHEN TotalCheckout < 0.25 * AvgCommonerCheckout OR AvgCommonerCheckout = 0 THEN 'low'
    END AS ItemCat
FROM
    ItemUsersAvg
NATURAL JOIN
    AllUsers
WHERE
    TotalCheckout > 0.75 * AvgCommonerCheckout OR
    TotalCheckout < 0.25 * AvgCommonerCheckout OR
    AvgCommonerCheckout = 0;

------------------------------- Now do events -------------------------------
DROP VIEW IF EXISTS EventUsersAvg CASCADE;
CREATE VIEW EventUsersAvg AS
SELECT 
    AU.patronID AS patronID, 
    COALESCE(AVG(AU2.TotalRegistration), 0) AS AvgCommonerRegistration
FROM 
    AllUsers AU
LEFT JOIN 
    CommonEventUsers CEU ON AU.patronID = CEU.Target
LEFT JOIN 
    AllUsers AU2 ON CEU.Commoner = AU2.patronID
GROUP BY 
    AU.patronID
ORDER BY patronID;

DROP VIEW IF EXISTS EventUsersCat CASCADE;
CREATE VIEW EventUsersCat AS
SELECT
    patronID,
    TotalRegistration,
    AvgCommonerRegistration,
    CASE
        WHEN TotalRegistration > 0.75 * AvgCommonerRegistration THEN 'high'
        WHEN TotalRegistration < 0.25 * AvgCommonerRegistration OR AvgCommonerRegistration = 0 THEN 'low'
    END AS EventCat
FROM
    EventUsersAvg
NATURAL JOIN
    AllUsers
WHERE
    TotalRegistration > 0.75 * AvgCommonerRegistration OR
    TotalRegistration < 0.25 * AvgCommonerRegistration OR
    AvgCommonerRegistration = 0;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
SELECT
    COALESCE(EventUsersCat.patronID, ItemUsersCat.patronID) AS patronID,
    CASE
        WHEN ItemUsersCat.ItemCat = 'low' AND EventUsersCat.EventCat = 'low' THEN 'inactive'
        WHEN ItemUsersCat.ItemCat = 'high' AND EventUsersCat.EventCat = 'low' THEN 'reader'
        WHEN ItemUsersCat.ItemCat = 'low' AND EventUsersCat.EventCat = 'high' THEN 'doer'
        WHEN ItemUsersCat.ItemCat = 'high' AND EventUsersCat.EventCat = 'high' THEN 'keener'
    END AS category
FROM 
    EventUsersCat 
FULL JOIN 
    ItemUsersCat 
ON 
    EventUsersCat.patronID = ItemUsersCat.patronID
WHERE
    ItemUsersCat.ItemCat IS NOT NULL AND
    EventUsersCat.EventCat IS NOT NULL AND
    (ItemUsersCat.ItemCat, EventUsersCat.EventCat) IN (('low', 'low'), ('high', 'low'), ('low', 'high'), ('high', 'high'))
ORDER BY patronID;
