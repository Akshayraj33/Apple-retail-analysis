-- Advanced Problems
-- Q.16 Determine the percentage chance of receiving warranty claims after each purchase for each country!

SELECT 
	country,
	total_unit_sold,
	total_claim,
	COALESCE(total_claim::numeric/total_unit_sold::numeric * 100, 0)
	as risk
FROM
(SELECT 
	st.country,
	SUM(s.quantity) as total_unit_sold,
	COUNT(w.claim_id) as total_claim
FROM sales as s
JOIN stores as st
ON s.store_id = st.store_id
LEFT JOIN 
warranty as w
ON w.sale_id = s.sale_id
GROUP BY 1) t1
ORDER BY 4 DESC

-- Q.17 Analyze the year-by-year growth ratio for each store.

-- each store and their yearly sale 
WITH yearly_sales
AS
(
	SELECT 
		s.store_id,
		st.store_name,
		EXTRACT(YEAR FROM sale_date) as year,
		SUM(s.quantity * p.price) as total_sale
	FROM sales as s
	JOIN
	products as p
	ON s.product_id = p.product_id
	JOIN stores as st
	ON st.store_id = s.store_id
	GROUP BY 1, 2, 3
	ORDER BY 2, 3 
),
growth_ratio
AS
(
SELECT 
	store_name,
	year,
	LAG(total_sale, 1) OVER(PARTITION BY store_name ORDER BY year) as last_year_sale,
	total_sale as current_year_sale
FROM yearly_sales
)

SELECT 
	store_name,
	year,
	last_year_sale,
	current_year_sale,
	ROUND(
			(current_year_sale - last_year_sale)::numeric/
							last_year_sale::numeric * 100
	,3) as growth_ratio
FROM growth_ratio
WHERE 
	last_year_sale IS NOT NULL
	AND 
	YEAR <> EXTRACT(YEAR FROM CURRENT_DATE)

-- Q.18 Calculate the correlation between product price and warranty claims for 
-- products sold in the last five years, segmented by price range.

SELECT 
	
	CASE
		WHEN p.price < 500 THEN 'Less Expenses Product'
		WHEN p.price BETWEEN 500 AND 1000 THEN 'Mid Range Product'
		ELSE 'Expensive Product'
	END as price_segment,
	COUNT(w.claim_id) as total_Claim
FROM warranty as w
LEFT JOIN
sales as s
ON w.sale_id = s.sale_id
JOIN 
products as p
ON p.product_id = s.product_id
WHERE claim_date >= CURRENT_DATE - INTERVAL '5 year'
GROUP BY 1


-- Q.19 Identify the store with the highest percentage of "Paid Repaired" claims relative to total claims filed

WITH paid_repair
AS
(SELECT 
	s.store_id,
	COUNT(w.claim_id) as paid_repaired
FROM sales as s
RIGHT JOIN warranty as w
ON w.sale_id = s.sale_id
WHERE w.repair_status = 'Paid Repaired'
GROUP BY 1
),

total_repaired
AS
(SELECT 
	s.store_id,
	COUNT(w.claim_id) as total_repaired
FROM sales as s
RIGHT JOIN warranty as w
ON w.sale_id = s.sale_id
GROUP BY 1)

SELECT 
	tr.store_id,
	st.store_name,
	pr.paid_repaired,
	tr.total_repaired,
	ROUND(pr.paid_repaired::numeric/
			tr.total_repaired::numeric * 100
		,2) as percentage_paid_repaired
FROM paid_repair as pr
JOIN 
total_repaired tr
ON pr.store_id = tr.store_id
JOIN stores as st
ON tr.store_id = st.store_id


-- Q.20 Write a query to calculate the monthly running total of sales for each store
-- over the past four years and compare trends during this period.

WITH monthly_sales
AS
(SELECT 
	store_id,
	EXTRACT(YEAR FROM sale_date) as year,
	EXTRACT(MONTH FROM sale_date) as month,
	SUM(p.price * s.quantity) as total_revenue
FROM sales as s
JOIN 
products as p
ON s.product_id = p.product_id
GROUP BY 1, 2, 3
ORDER BY 1, 2,3
)
SELECT 
	store_id,
	month,
	year,
	total_revenue,
	SUM(total_revenue) OVER(PARTITION BY store_id ORDER BY year, month) as running_total
FROM monthly_sales


--Q.21 Analyze product sales trends over time, segmented into key periods: from launch to 6 months, 6-12 months, 12-18 months, and beyond 18 months.

SELECT 
	p.product_name,
	CASE 
		WHEN s.sale_date BETWEEN p.launch_date AND p.launch_date + INTERVAL '6 month' THEN '0-6 month'
		WHEN s.sale_date BETWEEN  p.launch_date + INTERVAL '6 month'  AND p.launch_date + INTERVAL '12 month' THEN '6-12' 
		WHEN s.sale_date BETWEEN  p.launch_date + INTERVAL '12 month'  AND p.launch_date + INTERVAL '18 month' THEN '6-12'
		ELSE '18+'
	END as plc,
	SUM(s.quantity) as total_qty_sale
	
FROM sales as s
JOIN products as p
ON s.product_id = p.product_id
GROUP BY 1, 2
ORDER BY 1, 3 DESC 
