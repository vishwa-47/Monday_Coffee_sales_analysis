-----monday coffee project


-- Monday Coffee SCHEMAS

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;

-- Import Rules
-- 1st import to city
-- 2nd import to products
-- 3rd import to customers
-- 4th import to sales


CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);


CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);


CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);




-- Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?



select * from city
select * from products
select * from  customers
select * from sales


select city_name,
	round((	population * 0.25)/1000000,2)as coffee_consumers,
	city_rank
	from city
order by 2 desc




-- Total Revenue from Coffee Sales

-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?



select city_name,
sum(total)
from sales as s
join customers as c
on s.customer_id =c.customer_Id
join city as ci
on c.city_id = ci.city_id
where extract(year from sale_date) = 2023
and extract(quarter from sale_date)=3
group by city_name
order by sum(total) desc





-- Sales Count for Each Product
-- How many units of each coffee product have been sold?


select product_name,count(sales.total) from products as p
join sales 
on sales.product_id = p.product_id
group by 1
order by 2 desc

	

select * from sales





-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?






select city_name,
	sum(total),
	count(distinct customer_name),
	round(sum(total)::numeric/count(distinct customer_name)::numeric,2) as average_sales
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1
order by 2 desc




-- City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.


select count(distinct cu.customer_name) as unique_customers,city_name,
round((c.population*0.25)/1000000,2)
from city as c
join customers as cu
on c.city_id = cu.city_id
group by 2,3
order by 3 desc









-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?



with ranking as
	(
select p.product_name,
	count(s.sale_id),
	ci.city_name,
	dense_rank()over(partition by ci.city_name order by count(s.sale_id)desc) as rank 
	from products as p
join sales as s
on p.product_id  = s.product_id
join customers as c
on s.customer_id = c.customer_id
join city as ci
on c.city_id = ci.city_id
group by 3,1
-- order by count(s.sale_id) desc
)

select * from ranking where rank<=3 

-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?



select ci.city_name,
	count(distinct c.customer_id)
	 from customers as c
join city as ci
on c.city_id = ci.city_id
join sales as s
on s.customer_id = ci.city_id
where 
	s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by 1

select distinct * from city

-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

with t1 as(
	

select ci.city_name,
	sum(s.total) as total_revenue,
	round(sum(total)::numeric/count(distinct c.customer_id)::numeric)::numeric as average_sale
from sales as s
join customers as c
on c.customer_id = s.customer_id
join city as ci
	on ci.city_id = c.city_id
group by ci.city_name
),

t2 as(
select ci.city_name,round(ci.estimated_rent/count(distinct c.customer_id)) from customers as c 
join city as ci
on c.city_id = ci.city_id
group by ci.city_name,ci.estimated_rent
)


select t1.city_name,
	total_revenue,
	average_sale,
	round as average_rent
	from t1 
join t2
on t1.city_name = t2.city_name
order by 2 desc

-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).


with monthly_sales as
	(
select ci.city_name,
	extract(month from s.sale_date) as month,
	extract(year from s.sale_date) as year,
	sum(total) as total_sale
	from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1,2,3
order by 1,3,2
),

	growth_ratio
	as(
	
	
select city_name,
	month,
	year,
	total_sale  as current_month_sale,
	lag(total_sale,1) over(partition by city_name order by year,month) as last_month_sale 
from monthly_sales
)


select city_name,
	month,
	year,
	current_month_sale,
	last_month_sale,
	round(
	(current_month_sale - last_month_sale)::numeric/last_month_sale::numeric * 100
	,2)
from growth_ratio
where last_month_sale is not null



-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



select
	ci.city_name,
	sum(price) as Highest_sales,
	ci.estimated_rent as total_rent,
	sum(price) as total_sales,
	count(distinct c.customer_id) as total_customers,
	round((population*0.25)/1000000,2) as estimated_coffee_consumers,
	round((population/estimated_rent::numeric),2) as average_rent
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_Id = c.city_id
join products as p
on p.product_id = s.product_id
group by 1,3,6,7
order by 2 desc
limit 3


select* from sales
select * from products

















WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC















