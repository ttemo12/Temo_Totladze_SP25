--t1)
WITH CTE1 AS (--extracting raw DATA FROM the TABLE so i can TRANSFORM it further later
    SELECT 
        EXTRACT(YEAR FROM s.time_id) AS calendar_year,
        co.country_region,
        ch.channel_desc,
        s.amount_sold
    FROM sales s
    JOIN channels ch ON s.channel_id = ch.channel_id
    JOIN customers c ON s.cust_id = c.cust_id
    JOIN countries co ON c.country_id = co.country_id
    WHERE EXTRACT(YEAR FROM s.time_id) BETWEEN 1998 AND 2001
      AND co.country_region IN ('Asia','Americas','Europe')
),
CTE2 AS (--aggregating total amount sold BY YEAR, region AND channel
    SELECT 
        calendar_year,
        country_region,
        channel_desc,
        SUM(amount_sold) AS amount_sold
    FROM CTE1
    GROUP BY calendar_year, country_region, channel_desc
),
CTE3 AS (--aggregating amount sold BY YEAR AND region 
    SELECT 
        calendar_year,
        country_region,
        SUM(amount_sold) AS total_amount_sold
    FROM CTE2
    GROUP BY calendar_year, country_region
),
CTE4 AS (--calculating the percentage SHARE OF EACH channel IN total regional sales per YEAR 
    SELECT 
        c2.calendar_year,
        c2.country_region,
        c2.channel_desc,
        c2.amount_sold,
        c3.total_amount_sold,
        ROUND((c2.amount_sold / c3.total_amount_sold) * 100, 2) AS "% BY CHANNELS"
    FROM CTE2 c2
    JOIN CTE3 c3 
      ON c2.calendar_year = c3.calendar_year
     AND c2.country_region = c3.country_region
),
CTE5 AS (--USING LAG TO calculate % change
    SELECT 
        *,
        LAG("% BY CHANNELS") OVER (
            PARTITION BY country_region, channel_desc
            ORDER BY calendar_year
        ) AS "% PREVIOUS PERIOD"
    FROM CTE4
)
SELECT country_region,--displaying ALL required COLUMNS AND calculating % diff
		calendar_year,
		channel_desc,
		amount_sold,
		"% BY CHANNELS",
		"% PREVIOUS PERIOD",
		ROUND(("% BY CHANNELS" - "% PREVIOUS PERIOD"), 2) AS "% DIFF"
FROM CTE5
WHERE calendar_year BETWEEN 1999 AND 2001
ORDER BY country_region, calendar_year, channel_desc;


--t2)
WITH CTE1 AS (--filtering raw DATA FIRST TO be processed USING 48 TO 52 so IN FINAL calculation the endpoint adjacent VALUES ARE included IN FINAL calculation
    SELECT
        t.calendar_week_number,
        t.day_number_in_week,
        t.time_id,
        TO_CHAR(t.time_id, 'Day') AS day_name,
        SUM(s.amount_sold) AS sales
    FROM times t
    JOIN sales s ON s.time_id = t.time_id
    WHERE t.calendar_week_number BETWEEN 48 AND 52
    AND t.calendar_year = 1999
    GROUP BY t.calendar_week_number, t.day_number_in_week, t.time_id
),
CTE2 AS (--calculating cumulative sales AND centered 3 DAY average but WITH cases ON monday AND friday
    SELECT
        c1.calendar_week_number,
        c1.time_id,
        c1.day_name,
        c1.day_number_in_week,
        c1.sales,
        SUM(c1.sales) OVER (
            PARTITION BY c1.calendar_week_number
            ORDER BY c1.day_number_in_week
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_sum,
        ROUND(
            CASE--USING cases TO make neccesary calculations ON monday AND friday
                WHEN c1.day_number_in_week = 1 THEN (
                    AVG(c1.sales) OVER (
                        ORDER BY c1.calendar_week_number, c1.day_number_in_week
                        ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING
                    )
                )
                WHEN c1.day_number_in_week = 5 THEN (
                    AVG(c1.sales) OVER (
                        ORDER BY c1.calendar_week_number, c1.day_number_in_week
                        ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING
                    )
                )
                ELSE (
                    AVG(c1.sales) OVER (
                        ORDER BY c1.calendar_week_number, c1.day_number_in_week
                        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
                    )
                )
            END, 
            2
        ) AS centered_3_day_avg
    FROM CTE1 c1
)
SELECT --displaying FINAL output
    calendar_week_number, 
    time_id, 
    day_name, 
    sales, 
    cum_sum, 
    centered_3_day_avg
FROM CTE2
WHERE calendar_week_number IN (49, 50, 51)
ORDER BY calendar_week_number, day_number_in_week;

--t3)
SELECT s.time_id,--average 3 DAY sales OF adjacent rows
    	SUM(s.amount_sold) AS sales,
    	ROUND(AVG(SUM(s.amount_sold)) OVER (
        	ORDER BY s.time_id
        	ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    	), 2) AS avg_sales_rows
FROM sales s
GROUP BY s.time_id
ORDER BY s.time_id;

SELECT s.time_id, --7 DAY sum OF amount sold 
    	SUM(s.amount_sold) AS sales,
    	ROUND(SUM(SUM(s.amount_sold)) OVER (
	        ORDER BY s.time_id
	        RANGE BETWEEN INTERVAL '6' DAY PRECEDING AND CURRENT ROW
    	), 2) AS avg_sales_range
FROM sales s
GROUP BY s.time_id
ORDER BY s.time_id;

SELECT s.time_id,--sum OF amount sold OF 2 days BEFORE AND CURRENT value, this query ALSO includes the same value time_id sales IN calculation
    	s.amount_sold,
    	SUM(amount_sold) OVER (
        	ORDER BY s.time_id
        	GROUPS BETWEEN 2 PRECEDING AND CURRENT ROW
    	) AS 3_day_group_sum
FROM sales s
ORDER BY s.time_id;
