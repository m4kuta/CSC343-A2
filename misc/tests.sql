-- query 1
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

Your query that answers the question goes below the "insert into" line:

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