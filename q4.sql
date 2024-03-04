-- Explorers Contest

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q4 cascade;

CREATE TABLE q4 (
    patronID CHAR(20) NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
DROP VIEW IF EXISTS EventLibrary CASCADE;
DROP VIEW IF EXISTS EventWard CASCADE;
DROP VIEW IF EXISTS PatronEventDetails CASCADE;
DROP VIEW IF EXISTS AllWards CASCADE;

-- Define views for your intermediate steps here:
-- Get each event id with the corresponding library it is in
CREATE VIEW EventLibrary AS
SELECT le.id, lr.library
FROM LibraryEvent le JOIN LibraryRoom lr ON le.room = lr.id;

-- Get each event with the corresponding ward it is in
CREATE VIEW EventWard AS
SELECT el.id, lb.ward
FROM EventLibrary el JOIN LibraryBranch lb ON el.library = lb.code;

-- For each event a patron signs up for have the ward it takes place in as well as the date
CREATE VIEW PatronEventDetails AS
SELECT esu.patron, esu.event, ew.ward, EXTRACT(YEAR FROM es.edate) AS year
FROM EventSignUp esu
JOIN EventWard ew ON esu.event = ew.id
JOIN EventSchedule es ON ew.id = es.event;

-- GET each patron who in each year signed up for an event in each ward
CREATE VIEW AllWards AS
SELECT patron, year
FROM PatronEventDetails
GROUP BY patron, year
HAVING count(DISTINCT ward) = (
    SELECT count(id)
    FROM Ward
);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
SELECT DISTINCT patron AS patronID
FROM AllWards;