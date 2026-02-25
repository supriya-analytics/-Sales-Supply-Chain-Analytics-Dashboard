
 CREATE TABLE products(
		product_id INT PRIMARY KEY,
		product_name VARCHAR (100),
		category VARCHAR (50),
		unit_cost DECIMAL (10,2),
		unit_price DECIMAL (10,2)
 );

 CREATE TABLE suppliers(
		supplier_id INT PRIMARY KEY,
		supplier_name VARCHAR (100),
		supplier_city VARCHAR (50),
		lead_time_days INt
 );

 CREATE TABLE inventory(
		inventory_id INT PRIMARY KEY,
		product_id INT,
		supplier_id INT,
		warehouse VARCHAR (50),
		stock_level INT,
		reorder_level INT,
					FOREIGN KEY (product_id)
					REFERENCES products (product_id),

					FOREIGN KEY (supplier_id)
					REFERENCES suppliers (supplier_id)
 );

 CREATE TABLE orders (
		order_id INT PRIMARY KEY,
		product_id INT,
		order_date DATE,
		quantity INT,
		region VARCHAR (50),
		delivery_days INT,
		unit_price DECIMAL (10,2),
		total_sales DECIMAL (12,2),
					FOREIGN KEY (product_id)
					REFERENCES products (product_id)
 );

 SELECT * FROM products;
 SELECT * FROM suppliers;
 SELECT * FROM inventory;
 SELECT * FROM orders;


--1. Top 10 products generating highest revenue

 SELECT p.product_name,
        sum(o.total_sales) as total_revenue
 FROM products p
 JOIN orders o
 ON p.product_id = o.product_id
 group by p.product_name
 ORDER BY total_revenue DESC
 LIMIT 10;

--2. Orders where delivery_days exceeded 7 days.

 SELECT order_id, delivery_days
 FROM orders
 where delivery_days > 7;

--3. Products with unit_price greater than category average price.

 SELECT *
 FROM products p
 WHERE unit_price > (
    SELECT AVG(unit_price)
    FROM products
    WHERE category = p.category
);

--4. Suppliers operating from Mumbai with lead_time_days > 5.

 SELECT * FROM suppliers
 WHERE supplier_city = 'Mumbai' AND
 	   lead_time_days > 5;

--5. Total revenue per region.

 SELECT region, SUM (total_sales) AS total_revenue
 FROM orders
 GROUP BY region;

--6. Average delivery_days per supplier.

 SELECT s.supplier_name , 
        ROUND (AVG (delivery_days),2) AS avg_days
 FROM orders o 
 JOIN products p
 	  ON p.product_id = o.product_id
 JOIN inventory i
      ON p.product_id = i.product_id
 JOIN suppliers s
      ON s.supplier_id = i.supplier_id
 GROUP BY s.supplier_name ;

--7. Total stock_level per warehouse.

 SELECT warehouse, SUM (stock_level) as total_stock_level
 FROM inventory
 GROUP BY warehouse;

--8. Category-wise profit margin

SELECT p.category,
	   ROUND (SUM ((p.unit_price - p.unit_cost)* o.quantity) /
	   SUM (o.total_sales) * 100,2) AS profit_margin_per
FROM products p
JOIN orders o
ON p.product_id = o.product_id
GROUP BY p.category;

--9. Total revenue per category

 SELECT p.category,
        SUM (o.total_sales) as total_revenue
 FROM products p
 JOIN orders o
 ON p.product_id = o.product_id
 GROUP BY p.category;

--10. Suppliers linked to products with stock below reorder level

 SELECT DISTINCT s.supplier_name, i.stock_level, i.reorder_level
 FROM suppliers s
 JOIN inventory i
 ON s.supplier_id = i.supplier_id
 WHERE i.stock_level < i.reorder_level;
 
--11. Region-wise sales with supplier lead time impact

 SELECT o.region,
        ROUND (AVG(s.lead_time_days),2) AS avg_lead_time,
		       SUM(o.total_sales) AS total_sales
 FROM orders o
 JOIN products p  ON o.product_id = p.product_id
 JOIN inventory i ON p.product_id = i.product_id
 JOIN suppliers s ON s.supplier_id = i.supplier_id
 GROUP BY o.region;

--12. Warehouse-wise sales performance

 SELECT i.warehouse,
        SUM (o.total_sales) AS total_sales
 FROM orders o
 JOIN inventory i ON o.product_id = i.product_id
 GROUP BY i.warehouse;

--13. Products whose sales are above overall average sales

 SELECT product_id,
        SUM (total_sales) AS total_sales
 FROM orders 
 GROUP BY product_id
 HAVING SUM(total_sales) >
 			(SELECT AVG (total_sales) FROM orders);

--14. Suppliers with lead_time_days greater than average

 SELECT * 
 FROM suppliers 
 WHERE lead_time_days > 
 		(SELECT AVG (lead_time_days) FROM suppliers);

--15. Warehouses having stock higher than average stock

 SELECT warehouse
 FROM inventory
 GROUP BY warehouse
 HAVING SUM (stock_level) >
 		(SELECT AVG (stock_level) FROM inventory);

--16. Rank products by revenue within each category

 SELECT p.category,
        p.product_name,
		SUM (o.total_sales) AS total_revenue ,
 RANK() OVER (PARTITION BY p.category ORDER BY SUM(o.total_sales)DESC) AS ranking
 FROM products p
 JOIN orders o 
 ON p.product_id = o.product_id
 GROUP BY p.category, p.product_name;

--17. Running total of sales by date

 SELECT order_date,
      SUM(total_sales) AS daily_sales,
      SUM(SUM(total_sales)) OVER 
      (ORDER BY order_date) AS running_total
 FROM orders
 GROUP BY order_date
 ORDER BY order_date;

--18. Top 3 suppliers by delivery performance (lowest lead time)

 SELECT * FROM (
 		SELECT supplier_name, lead_time_days,
		RANK() OVER (ORDER BY lead_time_days DESC) AS rank_supplier
		FROM suppliers
		) t
		WHERE rank_supplier <=3;

--19. Month-Over-Month sales growth
 
 WITH monthly_sales AS (
 
 SELECT 
 		DATE_TRUNC ('month',order_date) AS month,
		SUM (total_sales) AS monthly_revenue
 FROM orders
 GROUP BY DATE_TRUNC ('month', order_date) 
 )

 SELECT 
 		month, 
		monthly_revenue,
		LAG (monthly_revenue) Over (ORDER BY month) as pre_month_revenue,
		(monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month)) AS mom_growth
		FROM monthly_sales
		ORDER BY month;
		 
--20. Month-over-Month (MoM) Growth %

 WITH monthly_sales AS (

 	SELECT 
		  DATE_TRUNC ('month', order_date) AS month,
		  SUM (total_sales) AS monthly_revenue
		  FROM orders
		  GROUP BY DATE_TRUNC ('month', order_date)
	 )

	 SELECT 
	 	  month,
		  monthly_revenue,
		  LAG (monthly_revenue) OVER (ORDER BY month) AS pre_month_revenue,
		  ROUND ((monthly_revenue - Lag(monthly_revenue) OVER (ORDER BY month))/
          Lag(monthly_revenue) OVER (ORDER BY month)* 100,2) AS mom_growth_percentage
		  FROM monthly_sales
		  ORDER BY month;
          
--21. Comparing current month sales with previous month using LAG

 WITH monthly_sales AS(
		SELECT 
		      DATE_TRUNC('month', order_date) AS month,
			  SUM(total_sales) AS monthly_revenue
			  FROM orders
			  GROUP BY DATE_TRUNC('month', order_date)
 )

        SELECT 
			  month,
			  monthly_revenue,
			  LAG (monthly_revenue ) OVER (ORDER BY month) AS pre_month_revenue
			  FROM monthly_sales
			  ORDER BY month;

--22. Categorize products as High, Medium, Low demand based on sales volume

 SELECT p.product_name,
 		SUM (o.quantity) as total_qty,
		CASE
			WHEN SUM(o.quantity) >=80 THEN 'high_demand'
			WHEN SUM(o.quantity) BETWEEN 30 AND 79 THEN 'medium_demand'
			ELSE
			'low_demand'
			END AS sales_category
			FROM orders o
			JOIN products p
			ON o.product_id = p.product_id
			GROUP BY p.product_name;

--23. Label delivery performance as On-Time or Delayed

 SELECT 
 	   order_id,
	   delivery_days,
	   CASE
	   		WHEN delivery_days <=5 THEN 'on_time'
			ELSE
			'delayed'
			END AS delivery_performance
			FROM orders
			GROUP BY order_id;

--24. Classify suppliers as Efficient, Moderate, Risky

 SELECT 
 	   supplier_name,
	   lead_time_days,
	   CASE
	        WHEN lead_time_days <= 5 THEN 'efficient'
			WHEN lead_time_days BETWEEN 6 AND 10 THEN 'moderate'
			ELSE
			'risky'
			END AS supplier_category
			FROM suppliers;
			
--25. Create profit band segmentation.

 SELECT 
       P.product_name,
	   SUM ((p.unit_price - p.unit_cost) * o.quantity) AS total_profit,
	   CASE
	   		WHEN SUM ((p.unit_price - p.unit_cost) * o.quantity) >=50000 THEN 'hight_profit'
			WHEN SUM ((p.unit_price - p.unit_cost) * o.quantity) BETWEEN 20000 AND 49999 THEN 'medium_profit'
			ELSE
			'low_profit'
			END AS profit_band
			FROM products p
			JOIN orders o
			ON p.product_id = o.product_id
			GROUP BY p.product_name;

--26. Extract monthly revenue trends

 SELECT
 	   DATE_TRUNC ('month' , order_date) AS month,
	   SUM(total_sales) AS monthly_revenue
	   FROM orders
	   GROUP BY DATE_TRUNC ('month' , order_date)
	   ORDER BY month;

--27. Identify peak sales month

SELECT * FROM (
			SELECT
				  DATE_TRUNC ('month', order_date) AS month,
				  SUM (total_sales) AS monthly_revenue,
				  RANK () OVER (ORDER BY SUM (total_sales) DESC ) AS rank_month
				  FROM orders
				  GROUP BY DATE_TRUNC ('month', order_date)
			   ) t

			      WHERE rank_month =1;

--28. Calculate quarterly growth rate

 WITH quarterly_sales AS (
                 SELECT 
				        DATE_TRUNC('quarter', order_date) AS quarter,
						SUM (total_sales) AS quarterly_sales
						FROM orders
						GROUP BY DATE_TRUNC('quarter', order_date)
						)

				 SELECT 
				        quarter,
						quarterly_sales,
						LAG(quarterly_sales) OVER (ORDER BY quarter) AS previous_qtr_sales,
						ROUND((quarterly_sales - LAG(quarterly_sales) OVER (ORDER BY quarter))/
						LAG(quarterly_sales) OVER (ORDER BY quarter)* 100,2) AS quaterly_growth_per
						FROM quarterly_sales;

--29. Compare weekend vs weekday sales

SELECT 
    SUM(total_sales) AS total_revenue,
    CASE 
        WHEN EXTRACT(DOW FROM order_date) IN (0,6) THEN 'Weekend'
        ELSE 'Weekday'
        END AS day_type
		FROM orders
		GROUP BY day_type;
		










 