-- OVERVIEW

--- KPI
SELECT 
	CAST(SUM(sales) AS money) AS total_sales,
	CAST(SUM(profit) AS money) AS total_profit, 
	ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_ratio,
	CAST(SUM(profit) / COUNT(DISTINCT order_id) AS money) AS profit_per_order,
	CAST(SUM(sales) / COUNT(DISTINCT customer_id) AS money) AS sales_per_customer,
	ROUND(SUM(discount * sales) / SUM(sales) *100, 0) AS avg_discount
FROM dw.orders;


--- Monthly Sales by Segment
SELECT 
	TO_CHAR(DATE_TRUNC('month', order_date), 'YYYY-MM') AS date, 
	segment, 
	CAST(SUM(sales) AS money) AS monthly_sales
FROM dw.orders
WHERE DATE_TRUNC('year', order_date) = '2016-01-01'
GROUP BY DATE_TRUNC('month', order_date), segment
ORDER BY date, segment;


--- Monthly Sales by Product Category
SELECT 
	TO_CHAR(DATE_TRUNC('month', order_date), 'YYYY-MM') AS date, 
	category, 
	CAST(SUM(sales) AS money) AS monthly_sales
FROM dw.orders
WHERE DATE_TRUNC('year', order_date) = '2016-01-01'
GROUP BY DATE_TRUNC('month', order_date), category
ORDER BY date, category;



-- PRODUCT DASHBOARD

--- Sales by Product Category over time
SELECT category, subcategory, CAST(SUM(sales) AS money) AS total_sales
FROM dw.orders
GROUP BY category, subcategory
ORDER BY category, total_sales DESC;



-- CUSTOMER ANALYSIS

--- Top 5 customers by sales in each segment
WITH customer_rank AS (
	SELECT segment, customer_name, sales, RANK() OVER(PARTITION BY (segment) ORDER BY (sales) DESC) AS sales_rank
	FROM (
		SELECT segment, customer_name, CAST(SUM(sales) AS money) AS sales
		FROM dw.orders
		GROUP BY segment, customer_name
	) AS s
)
SELECT segment, customer_name, sales
FROM customer_rank
WHERE sales_rank <= 5;


--- Sales per Region
SELECT region, CAST(SUM(sales) AS money) AS sales
FROM dw.orders
GROUP BY region
ORDER BY sales DESC;


--- Top 10 States by sales
SELECT state, CAST(SUM(sales) AS money) AS sales
FROM dw.orders
GROUP BY state 
ORDER BY sales DESC
LIMIT 10;




