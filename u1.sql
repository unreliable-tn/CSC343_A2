SET SEARCH_PATH TO Library, public;

DROP VIEW IF EXISTS EventDetails1 CASCADE;
DROP VIEW IF EXISTS EventDetails2 CASCADE;
DROP VIEW IF EXISTS EventDetails CASCADE;
DROP VIEW IF EXISTS OutOfBoundsEvents CASCADE;
DROP VIEW IF EXISTS AllCombos CASCADE;
DROP VIEW IF EXISTS NotOnDay CASCADE;
DROP VIEW IF EXISTS NoSessions CASCADE;

-- Get the id, room, start and end time of each event
CREATE VIEW EventDetails1 AS
SELECT le.id, le.room, es.edate, TO_CHAR(es.edate, 'dy') AS eday, es.start_time, es.end_time
FROM LibraryEvent le JOIN EventSchedule es ON le.id = es.event;

-- Get id, library, start and end time of each event
CREATE VIEW EventDetails2 AS
SELECT ed1.id, lr.library, ed1.edate, ed1.eday, ed1.start_time, ed1.end_time 
FROM EventDetails1 ed1 JOIN LibraryRoom lr ON ed1.room = lr.id;

-- Get id, library, start and end time of each event and open and close time of each library
CREATE VIEW EventDetails AS 
SELECT ed2.id, ed2.library, ed2.edate, ed2.eday, ed2.start_time, ed2.end_time, lh.day, lh.start_time AS open, lh.end_time AS close
FROM EventDetails2 ed2 JOIN LibraryHours lh ON ed2.library = lh.library;

-- Get all event ids that are out of bounds
CREATE VIEW OutOfBoundsEvents AS
SELECT DISTINCT id, edate
FROM EventDetails
WHERE eday = CAST(day AS VARCHAR)
AND (
    start_time < open
    OR end_time > close
);

-- Get all combos of libraries and days of the week
CREATE VIEW AllCombos AS
SELECT *
FROM (SELECT DISTINCT library FROM LibraryHours) l, (SELECT DISTINCT day FROM LibraryHours) d;

-- Get all days when each library is closed and then the events on those days
CREATE VIEW NotOnDay AS
SELECT DISTINCT ed.id, ed.edate
FROM (
    (SELECT * FROM AllCombos)
    EXCEPT
    (SELECT library, day FROM LibraryHours)
) n JOIN EventDetails ed
ON n.library = ed.library
AND CAST(n.day AS VARCHAR) = ed.eday;

-- Delete all out of bounds events
DELETE FROM EventSchedule
WHERE event, edate IN (
    (SELECT id, edate FROM OutOfBoundsEvents)
    UNION
    (SELECT id, edate FROM NotOnDay)
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
    SELECT * FROM NoSessions
);

-- Remove any signups for events that have no sessions
DELETE FROM EventSignUp
WHERE event IN (
    SELECT * FROM NoSessions
);