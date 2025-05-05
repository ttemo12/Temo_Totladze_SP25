--Create a query to produce a sales report highlighting the top customers with the highest sales across different sales channels.
--This report should list the top 5 customers for each channel. Additionally, calculate a key performance indicator (KPI) called 'sales_percentage,'
--which represents the percentage of a customer's sales relative to the total sales within their respective channel.
--Please format the columns as follows:
--Display the total sales amount with two decimal places
--Display the sales percentage with four decimal places and include the percent sign (%) at the end
--Display the result for each channel in descending order of sales



WITH total_soldCTE AS (-- CTE to calculate total amount sold per customer per channel
	SELECT
		c.cust_id,
		s.channel_id,
    	ch.channel_desc,
    	c.cust_last_name, 
    	c.cust_first_name, 
    	SUM(s.amount_sold) AS total_amount_sold
	FROM sales s 
	JOIN channels ch ON s.channel_id = ch.channel_id
	JOIN customers c ON c.cust_id = s.cust_id
	GROUP BY c.cust_id, c.cust_last_name, c.cust_first_name, ch.channel_desc, s.channel_id
), 
channel_totalCTE AS (--CTE TO calculate total sales FOR EACH channel
	SELECT
		channel_desc,
		SUM(total_amount_sold) AS channel_total_sales
	FROM total_soldCTE
	GROUP BY channel_desc
),
ranked_custCTE AS (--CTE TO RANK customers WITHIN EACH channel based ON their sales
	SELECT 
		ts.*,
		DENSE_RANK() OVER (PARTITION BY ts.channel_desc ORDER BY ts.total_amount_sold DESC) AS ranked_cust
	FROM total_soldCTE ts
),
top_custCTE AS (--CTE TO FILTER ONLY the top 5 customers
	SELECT 
		rc.*,
		ct.channel_total_sales
	FROM ranked_custCTE rc
	JOIN channel_totalCTE ct 
		ON rc.channel_desc = ct.channel_desc
	WHERE rc.ranked_cust <= 5
)
SELECT --formated FOR display
	tc.channel_desc,
	tc.cust_last_name,
	tc.cust_first_name,
	ROUND(tc.total_amount_sold, 2) AS total_sales,
	CONCAT(ROUND((tc.total_amount_sold / tc.channel_total_sales) * 100, 4), '%') AS sales_percentage
FROM 
	top_custCTE tc
ORDER BY 
	tc.channel_desc,
	tc.total_amount_sold DESC;


--Create a query to retrieve data for a report that displays the total sales 
--for all products in the Photo category in the Asian region for the year 2000. 
--Calculate the overall report total and name it 'YEAR_SUM'
--Display the sales amount with two decimal places
--Display the result in descending order of 'YEAR_SUM'
--For this report, consider exploring the use of the crosstab function.



WITH CTE1 AS ( -- CTE TO FILTER record based ON region YEAR AND prod_category
	SELECT *
	FROM sales s 
	JOIN customers c ON c.cust_id = s.cust_id
	JOIN products p ON p.prod_id = s.prod_id
	JOIN countries co ON co.country_id = c.country_id
	WHERE co.country_region = 'Asia'
		AND EXTRACT(YEAR FROM time_id) = 2000
    	AND p.prod_category = 'Photo'
)
SELECT --query TO AGGREGATE sales BY EACH quarter
 	CTE1.prod_name,
	SUM(CASE WHEN EXTRACT(QUARTER FROM CTE1.time_id) = 1 THEN CTE1.amount_sold ELSE 0 END) AS Q1,
	SUM(CASE WHEN EXTRACT(QUARTER FROM CTE1.time_id) = 2 THEN CTE1.amount_sold ELSE 0 END) AS Q2,
	SUM(CASE WHEN EXTRACT(QUARTER FROM CTE1.time_id) = 3 THEN CTE1.amount_sold ELSE 0 END) AS Q3,
	SUM(CASE WHEN EXTRACT(QUARTER FROM CTE1.time_id) = 4 THEN CTE1.amount_sold ELSE 0 END) AS Q4,
	SUM(CTE1.amount_sold) AS year_sum --sum OF ALL quarter
FROM CTE1
GROUP BY CTE1.prod_name;

--Create a query to generate a sales report for customers ranked in the top 300 based on total sales in the years 1998, 1999, and 2001.
--The report should be categorized based on sales channels, and separate calculations should be performed for each channel.
--Retrieve customers who ranked among the top 300 in sales for the years 1998, 1999, and 2001
--Categorize the customers based on their sales channels
--Perform separate calculations for each sales channel
--Include in the report only purchases made on the channel specified
--Format the column so that total sales are displayed with two decimal places

WITH salesCTE AS (-- CTE to calculate total amount sold per customer per channel per year
  SELECT 
    s.channel_id,
    ch.channel_desc,
    c.cust_id,
    c.cust_first_name,
    c.cust_last_name,
    EXTRACT(YEAR FROM s.time_id) AS sales_year,
    SUM(s.amount_sold) AS total_sales
  FROM sales s
  JOIN channels ch ON s.channel_id = ch.channel_id
  JOIN customers c ON c.cust_id = s.cust_id
  WHERE EXTRACT(YEAR FROM s.time_id) IN (1998, 1999, 2001)
  GROUP BY s.channel_id, ch.channel_desc, c.cust_id, c.cust_first_name, c.cust_last_name, EXTRACT(YEAR FROM s.time_id)
),
ranked_sales AS (--ranking customers per YEAR AND channel based ON total sales 
  SELECT *,
         RANK() OVER (PARTITION BY channel_id, sales_year ORDER BY total_sales DESC) AS sales_rank
  FROM salesCTE
),
top_300_all_years AS ( --selecting customers that were IN top 300 IN ALL years 
  SELECT cust_id, channel_id
  FROM ranked_sales
  WHERE sales_rank <= 300
  GROUP BY cust_id, channel_id
  HAVING COUNT(DISTINCT sales_year) = 3
),
final_report AS (-- formatted FOR display
  SELECT rs.channel_id,
         rs.channel_desc,
         rs.sales_year,
         rs.cust_id,
         rs.cust_first_name,
         rs.cust_last_name,
         ROUND(rs.total_sales, 2) AS total_sales
  FROM ranked_sales rs
  JOIN top_300_all_years t
    ON rs.cust_id = t.cust_id AND rs.channel_id = t.channel_id
  WHERE rs.sales_year IN (1998, 1999, 2001)
)
SELECT 
  channel_desc,
  sales_year,
  cust_id,
  cust_first_name,
  cust_last_name,
  total_sales
FROM final_report
ORDER BY channel_desc, sales_year, total_sales DESC;



--Create a query to generate a sales report for January 2000, February 2000, and March 2000 specifically for the Europe and Americas regions.
--Display the result by months and by product category in alphabetical order.

SELECT 
  TO_CHAR(s.time_id, 'YYYY-MM') AS calendar_month,
  p.prod_category,
  ROUND(SUM(CASE WHEN co.country_region = 'Americas' THEN s.amount_sold ELSE 0 END), 2) AS america_sales,--summing independently FOR EACH region
  ROUND(SUM(CASE WHEN co.country_region = 'Europe' THEN s.amount_sold ELSE 0 END), 2) AS europe_sales
FROM sales s
JOIN customers c ON s.cust_id = c.cust_id
JOIN countries co ON c.country_id = co.country_id
JOIN products p ON s.prod_id = p.prod_id
WHERE EXTRACT(YEAR FROM s.time_id) = 2000 --filtering FOR YEAR 2000 AND months 1,2,3 AND region europe AND americas
  AND EXTRACT(MONTH FROM s.time_id) IN (1, 2, 3) 
  AND co.country_region IN ('Europe', 'Americas')
GROUP BY TO_CHAR(s.time_id, 'YYYY-MM'), p.prod_category
ORDER BY calendar_month, p.prod_category;





