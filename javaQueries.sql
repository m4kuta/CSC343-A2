-- bookSeat 1
select capacity_economy
from flight join plane on plane = tail_number 
where flight_num = 5;

select capacity_economy from flight join plane on plane = tail_number where flight_num = 5;


-- bookSeat 2
select COALESCE(
(select count(*) as booked
from booking where flight_id = 5 and seat_class = 'economy'
group by flight_id, seat_class 
order by flight_id, seat_class), 
0);

select COALESCE((select count(*) as booked from booking where flight_id = 5 and seat_class = 'economy' group by flight_id, seat_class), 0);

-- "select *, (capacity_economy + capacity_business + capacity_first) as total_capacity from plane";