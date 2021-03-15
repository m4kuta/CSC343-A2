-- query 2
select 
    *,
    case
        when dep_country = arv_country then
            case 
                when dep_delay >= '05:00:00' and (arv_delay > (dep_delay)/2) then
                    case 
                        when dep_delay < '10:00:00' then 0.35 * price
                        when dep_delay >= '10:00:00' then 0.50 * price
                    end
                else 0
            end
        when dep_country != arv_country then
            case
                when dep_delay >= '08:00:00' and (arv_delay > (dep_delay)/2) then
                    case 
                        when dep_delay < '12:00:00' then 0.35 * price
                        when dep_delay >= '12:00:00' then 0.50 * price 
                    end
                else 0
            end
        else 0
    end as refund
from FlightBookingInfo; 


-- select 
--     F1.id, F1.airline, F1.country as dep_country, F2.country as arv_country, 
--     case 
--         when F1.country = F2.country then true
--         when F1.country != F2.country then false
--     end as intl,
--     F1.s_dep, F1.s_arv 
-- from
--     (flight join airport on outbound = code) as F1
--     join 
--     (flight join airport on inbound = code) as F2
--     on F1.id = F2.id;


-- select 
--     Flights.id as flight_id, airline, name, 
--     dep_country, arv_country, intl, 
--     s_dep, departure.datetime as a_dep, s_arv, arrival.datetime as a_arv, 
--     (departure.datetime - s_dep) as dep_delay, 
--     (arrival.datetime - s_arv) as arv_delay,
--     booking.id as booking_id, seat_class, price 
-- from 
--     Flights
--     join airline on (Flights.airline = airline.code)
--     join departure on (Flights.id = departure.flight_id)
--     join arrival on (Flights.id = arrival.flight_id)
--     join booking on (Flights.id = booking.flight_id);


-- query 4
-- drop view if exists PlaneCap cascade;
-- drop view if exists FlightsByPlane cascade;
-- drop view if exists PercentCapacity cascade;


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


-- select 
-- 	airline, tail_number, 
-- 	count(case when percent_cap < 0.2 then 1 end) as very_low, 
-- 	count(case when 0.2 <= percent_cap and percent_cap < 0.4 then 1 end) as low, 
-- 	count(case when 0.4 <= percent_cap and percent_cap < 0.6 then 1 end) as fair, 
-- 	count(case when 0.6 <= percent_cap and percent_cap < 0.8 then 1 end) as normal, 
-- 	count(case when 0.8 <= percent_cap then 1 end) as high
-- from PercentCapacity
-- group by airline, tail_number, flight_num;


-- query 5
-- Test queries

select * 
from Hop
order by n, id;


create TEMPORARY view hop1 as
select 
	1 as n, id, outbound, inbound, s_dep, s_arv 
from 
	flight
where 
	extract(year from s_dep) = extract(year from (select day from day)) 
	and extract(day from s_dep) = extract(day from (select day from day))
	and outbound = 'YYZ';


create TEMPORARY view hop2 as
select 
	n + 1 as n, flight.id, flight.outbound, flight.inbound, flight.s_dep, flight.s_arv
from
	hop1 cross join Flight
where 
	n < (select n from n) and hop1.inbound = Flight.outbound and (Flight.s_dep - hop1.s_arv) <= '24:00:00' and (Flight.s_dep - hop1.s_arv) >= '00:00:00';


create TEMPORARY view hop3 as 
select 
	n + 1 as n, flight.id, flight.outbound, flight.inbound, flight.s_dep, flight.s_arv
from
	hop2 cross join Flight
where 
	n < (select n from n) and hop2.inbound = Flight.outbound and (Flight.s_dep - hop2.s_arv) <= '24:00:00' and (Flight.s_dep - hop2.s_arv) >= '00:00:00';


select * from hop1 union all select * from hop2 union all select * from hop3;


-- bookSeat q1
select capacity_economy
from flight join plane on plane = tail_number 
where flight_num = 5;

select capacity_economy from flight join plane on plane = tail_number where flight_num = 5;


-- bookSeat q2
select COALESCE(
(select count(*) as booked
from booking where flight_id = 5 and seat_class = 'economy'
group by flight_id, seat_class 
order by flight_id, seat_class), 
0);

select COALESCE((select count(*) as booked from booking where flight_id = 4 and seat_class = 'economy' group by flight_id, seat_class), 0);

-- bookSeat q3
select COALESCE((select max(id) from booking), 0);

-- "select *, (capacity_economy + capacity_business + capacity_first) as total_capacity from plane";