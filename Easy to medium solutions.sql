--Apple Sales Project - 1M rows sales datasets
SELECT * FROM category;
SELECT * FROM products;
SELECT * FROM stores;
SELECT * FROM sales;
SELECT * FROM warranty;

--EDA
SELECT DISTINCT repair_status FROM warranty;
SELECT COUNT(*) FROM sales;

--Improving Query Performance

-- et - 182.ms
--pt - 0.16ms
--et - 5-15 ms
EXPLAIN ANALYZE
SELECT * FROM sales
WHERE product_id ='P-44'

CREATE INDEX sales_product_id ON sales(product_id);

-- et - 115.ms
--pt - 0.17ms
--et - 3.9 ms
EXPLAIN ANALYZE
SELECT * FROM sales
WHERE store_id ='ST-31'

CREATE INDEX sales_store_id ON sales(store_id);
CREATE INDEX sales_sale_date ON sales(sale_date);

--Business Problems
--Medium Problems

--1. Find the number of stores in each country.
SELECT 
	country,
	COUNT(store_id) as total_stores
FROM stores
GROUP BY 1
ORDER BY 2 DESC

-- Q.2 Calculate the total number of units sold by each store.

SELECT 
	s.store_id,
	st.store_name,
	SUM(s.quantity) as total_unit_sold
FROM sales as s
JOIN
stores as st
ON st.store_id = s.store_id
GROUP BY 1, 2
ORDER BY 3 DESC

-- Q.3 Identify how many sales occurred in December 2023.
SELECT 
	COUNT(sale_id) as total_sale 
FROM sales
WHERE TO_CHAR(sale_date, 'MM-YYYY') = '12-2023'

-- Q.4 Determine how many stores have never had a warranty claim filed.
SELECT COUNT(*) FROM stores
WHERE store_id NOT IN (
						SELECT 
							DISTINCT store_id
						FROM sales as s
						RIGHT JOIN warranty as w
						ON s.sale_id = w.sale_id
						);

-- Q.5 Calculate the percentage of warranty claims marked as "Warranty Void".
no claim that as wv/total claim * 100

SELECT 
	ROUND
		(COUNT(claim_id)/
						(SELECT COUNT(*) FROM warranty)::numeric 
		* 100, 
	2)as warranty_void_percentage
FROM warranty
WHERE repair_status = 'Warranty Void'

-- Q.6 Identify which store had the highest total units sold in the last year.

SELECT 
	s.store_id,
	st.store_name,
	SUM(s.quantity)
FROM sales as s
JOIN stores as st
ON s.store_id = st.store_id
WHERE sale_date >= (CURRENT_DATE - INTERVAL '1 year')
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1

-- Q.7 Count the number of unique products sold in the last year.

SELECT 
	COUNT(DISTINCT product_id)
FROM sales
WHERE sale_date >= (CURRENT_DATE - INTERVAL '1 year')

-- Q.8 Find the average price of products in each category.
SELECT 
	p.category_id,
	c.category_name,
	AVG(p.price) as avg_price
FROM products as p
JOIN 
category as c
ON p.category_id = c.category_id
GROUP BY 1, 2
ORDER BY 3 DESC

-- Q.9 How many warranty claims were filed in 2020?
SELECT 
	COUNT(*) as warranty_claim
FROM warranty
WHERE EXTRACT(YEAR FROM claim_date) = 2020

-- Q.10 For each store, identify the best-selling day based on highest quantity sold.

-- store_id, day_name, sum(qty)
--  window dense rank 


SELECT  * 
FROM
(
	SELECT 
		store_id,
		TO_CHAR(sale_date, 'Day') as day_name,
		SUM(quantity) as total_unit_sold,
		RANK() OVER(PARTITION BY store_id ORDER BY SUM(quantity) DESC) as rank
	FROM sales
	GROUP BY 1, 2
) as t1
WHERE rank = 1

