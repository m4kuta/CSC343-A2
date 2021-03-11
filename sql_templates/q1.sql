-- Q1. Airlines

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
    pass_id INT,
    name VARCHAR(100),
    airlines INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS PassIDFullName CASCADE;
DROP VIEW IF EXISTS PassAirlines CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW PassIDFullName AS
    SELECT id, firstname||' '||surname AS "name"
    FROM passenger;

CREATE VIEW PassAirlines AS
    SELECT id, count(DISTINCT airline) AS airlines
    FROM (
        SELECT passenger.id AS id, flight.airline AS airline
        FROM booking
            JOIN flight ON booking.flight_id = flight.id
            FULL OUTER JOIN passenger ON passenger.id = booking.pass_id
        ) AS airline_bookings
    GROUP BY id;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1
SELECT *
FROM PassIDFullName NATURAL JOIN PassAirlines;
