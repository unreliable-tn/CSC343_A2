-- Overdue Items

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q2 cascade;

create table q2 (
    branch CHAR(5) NOT NULL,
    patron CHAR(20),
    title TEXT NOT NULL,
    overdue INT NOT NULL
);

DROP VIEW IF EXISTS NonreturnOverdue CASCADE;
CREATE VIEW NonreturnOverdue AS
SELECT 
    LB.code AS branch,
    P.card_number AS patron,
    H.title,
    EXTRACT(day FROM CURRENT_DATE - (C.checkout_time + interval '1 day' * 
        CASE 
            WHEN H.htype IN ('books', 'audiobooks') THEN 21 
            WHEN H.htype IN ('movies', 'music', 'magazines and newspapers') THEN 7 
        END)) AS overdue
FROM 
    Checkout C
    JOIN LibraryHolding LH ON C.copy = LH.barcode
    JOIN Holding H ON LH.holding = H.id
    JOIN LibraryBranch LB ON LH.library = LB.code
    JOIN Patron P ON C.patron = P.card_number
    LEFT JOIN Return R ON C.id = R.checkout
WHERE 
    LB.ward IN (SELECT id FROM Ward WHERE name = 'Parkdale-High Park')
    AND R.return_time IS NULL 
    AND CURRENT_DATE > (C.checkout_time + interval '1 day' * 
        CASE 
            WHEN H.htype IN ('books', 'audiobooks') THEN 21 
            WHEN H.htype IN ('movies', 'music', 'magazines and newspapers') THEN 7 
        END)::date;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
SELECT * FROM NonreturnOverdue
