-- Q3. North and South Connections

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    outbound VARCHAR(30),
    inbound VARCHAR(30),
    direct INT,
    one_con INT,
    two_con INT,
    earliest timestamp
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS PossibleCityRoutes CASCADE;
DROP VIEW IF EXISTS FlightsOnSameDate CASCADE;
DROP VIEW IF EXISTS Direct CASCADE;
DROP VIEW IF EXISTS OneConn CASCADE;
DROP VIEW IF EXISTS TwoConn CASCADE;
DROP VIEW IF EXISTS Earliest CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW PossibleCityRoutes AS
    SELECT DISTINCT a1.city AS outbound, a2.city AS inbound
    FROM airport a1, airport a2
    WHERE a1.country = 'Canada' AND a2.country = 'USA'
       OR a1.country = 'USA' AND a2.country = 'Canada';

CREATE VIEW FlightsOnSameDate AS
    SELECT id,
           airport_outbound,
           outbound, inbound AS airport_inbound,
           city AS inbound, s_dep, s_arv
    FROM (SELECT id,
                 outbound AS airport_outbound,
                 city AS outbound,
                 inbound,
                 s_dep,
                 s_arv
          FROM flight
              JOIN airport
                  ON flight.outbound = airport.code) AS WithOutboundCity
        JOIN airport ON WithOutboundCity.inbound = airport.code
    WHERE DATE(s_dep) = DATE '2021-04-30' AND DATE(s_arv) = DATE '2021-04-30';

-- direct
CREATE VIEW Direct AS
    SELECT p.outbound AS outbound, p.inbound AS inbound, (
        SELECT count(*) FROM (
            SELECT id
            FROM FlightsOnSameDate
            WHERE outbound = p.outbound AND inbound = p.inbound
            ) PossibleRoutes
        ) AS direct
    FROM PossibleCityRoutes p;

-- one conn
CREATE VIEW OneConn AS
    SELECT p.outbound AS outbound, p.inbound AS inbound, (
        SELECT count(*)
        FROM (
            SELECT FirstLeg.id AS FirstLegID, SecondLeg.id AS SecondLegID
            FROM FlightsOnSameDate AS FirstLeg
                INNER JOIN FlightsOnSameDate AS SecondLeg
                    ON FirstLeg.airport_inbound = SecondLeg.airport_outbound
                        AND extract(
                            EPOCH FROM SecondLeg.s_dep - FirstLeg.s_arv
                            ) / 60 >= 30
            WHERE FirstLeg.outbound = p.outbound
              AND SecondLeg.inbound = p.inbound
            ) PossibleTransfers
        ) AS one_con
    FROM PossibleCityRoutes p;

-- two conn
CREATE VIEW TwoConn AS
    SELECT p.outbound AS outbound, p.inbound AS inbound, (
        SELECT count(*)
        FROM (
            SELECT FirstLeg.id AS FirstLegID,
                   SecondLeg.id AS SecondLegID,
                   ThirdLeg.id AS ThirdLegID
            FROM FlightsOnSameDate AS FirstLeg
                INNER JOIN FlightsOnSameDate AS SecondLeg
                    ON FirstLeg.airport_inbound = SecondLeg.airport_outbound
                        AND extract(
                            EPOCH FROM SecondLeg.s_dep - FirstLeg.s_arv
                            ) / 60 >= 30
                INNER JOIN FlightsOnSameDate AS ThirdLeg
                    ON SecondLeg.airport_inbound = ThirdLeg.airport_outbound
                        AND extract(
                            EPOCH FROM ThirdLeg.s_dep - SecondLeg.s_arv
                            ) / 60 >= 30
            WHERE FirstLeg.outbound = p.outbound
              AND ThirdLeg.inbound = p.inbound
            ) PossibleTransfers
        ) AS two_con
    FROM PossibleCityRoutes p;

-- earliest
CREATE VIEW Earliest AS
    SELECT p.outbound AS outbound, p.inbound AS inbound, (
        SELECT s_arv
        FROM (
            SELECT ThirdLeg.s_arv
            FROM FlightsOnSameDate AS FirstLeg
                INNER JOIN FlightsOnSameDate AS SecondLeg
                    ON FirstLeg.airport_inbound = SecondLeg.airport_outbound
                        AND extract(
                            EPOCH FROM SecondLeg.s_dep - FirstLeg.s_arv
                            ) / 60 >= 30
                INNER JOIN FlightsOnSameDate AS ThirdLeg
                    ON SecondLeg.airport_inbound = ThirdLeg.airport_outbound
                        AND extract(
                            EPOCH FROM ThirdLeg.s_dep - SecondLeg.s_arv
                            ) / 60 >= 30
            WHERE FirstLeg.outbound = p.outbound
              AND ThirdLeg.inbound = p.inbound
            ) PossibleRoutes
        UNION (
            SELECT SecondLeg.s_arv
            FROM FlightsOnSameDate AS FirstLeg
                INNER JOIN FlightsOnSameDate AS SecondLeg
                    ON FirstLeg.airport_inbound = SecondLeg.airport_outbound
                        AND extract(
                            EPOCH FROM SecondLeg.s_dep - FirstLeg.s_arv
                            ) / 60 >= 30
            WHERE FirstLeg.outbound = p.outbound
              AND SecondLeg.inbound = p.inbound
            )
        UNION (
            SELECT s_arv
            FROM FlightsOnSameDate
            WHERE outbound = p.outbound AND inbound = p.inbound
            )
        ORDER BY s_arv
        LIMIT 1
        ) AS earliest
    FROM PossibleCityRoutes p;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
SELECT *
FROM PossibleCityRoutes
    NATURAL JOIN Direct
    NATURAL JOIN OneConn
    NATURAL JOIN TwoConn
    NATURAL JOIN Earliest;
