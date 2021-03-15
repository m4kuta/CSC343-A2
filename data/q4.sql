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

-- drop view if exists PlaneCap cascade;
-- drop view if exists FlightsByPlane cascade;
-- drop view if exists PercentCapacity cascade;

drop view if exists PlaneFullFlight;
drop view if exists FlightFullBooking;
drop view if exists PlaneFullBooking;
drop view if exists PlaneFullDepart;
drop view if exists PlaneCapacity;

-- Define views for your intermediate steps here:

-- create view PlaneCap as
-- select plane.airline, tail_number, (capacity_economy + capacity_business + capacity_first) as total_cap 
-- from plane
-- group by tail_number;

-- create view FlightsByPlane as
-- select plane, flight.id as flight_id, count(*) as total_passengers
-- from 
-- 	flight 
-- 	right join booking on flight.id = booking.flight_id
-- 	right join departure on flight.id = departure.flight_id
-- group by plane, flight.id;
-- -- Need to include flights that have no bookings and planes that had no flights

-- create view PercentCapacity as
-- select airline, tail_number, flight_num, total_cap, total_passengers, total_passengers/total_cap::float as percent_cap
-- from PlaneCap join FlightsByPlane on PlaneCap.tail_number = FlightsByPlane.plane;


create view PlaneFullFlight as
select
	flight.id as flight_id, flight.airline, plane.tail_number, 
	(capacity_economy + capacity_business + capacity_first) as capacity
from
	plane full join flight on plane.tail_number = flight.plane;


create view FlightFullBooking as
select 
	flight.id as flight_id, flight.airline, flight.plane, booking.id as booking_id
from 
	flight full join booking on flight.id = booking.flight_id;


create view PlaneFullBooking as
select 
	PF.flight_id, Pf.airline, PF.tail_number, PF.capacity, FB.booking_id
from 
	PlaneFullFlight PF full join FlightFullBooking as FB on PF.flight_id = FB.flight_id;


create view PlaneFullDepart as
select 
	PB.flight_id, PB.airline, PB.tail_number, PB.capacity, departure.datetime, PB.booking_id
from 
	PlaneFullBooking PB full join departure on PB.flight_id = departure.flight_id
order by 
	PB.flight_id;


create view PlaneCapacity as
select 
	flight_id, airline, tail_number, 
	case 
		when datetime is null then null
		else count(booking_id)/capacity::float
	end as percent_cap
from PlaneFullDepart
group by 
	flight_id, airline, tail_number, capacity, datetime
order by 
	flight_id;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
-- select 
-- 	airline, tail_number, 
-- 	count(case when percent_cap < 0.2 then 1 end) as very_low, 
-- 	count(case when 0.2 <= percent_cap and percent_cap < 0.4 then 1 end) as low, 
-- 	count(case when 0.4 <= percent_cap and percent_cap < 0.6 then 1 end) as fair, 
-- 	count(case when 0.6 <= percent_cap and percent_cap < 0.8 then 1 end) as normal, 
-- 	count(case when 0.8 <= percent_cap then 1 end) as high
-- from PercentCapacity
-- group by airline, tail_number, flight_num;

select 
	airline, tail_number, 
	count(case when 0.0 <= percent_cap and percent_cap < 0.2 then 1 end) as very_low, 
	count(case when 0.2 <= percent_cap and percent_cap < 0.4 then 1 end) as low, 
	count(case when 0.4 <= percent_cap and percent_cap < 0.6 then 1 end) as fair, 
	count(case when 0.6 <= percent_cap and percent_cap < 0.8 then 1 end) as normal, 
	count(case when 0.8 <= percent_cap then 1 end) as high
from 
	PlaneCapacity
group by 
	airline, tail_number;