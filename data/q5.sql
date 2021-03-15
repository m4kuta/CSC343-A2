-- Q5. Flight Hopping

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
	destination CHAR(3),
	num_flights INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS day CASCADE;
DROP VIEW IF EXISTS n CASCADE;

CREATE VIEW day AS
SELECT day::date as day FROM q5_parameters;
-- can get the given date using: (SELECT day from day)

CREATE VIEW n AS
SELECT n FROM q5_parameters;
-- can get the given number of flights using: (SELECT n from n)

-- HINT: You can answer the question by writing one recursive query below, without any more views.
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5
with recursive Hop as (
	select 
		1 as n, id, outbound, inbound, s_dep, s_arv 
	from 
		flight
	where 
		s_dep >= (select day from day) and outbound = 'YYZ'
	
	union all

	select 
		n + 1 as n, flight.id, flight.outbound, flight.inbound, flight.s_dep, flight.s_arv
	from
		Hop cross join Flight
	where 
		n < (select n from n) and Hop.inbound = Flight.outbound and (Flight.s_dep - Hop.s_arv) <= '24:00:00' and (Flight.s_dep - Hop.s_arv) >= '00:00:00'
) 
select inbound as destination, n as num_flights
from Hop 
order by n, id;

-- create TEMPORARY view hop1 as
-- select 
-- 	1 as n, id, outbound, inbound, s_dep, s_arv 
-- from 
-- 	flight
-- where 
-- 	s_dep >= (select day from day) and outbound = 'YYZ'
-- ;


-- create TEMPORARY view hop2 as
-- select 
-- 	n + 1 as n, flight.id, flight.outbound, flight.inbound, flight.s_dep, flight.s_arv
-- from
-- 	hop1 cross join Flight
-- where 
-- 	n < (select n from n) and hop1.inbound = Flight.outbound and (Flight.s_dep - hop1.s_arv) <= '24:00:00' and (Flight.s_dep - hop1.s_arv) >= '00:00:00'
-- ;


-- create TEMPORARY view hop3 as 
-- select 
-- 	n + 1 as n, flight.id, flight.outbound, flight.inbound, flight.s_dep, flight.s_arv
-- from
-- 	hop2 cross join Flight
-- where 
-- 	n < (select n from n) and hop2.inbound = Flight.outbound and (Flight.s_dep - hop2.s_arv) <= '24:00:00' and (Flight.s_dep - hop2.s_arv) >= '00:00:00'
-- ;

-- select * from hop1 union all select * from hop2 union all select * from hop3; 