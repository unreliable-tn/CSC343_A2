-- Branch Activity

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q1 cascade;

CREATE TABLE q1 (
    branch CHAR(5) NOT NULL,
    year INT NOT NULL,
    events INT NOT NULL,
    sessions FLOAT NOT NULL,
    registration INT NOT NULL,
    holdings INT NOT NULL,
    checkouts INT NOT NULL,
    duration FLOAT NOT NULL
);

DROP VIEW IF EXISTS AllBranchYearEvent CASCADE;
CREATE VIEW AllBranchYearEvent AS
SELECT 
    LB.code AS branch, 
    Years.year, 
    ActualEvents.event
FROM 
    (SELECT DISTINCT code FROM LibraryBranch) LB
CROSS JOIN 
    generate_series(2019, 2023) AS Years(year)
LEFT JOIN 
    (SELECT 
         LibraryBranch.code, 
         EXTRACT(YEAR FROM edate) AS year, 
         event
     FROM 
         LibraryBranch
         JOIN LibraryRoom ON LibraryBranch.code = LibraryRoom.library
         JOIN LibraryEvent ON LibraryRoom.id = LibraryEvent.room
         JOIN EventSchedule ON LibraryEvent.id = EventSchedule.event
     WHERE 
         EXTRACT(YEAR FROM edate) BETWEEN 2019 AND 2023) AS ActualEvents
ON 
    LB.code = ActualEvents.code AND Years.year = ActualEvents.year;

DROP VIEW IF EXISTS NumEventsPerBranchYear CASCADE;
CREATE VIEW NumEventsPerBranchYear AS
SELECT branch, 
    year, 
    COUNT(DISTINCT event) AS events
FROM AllBranchYearEvent
GROUP BY 
    branch, year;

DROP VIEW IF EXISTS AvgSessionsPerBranchYear CASCADE;
CREATE VIEW AvgSessionsPerBranchYear AS
SELECT 
    branch, year,
    CASE 
        WHEN NumEvents = 0 THEN 0
        ELSE NumSessions::FLOAT / NumEvents 
    END AS Sessions
FROM (
    SELECT 
        branch, year, COUNT(DISTINCT event) AS NumEvents, COUNT(event) AS NumSessions
    FROM 
        AllBranchYearEvent
    GROUP BY 
        branch, year
) as SessionCount;

DROP VIEW IF EXISTS AllBranchYearReg CASCADE;
CREATE VIEW AllBranchYearReg AS
SELECT 
    LB.code AS branch, 
    Years.year, 
    CASE 
        WHEN ActualReg.Registration IS NULL THEN 0
        ELSE ActualReg.Registration 
    END AS Registration
FROM 
    (SELECT DISTINCT code FROM LibraryBranch) LB
CROSS JOIN 
    generate_series(2019, 2023) AS Years(year)
LEFT JOIN 
    (SELECT 
        LibraryBranch.code, 
        EXTRACT(YEAR FROM edate) AS year, 
        COUNT(DISTINCT patron || LibraryEvent.id) AS Registration
    FROM 
        LibraryBranch
        JOIN LibraryRoom ON LibraryBranch.code = LibraryRoom.library
        JOIN LibraryEvent ON LibraryRoom.id = LibraryEvent.room
        JOIN EventSchedule ON LibraryEvent.id = EventSchedule.event
        JOIN EventSignUp ON LibraryEvent.id = EventSignUp.event
    WHERE 
        EXTRACT(YEAR FROM edate) BETWEEN 2019 AND 2023
    GROUP BY 
        LibraryBranch.code, EXTRACT(YEAR FROM edate)
    ) AS ActualReg
ON 
    LB.code = ActualReg.code AND Years.year = ActualReg.year;

DROP VIEW IF EXISTS AllHoldings CASCADE;
CREATE VIEW AllHoldings AS
SELECT 
    LB.code AS branch, 
    Years.year, 
    CASE 
        WHEN holdings IS NULL THEN 0
        ELSE holdings
    END AS holdings
FROM 
    (SELECT DISTINCT code FROM LibraryBranch) LB
CROSS JOIN 
    generate_series(2019, 2023) AS Years(year)
LEFT JOIN 
    (SELECT library, COUNT(holding) AS holdings
    FROM LibraryHolding
    GROUP BY library
    ) AS ActualHolding
ON 
    LB.code = ActualHolding.library;

DROP VIEW IF EXISTS AllCheckouts CASCADE;
CREATE VIEW AllCheckouts AS
SELECT 
    LB.code AS branch, 
    Years.year, 
    CASE 
        WHEN checkouts IS NULL THEN 0
        ELSE checkouts
    END AS checkouts
FROM 
    (SELECT DISTINCT code FROM LibraryBranch) LB
CROSS JOIN 
    generate_series(2019, 2023) AS Years(year)
LEFT JOIN 
    (SELECT 
        LibraryHolding.library,
        EXTRACT(YEAR FROM Checkout.checkout_time) AS year,
        COUNT(id) AS checkouts
    FROM Checkout
        LEFT JOIN LibraryHolding ON LibraryHolding.barcode = Checkout.copy
    GROUP BY LibraryHolding.library, year
    ) AS ActualCheckouts
ON 
    LB.code = ActualCheckouts.library AND ActualCheckouts.year = Years.year;

DROP VIEW IF EXISTS AllDurations CASCADE;
CREATE VIEW AllDurations AS
SELECT 
    LB.code AS branch, 
    Years.year, 
    CASE 
        WHEN duration IS NULL THEN 0
        ELSE duration
    END AS duration
FROM 
    (SELECT DISTINCT code FROM LibraryBranch) LB
CROSS JOIN 
    generate_series(2019, 2023) AS Years(year)
LEFT JOIN 
    (SELECT 
        LibraryHolding.library,
        EXTRACT(YEAR FROM C.checkout_time) AS year,
        AVG(
            CASE 
                WHEN DATE_PART('hour', R.return_time - C.checkout_time) >= 12 THEN DATE_PART('day', R.return_time - C.checkout_time) + 1
                ELSE DATE_PART('day', R.return_time - C.checkout_time)
            END
        ) AS duration
    FROM LibraryHolding
        LEFT JOIN 
            Checkout C ON LibraryHolding.barcode = C.copy
        LEFT JOIN 
            Return R ON C.id = R.checkout
    WHERE 
        R.return_time IS NOT NULL
    GROUP BY LibraryHolding.library, EXTRACT(YEAR FROM C.checkout_time)
    ) AS ActualDurations
ON 
    LB.code = ActualDurations.library AND ActualDurations.year = Years.year;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1
SELECT * 
FROM NumEventsPerBranchYear
    NATURAL JOIN AvgSessionsPerBranchYear 
    NATURAL JOIN AllBranchYearReg 
    NATURAL JOIN AllHoldings 
    NATURAL JOIN AllCheckouts
    NATURAL JOIN AllDurations
ORDER BY branch, year;
