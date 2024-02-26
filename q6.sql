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

-- Define views for your intermediate steps here:
CREATE VIEW SingleAuthorBooks AS
SELECT id
FROM Holding JOIN HoldingContributor ON id = holding
WHERE htype = 'books'
GROUP BY id
HAVING count(contributor) = 1;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q6
