---create database 
create database project;

---use database
use project;

---reading data

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

---Roll Metrics

---how many rolls were ordered?

select count(*) as No_of_rolls_ordered from customer_orders;

---how many unique customer orders were made?

select COUNT(distinct customer_id) as No_unique_customer from customer_orders;

---how many successful orders were delivered by each driver?

----
create view clean_driver_order
as
select *,
case 
when cancellation  in ('cancellation','Customer Cancellation') then 'c'
else 'nc'
end as cancel_order_detail
from driver_order;
----
select driver_id,COUNT(driver_id) as No_delivered_order from clean_driver_order
where cancel_order_detail  in ('nc')
group by driver_id;

---how many	of each type of roll was delivered?

with cte as(
select * from customer_orders
where order_id in (
select order_id from clean_driver_order
where cancel_order_detail  in ('nc'))
)
select roll_id,count(roll_id) as No_roll_delivered  from cte
group by roll_id;

---how many veg and non veg rolls were ordered by each customer?

select customer_id,c.roll_id,roll_name,COUNT(c.roll_id) as No_rolls from 
customer_orders c join rolls r
on c.roll_id=r.roll_id
group by customer_id,c.roll_id,roll_name
order by No_rolls desc;

---what was the maximum number of rolls	delivered in a single order?

with cte as(
select * from customer_orders
where order_id in (
select order_id from clean_driver_order
where cancel_order_detail  in ('nc'))
),
cte1 as(
select order_id,COUNT(*) as cnt from cte
group by order_id
)
select top 1 *,rank() over(order by cnt desc) as rnk from cte1;

---for each customer, how many delivered rolls had at least 1 change and how many had no changes?

with temp_customer_order as (
select order_id,customer_id,roll_id,
case
when not_include_items is null or not_include_items=' ' then '0' 
when not_include_items is not null then not_include_items
end as new_not_include_items ,
case 
when extra_items_included is null or extra_items_included='NaN' or extra_items_included=' ' then '0'
else extra_items_included
end as new_extra_items_included,
order_date
from customer_orders
),

temp_driver_order as(
select order_id,driver_id,pickup_time,distance,duration,
case
when cancellation in ('cancellation','Customer Cancellation') then '0' 
else '1'
end as new_cancellation
from driver_order
),
cte as (
select * from temp_customer_order 
where order_id in 
(select order_id from temp_driver_order
where new_cancellation='1')
),

cte1 as(
select *,
case 
when new_extra_items_included='0' and new_not_include_items='0' then 'No change' 
else 'change'
end as changes_in_order
from cte)

select customer_id,changes_in_order as 'at least 1_change' ,count(*) as cnt from cte1
group by customer_id,changes_in_order;

---how many rolls were delivered that had both exclusions and extras?

with temp_customer_order as (
select order_id,customer_id,roll_id,
case
when not_include_items is null or not_include_items=' ' then '0' 
when not_include_items is not null then not_include_items
end as new_not_include_items ,
case 
when extra_items_included is null or extra_items_included='NaN' or extra_items_included=' ' then '0'
else extra_items_included
end as new_extra_items_included,
order_date
from customer_orders
),

temp_driver_order as(
select order_id,driver_id,pickup_time,distance,duration,
case
when cancellation in ('cancellation','Customer Cancellation') then '0' 
else '1'
end as new_cancellation
from driver_order
),
cte as (
select * from temp_customer_order 
where order_id in 
(select order_id from temp_driver_order
where new_cancellation='1')
),

cte1 as(
select *,
case 
when new_extra_items_included!='0' and new_not_include_items!='0' then 'both inc exc' 
else 'either 1 inc or exc'
end as changes_in_order
from cte)

select changes_in_order  ,count(*) as cnt from cte1
group by changes_in_order;

---what was the total number of rolls ordereed for each hour of the day ?

select CONCAT(hr,'-',hr1) as Hour_bucket,count(*) as cnt from 
(select *,datepart(hour,order_date) as hr,datepart(hour,order_date)+1  as hr1 from customer_orders) as c 
group by CONCAT(hr,'-',hr1);

---what was the number of orders for each day of the week?

select day, count(*) as cnt from
(select *,datename(dw,order_date) as 'day'  from customer_orders) as c
group by day;

--- Driver and customer experience 

---what was the average time in minutes it took for each driver at the faasos HQ to pickup the order?

with cte as (
select c.order_id AS order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date,driver_id,pickup_time,distance,duration,cancellation,DATEDIFF(MINUTE,order_date,pickup_time) as diff_min  from 
customer_orders c join driver_order d
on c.order_id=d.order_id
where pickup_time is not null
),
cte1 as(
select *,ROW_NUMBER() over(partition by order_id order by diff_min) as rnk from cte
)
select driver_id,avg(diff_min) as avg_diff_min from cte1
where rnk=1
group by driver_id;


---Is there any relationship between the number of rolls and how long the order takes to prepare?

with cte as (
select c.order_id AS order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date,driver_id,pickup_time,distance,duration,cancellation,DATEDIFF(MINUTE,order_date,pickup_time) as diff_min  from 
customer_orders c join driver_order d
on c.order_id=d.order_id
where pickup_time is not null
)
select order_id,COUNT(roll_id) as No_of_roll,AVG(diff_min) as Time_to_prepare from cte
group by order_id

---Using scatter chart, i found that linear relationship between the no of rolls and time to prepare food 

---What was the average distance travelled for each customer?

		---clean data
		create view clean_driver_orders

		as

		select order_id,driver_id,pickup_time,Total_Distance,Total_duration,cancel_order_detail from
		(select *,
		case 
		when cancellation  in ('cancellation','Customer Cancellation') then 'c'
		else 'nc'
		end as cancel_order_detail,
		CONVERT(decimal(4,2),TRIM(REPLACE(lower(distance),'km',''))) as Total_Distance,
		CONVERT(decimal(4,2), TRIM( REPLACE( LOWER( REPLACE( lower(REPLACE(lower(duration),'minutes','')) , 'mins' ,'')) , 'minute' , ''))) as Total_duration
		from driver_order) as c;



---
with cte as (
select c.order_id AS order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date,driver_id,pickup_time,Total_Distance,Total_duration,cancel_order_detail,DATEDIFF(MINUTE,order_date,pickup_time) as diff_min  from 
customer_orders c join clean_driver_orders d
on c.order_id=d.order_id
where pickup_time is not null
),

cte1 as(
select *,ROW_NUMBER() over(partition by order_id order by diff_min) as rnk from cte
)

select customer_id,avg(Total_Distance) as Avg_distance from cte1
where rnk=1
group by customer_id;


---What was the	difference between the longest and shortest delivery times for all orders?

select MAX(Total_duration)-MIN(Total_duration) as diff from clean_driver_orders


---What was the average speed for each driver for each delivery and do you notice any trend for these values?

select cl.order_id,driver_id,cnt,(Total_Distance/Total_duration) as Speed from
clean_driver_orders as cl join (select order_id,count(roll_id) as cnt from customer_orders group by order_id) as c
on cl.order_id=c.order_id
where cancel_order_detail='nc'


---What is the successful delivery percentage for each driver?

with cte as(
select *,
case 
when cancel_order_detail='nc' then 1
else 0
end as cancel_percentage
from clean_driver_orders
),

cte1 as(
select driver_id,SUM(cancel_percentage) as sum_total, COUNT(*) as cnt from cte
group by driver_id
)
select driver_id,convert(float,(sum_total))*100/convert(float,(cnt)) as successful_delivery_percentage from cte1