SET SEARCH_PATH TO Library, public;

DROP VIEW IF EXISTS OpenSunday CASCADE;
DROP VIEW IF EXISTS OpenPast6 CASCADE;
DROP VIEW IF EXISTS ToUpdate CASCADE;

-- All libraries that are open on sunday
CREATE VIEW OpenSunday AS
SELECT DISTINCT library
FROM LibraryHours
WHERE CAST(day AS VARCHAR) = 'sun';

-- Get all libraries that are opne past 6 on a weekday
CREATE VIEW OpenPast6 AS
SELECT DISTINCT library
FROM LibraryHours
WHERE CAST(day AS VARCHAR) <> 'sat'
AND CAST(day AS VARCHAR) <> 'sun'
AND CAST(TO_CHAR(end_time, 'HH24') AS INT) > 18;

-- Get all libraries that are not open on sundays and do not open past 6pm on weekdays
-- whos hours should be updated on Thursdays
CREATE VIEW ToUpdate AS
SELECT DISTINCT library
FROM LibraryHours
WHERE library NOT IN (
    (SELECT * FROM OpenSunday)
    UNION
    (SELECT * FROM OpenPast6)
)
AND CAST(day AS varchar) = 'thu';

-- Get all libraries that are not open on sundays and do not open past 6pm on weekdays
-- whos hours should be added on Thursdays
CREATE VIEW ToAdd AS
SELECT DISTINCT library
FROM LibraryHours
WHERE library NOT IN (
    (SELECT * FROM OpenSunday)
    UNION
    (SELECT * FROM OpenPast6)
)
AND library NOT IN (
    SELECT * FROM ToUpdate
);

-- Update hours for libraries in ToUpdate
UPDATE LibraryHours
SET end_time = CAST('21:00:00' AS TIME)
WHERE library IN (
    SELECT * FROM ToUpdate
)
AND CAST(day AS VARCHAR) = 'thu';

-- Add hours on thursday for libraries in ToAdd
INSERT INTO LibraryHours (
    SELECT library, CAST('thu' AS week_day) AS day, CAST('18:00:00' AS TIME) AS start_time, CAST('21:00:00' AS TIME) AS end_time
    FROM ToAdd
);