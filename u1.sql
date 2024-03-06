SET SEARCH_PATH TO Library, public;

DROP VIEW IF EXISTS EventDetails1 CASCADE;
DROP VIEW IF EXISTS EventDetails2 CASCADE;
DROP VIEW IF EXISTS EventDetails CASCADE;
DROP VIEW IF EXISTS OutOfBoundsEvents CASCADE;
DROP VIEW IF EXISTS NoSessions CASCADE;

-- Get the id, room, start and end time of each event
CREATE VIEW EventDetails1 AS
SELECT le.id, le.room, TO_CHAR(es.edate, 'dy') AS edate, es.start_time, es.end_time
FROM LibraryEvent le JOIN EventSchedule es ON le.id = es.event;

-- Get id, library, start and end time of each event
CREATE VIEW EventDetails2 AS
SELECT ed1.id, lr.library, ed1.edate, ed1.start_time, ed1.end_time 
FROM EventDetails1 ed1 JOIN LibraryRoom lr ON ed1.room = lr.id;

-- Get id, library, start and end time of each event and open adn close time of each library
CREATE VIEW EventDetails AS 
SELECT ed2.id, ed2.library, ed2.start_time, ed2.end_time, lh.day, lh.start_time AS open, lh.end_time AS close
FROM EventDetails2 ed2 JOIN LibraryHours lh ON ed2.library = lh.library
WHERE ed2.edate = CAST(lh.day AS VARCHAR);

-- Get all event ids that are out of bounds
CREATE VIEW OutOfBoundsEvents AS
SELECT DISTINCT id
FROM EventDetails
WHERE start_time < open
OR end_time > close;

-- Delete all out of bounds events
DELETE FROM EventSchedule
WHERE event IN (
    SELECT id FROM OutOfBoundsEvents
);

-- Get all events that no longer have any sessions
CREATE VIEW NoSessions AS
SELECT id
FROM LibraryEvent
WHERE id NOT IN (
    SELECT event
    FROM EventSchedule
);

-- Delete all events that have no sessions
DELETE FROM LibraryEvent
WHERE id IN (
    SELETC * FROM NoSessions
);

-- Remove any signups for events that have no sessions
DELETE FROM EventSignUp
WHERE event IN (
    SELECT * FROM NoSessions
);