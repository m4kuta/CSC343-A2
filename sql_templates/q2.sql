-- Q2. Refunds!

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    airline CHAR(2),
    name VARCHAR(50),
    year CHAR(4),
    seat_class seat_class,
    refund REAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
drop view if exists Flights cascade;
drop view if exists FlightBookings cascade;
drop view if exists FlightRefunds cascade;

-- Define views for your intermediate steps here:
create view Flights as
select 
    F1.id, F1.airline, F1.country as dep_country, F2.country as arv_country, 
    case 
        when F1.country = F2.country then true
        when F1.country != F2.country then false
    end as intl,
    F1.s_dep, F1.s_arv 
from
    (flight join airport on outbound = code) as F1
    join 
    (flight join airport on inbound = code) as F2
    on F1.id = F2.id;


create view FlightBookings as
select 
    Flights.id as flight_id, airline, name, 
    dep_country, arv_country, intl, 
    s_dep, departure.datetime as a_dep, s_arv, arrival.datetime as a_arv, 
    (departure.datetime - s_dep) as dep_delay, 
    (arrival.datetime - s_arv) as arv_delay,
    booking.id as booking_id, seat_class, price 
from 
    Flights
    join airline on (Flights.airline = airline.code)
    join departure on (Flights.id = departure.flight_id)
    join arrival on (Flights.id = arrival.flight_id)
    join booking on (Flights.id = booking.flight_id);


create view FlightRefunds as
select 
    *,
    case 
        when intl = false and  dep_delay < '10:00:00' then 0.35 * price
        when intl = false and dep_delay >= '10:00:00' then 0.50 * price
        when intl = true and dep_delay < '12:00:00' then 0.35 * price
        when intl = true and dep_delay >= '12:00:00' then 0.50 * price 
    end as refund
from 
    FlightBookings
where 
    ((intl = false and dep_delay > '05:00:00') or 
    (intl = true and dep_delay > '08:00:00')) 
    and (arv_delay > (dep_delay)/2); 


INSERT INTO q2
select 
    airline, name, extract(year from s_dep) as year, seat_class, 
    sum(refund) as refund
from 
    FlightRefunds
group by 
    airline, name, year, seat_class;