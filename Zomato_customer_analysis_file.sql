#reading datasets
use zomato;

select * from golden_users;
select * from users;
select * from products;
select * from sales;

#solve the different problem 

#what is the total amount each customer spent on zomato?
select s.userid , sum(price) as Total_amount from 
sales s join products p
on s.product_id=p.product_id
group by s.userid;

#how many days has each customer visited zomato?
select userid,COUNT(distinct orderdate) as No_days from sales
group by userid;

#what was the firt product purchsed by each customer?
with cte as(
select userid,s.product_id, DENSE_RANK() over(partition by userid order by orderdate) as rnk from 
sales s join products p
on s.product_id=p.product_id 
)
select * from cte
where rnk=1;

#what is the most purchased item on the menu and how many times was it purchsed by all customers?
select s.product_id,count(s.product_id) as cnt from
sales s join products p 
on s.product_id=p.product_id
group by s.product_id
order by cnt desc LIMIT 1;

select userid,count(userid) as No_of_order from sales
where product_id=2
group by userid
order by No_of_order desc;

#which item was the popular for each customer?
with cte as(
select userid, product_id, count(product_id) as cnt, DENSE_RANK() over
(partition by userid order by count(product_id) desc) as rnk from sales
group by userid, product_id
)
select userid, product_id from cte
where rnk=1;

#which item was purchsed first by the customer after they became a member?
with cte as(
select s.*,gold_users_signupdate from 
sales s join golden_users g
on s.userid=g.userid and orderdate>=gold_users_signupdate
),
cte1 as(
select *,DENSE_RANK() over(partition by userid order by orderdate) as rnk from cte
)
select * from cte1
where rnk=1;

#which item was purchsed just before the customer became a member?
with cte as(
select s.*,gold_users_signupdate from 
sales s join golden_users g
on s.userid=g.userid and orderdate<=gold_users_signupdate
),
cte1 as(
select *,DENSE_RANK() over(partition by userid order by orderdate desc) as rnk from cte
)
select * from cte1
where rnk=1;

#what is the orders and amount spent for each member before they became a member?
with cte as(
select s.*,gold_users_signupdate,product_name,price from 
sales s join golden_users g
on s.userid=g.userid and orderdate<=gold_users_signupdate
join products p
on p.product_id=s.product_id
)
select userid,count(userid) as No_of_orders,sum(price) as Total_amount from cte
group by userid;

#if buying each product generates points for eg. 5rs=2 zomato point and each product has different purchasing points
#for eg. for p1 5rs=1, p2 10rs=5, p3=5rs=1 zomato point
#calculate points collected by each customers and find out the cashback
#product most points have been given till now

#problem 1
	with cte as(
	select s.*,price from 
	sales s join products p
	on s.product_id=p.product_id
	),
	cte1 as(
	select *,
	case 
	when product_id=1 then 5
	when product_id=2 then 2
	when product_id=3 then 5
	end as point
	from cte
	),
	cte2 as(
	select *,(price/point) as total_points from cte1
	),
	cte3 as(
	select userid,sum(total_points) as Total_points_earn  from cte2
	group by userid
	)
	select *,(Total_points_earn/2.5) as Total_cashback from cte3
	order by Total_points_earn desc;

#problem 2

	with cte as(
	select s.*,price from 
	sales s join products p
	on s.product_id=p.product_id
	),
	cte1 as(
	select *,
	case 
	when product_id=1 then 5
	when product_id=2 then 2
	when product_id=3 then 5
	end as point
	from cte
	),
	cte2 as(
	select *,(price/point) as total_points from cte1
	),
	cte3 as(
	select product_id,sum(total_points) as Total_points_earn  from cte2
	group by product_id
	)
	select * from cte3
	order by Total_points_earn desc limit 1;

#In the first one year after a customer joins the gold program irrespective of what the customer 
#has purchased they earn 5 zomato points for every 10 rs spent who earned more 1 or 3 and what was 
#their points earnings	in their first year?

with cte as(
select s.*, price, gold_users_signupdate from 
sales s join products p
on s.product_id=p.product_id 
join golden_users g
on g.userid=s.userid and orderdate>=gold_users_signupdate and orderdate<=DATE_ADD(gold_users_signupdate, INTERVAL 1 year)
)
select *, (price*0.5) as total_points from cte;

#rank all the transaction of the customers
select *,rank() over(partition by userid order by orderdate desc) as rnk from sales;

#rank all the transactions for each member whenever they are a zomato gold member for every non gold member 
#transaction mark as na
WITH cte AS (
SELECT s.*, g.gold_users_signupdate 
FROM sales s 
LEFT JOIN golden_users g ON s.userid=g.userid AND orderdate>=gold_users_signupdate
),
cte1 AS (
SELECT *, RANK() OVER(PARTITION BY userid ORDER BY orderdate DESC) AS rnk FROM cte
),
cte2 AS (
SELECT userid, product_id, orderdate, gold_users_signupdate,
CASE
WHEN gold_users_signupdate IS NULL THEN 'na' ELSE CONVERT(rnk, CHAR) END AS ranking
FROM cte1
)
SELECT * FROM cte2;