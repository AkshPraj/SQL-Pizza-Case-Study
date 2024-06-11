
create database pizza_proj;
use pizza_proj;

-- let's  import the csv files
-- Now understand each table (all columns)
select * from order_details;  -- order_details_id	order_id	pizza_id	quantity

select * from pizzas; -- pizza_id, pizza_type_id, size, price

select * from orders;  -- order_id, date, time

select * from pizza_types;  -- pizza_type_id, name, category, ingredients

-- Retrieve the total number of orders placed.
select count(distinct order_id) from orders;

-- Calculate the total revenue generated from pizza sales.

select round(sum(p.price * o.quantity),2)  as total_revenue
from pizzas p join order_details o
on p.pizza_id = o.pizza_id;

-- Identify the highest-priced pizza.

select pt.name, p.price as price
from pizza_types pt join pizzas p
on pt.pizza_type_id = p.pizza_type_id
order by p.price desc
limit 1; 

-- Alternative (using window function) - without using LIMIT function

with cte as (
select pt.name as pizza_name, p.price as price,
rank() over (order by price desc) as rnk
from pizzas p
join pizza_types pt on pt.pizza_type_id = p.pizza_type_id)

select pizza_name, price from cte where rnk = 1;

-- Identify the most common pizza size ordered.

select p.size , count(distinct od.order_id) as No_of_orders,
		sum(od.quantity)
from pizzas p join order_details od
on p.pizza_id = od.pizza_id
group by p.size
order by count(distinct od.order_id) desc;


-- List the top 5 most ordered pizza types along with their quantities.

select pt.name, 
		sum(quantity) as No_of_quantity
from  pizza_types pt join pizzas p
on pt.pizza_type_id = p.pizza_type_id
join order_details od
on od.pizza_id = p.pizza_id
group by pt.name
order by count(order_id) desc
limit 5;


-- Intermediate:
-- Find the total quantity of each pizza category ordered 
-- (this will help us to understand the category which customers prefer the most).

select pt.category, sum(od.quantity) as Total_Quantity_Ordered
from  pizza_types pt join pizzas p
on pt.pizza_type_id = p.pizza_type_id
join order_details od
on od.pizza_id = p.pizza_id
group by pt.category;

-- Determine the distribution of orders by hour of the day(at which time the orders are maximum 
-- (for inventory management and resource allocation).

select hour(time) as hour_of_the_day, 
	   count(distinct order_id) as no_of_orders
from orders
group by hour(time)
order by no_of_orders desc;

-- Find the category-wise distribution of pizzas (to understand customer behaviour).

select category, count(distinct pizza_type_id) as no_of_pizza
from pizza_types
group by category
order by no_of_pizza desc;

-- Group the orders by date and calculate the average number of pizzas ordered per day.

with perday as (
select o.date, sum(od.quantity) as total_order_per_day
from orders o join order_details od
on o.order_id = od.order_id
group by o.date)

select avg(total_order_per_day) as avg_no_of_pizza_per_day
from perday;

-- alternate using subquery
select avg(total_order_per_day) as avg_no_of_pizza_per_day
from (
select o.date, sum(od.quantity) as total_order_per_day
from orders o join order_details od
on o.order_id = od.order_id
group by o.date) as pizza_ordered ;


-- Determine the top 3 most ordered pizza types based on revenue (let's see the revenue wise  -- pizza orders to understand from sales perspective which pizza is the best selling)

select pt.name, sum(p.price * od.quantity) as total_revenue
from order_details od join pizzas p
on p.pizza_id = od.pizza_id
join pizza_types pt
on pt.pizza_type_id = p.pizza_type_id
group by pt.name
order by total_revenue desc
limit 3;


-- Advanced:
-- Calculate the percentage contribution of each pizza type to total revenue (to understand % -- of contribution of each pizza in the total revenue).

select pt.category, 
	concat(round((sum(od.quantity*p.price) /
		(select sum(od.quantity*p.price) 
		from order_details od
		join pizzas p on p.pizza_id = od.pizza_id 
		))*100 ,2), '%') as Revenue_contribution 
from order_details od
join pizzas p on p.pizza_id = od.pizza_id
join pizza_types pt on pt.pizza_type_id = p.pizza_type_id
group by pt.category;

-- alternate using subquery

select*, concat(round(total_revenue/(select sum(p.price * od.quantity) 
		from order_details od join pizzas p
        on od.pizza_id = p.pizza_id) * 100,2), "%") as revenue_contribution
from (
select pt.category, round(sum(p.price * od.quantity)) as total_revenue
from order_details od join pizzas p
on od.pizza_id = p.pizza_id
join pizza_types pt
on pt.pizza_type_id = p.pizza_type_id
group by pt.category
order by total_revenue desc) rev_perc;

-- Analyze the cumulative revenue generated over time.

with cte as(
select o.date as date, round(sum(p.price * od.quantity), 2) as revenue 
from order_details od join pizzas p
on od.pizza_id = p.pizza_id
join orders o
on o.order_id = od.order_id
group by o.date)

select date, revenue, 
	round(sum(revenue) over(order by date) ,2) as cumulative_sum
from cte;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category (In -- each category which pizza is the most selling)

with cte as (
select pt.category, pt.name, round(sum(p.price * od.quantity), 2) as revenue 
from order_details od join pizzas p
on od.pizza_id = p.pizza_id
join pizza_types pt
on p.pizza_type_id = pt.pizza_type_id
group by category, name)

, cte1 as (
select category, name, revenue,
rank() over (partition by category order by revenue desc) as rnk
from cte
)

select category, name, revenue
from cte1
where rnk in (1, 2, 3)
order by category, name, revenue;