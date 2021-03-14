-- Q4. Plane Capacity Histogram

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
	airline CHAR(2),
	tail_number CHAR(5),
	very_low INT,
	low INT,
	fair INT,
	normal INT,
	high INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
drop view if exists PlaneCap cascade;
drop view if exists FlightsByPlane cascade;
drop view if exists PercentCapacity cascade;


-- Define views for your intermediate steps here:
create view PlaneCap as
select plane.airline, tail_number, (capacity_economy + capacity_business + capacity_first) as total_cap 
from plane
group by tail_number;


create view FlightsByPlane as
select plane, flight_num, count(*) as total_passengers
from flight join booking on flight.id = booking.flight_id
group by plane, flight_num;


create view PercentCapacity as
select airline, tail_number, flight_num, total_cap, total_passengers, total_passengers/total_cap::float as percent_cap
from PlaneCap join FlightsByPlane on PlaneCap.tail_number = FlightsByPlane.plane;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
select 
	airline, tail_number, 
	count(case when percent_cap < 0.2 then 1 end) as very_low, 
	count(case when 0.2 <= percent_cap and percent_cap < 0.4 then 1 end) as low, 
	count(case when 0.4 <= percent_cap and percent_cap < 0.6 then 1 end) as fair, 
	count(case when 0.6 <= percent_cap and percent_cap < 0.8 then 1 end) as normal, 
	count(case when 0.8 <= percent_cap then 1 end) as high
from PercentCapacity
group by airline, tail_number, flight_num;