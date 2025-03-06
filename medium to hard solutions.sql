-- Medium to Hard Questions
-- Q.11 Identify the least selling product in each country for each year based on total units sold.

WITH product_rank
AS
(
SELECT 
	st.country,
	p.product_name,
	SUM(s.quantity) as total_qty_sold,
	RANK() OVER(PARTITION BY st.country ORDER BY SUM(s.quantity)) as rank
FROM sales as s
JOIN 
stores as st
ON s.store_id = st.store_id
JOIN
products as p
ON s.product_id = p.product_id
GROUP BY 1, 2
)
SELECT 
* 
FROM product_rank
WHERE rank = 1

-- Q.12 Calculate how many warranty claims were filed within 180 days of a product sale.

SELECT 
	COUNT(*)
FROM warranty as w
LEFT JOIN 
sales as s
ON s.sale_id = w.sale_id
WHERE 
	w.claim_date - sale_date <= 180

--Q.13  Determine how many warranty claims were filed for products launched in the last two years.
-- each prod 
--  no claim
--  no sale
-- each must be launcnhed in last 2 year

SELECT 
	p.product_name,
	COUNT(w.claim_id) as no_claim,
	COUNT(s.sale_id)
FROM warranty as w
RIGHT JOIN
sales as s 
ON s.sale_id = w.sale_id
JOIN products as p
ON p.product_id = s.product_id
WHERE p.launch_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY 1
HAVING COUNT(w.claim_id) > 0

-- Q.14 List the months in the last three years where sales exceeded 5,000 units in the USA.

SELECT 
	TO_CHAR(sale_date, 'MM-YYYY') as month,
	SUM(s.quantity) as total_unit_sold
FROM sales as s
JOIN 
stores as st
ON s.store_id = st.store_id
WHERE 
	st.country = 'USA'
	AND
	s.sale_date >= CURRENT_DATE - INTERVAL '3 year'
GROUP BY 1
HAVING SUM(s.quantity) > 5000

-- Q.15 Identify the product category with the most warranty claims filed in the last two years.

SELECT 
	c.category_name,
	COUNT(w.claim_id) as total_claims
FROM warranty as w
LEFT JOIN
sales as s
ON w.sale_id = s.sale_id
JOIN products as p
ON p.product_id = s.product_id
JOIN 
category as c
ON c.category_id = p.category_id
WHERE 
	w.claim_date >= CURRENT_DATE - INTERVAL '2 year'
GROUP BY 1