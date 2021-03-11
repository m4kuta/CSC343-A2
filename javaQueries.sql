select capacity_economy
from flight join plane on plane = tail_number 
where flight_num = 5;

select capacity_economy from flight join plane on plane = tail_number where flight_num = 5;

select count(*) as booked
from booking where flight_id = 5 and seat_class = 'economy'
group by flight_id, seat_class 
order by flight_id, seat_class;

select count(*) as booked from booking where flight_id = 5 and seat_class = 'economy' group by flight_id, seat_class order by flight_id, seat_class;






-- "select *, (capacity_economy + capacity_business + capacity_first) as total_capacity from plane";