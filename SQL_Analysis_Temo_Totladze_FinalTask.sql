--t1)
WITH channel_region_sales AS ( --making initial TABLE WITH ALL the data that i will need for calculation later 
    SELECT 
        ch.channel_desc,
        co.country_region,
        SUM(s.quantity_sold) AS total_quantity_sold
    FROM sales s
    JOIN channels ch ON s.channel_id = ch.channel_id
    JOIN customers cu ON s.cust_id = cu.cust_id
    JOIN countries co ON co.country_id = cu.country_id
    GROUP BY 
        ch.channel_desc, co.country_region
),
channel_totals AS (--calculating channel totals here BY GROUPING BY channel_desc ONLY 
    SELECT 
        channel_desc,
        SUM(total_quantity_sold) AS channel_total_quantity
    FROM channel_region_sales
    GROUP BY 
        channel_desc
),
final_data AS ( --calculating percentage here
    SELECT 
        crs.channel_desc,
        crs.country_region,
        crs.total_quantity_sold,
        ct.channel_total_quantity,
        (crs.total_quantity_sold * 100.0 / ct.channel_total_quantity) AS sales_percentage
    FROM channel_region_sales crs
    JOIN 
        channel_totals ct ON crs.channel_desc = ct.channel_desc
)
SELECT 
    channel_desc AS "channel_desc",
    country_region AS "country_region",
    TO_CHAR(total_quantity_sold, 'FM999,999,990.00') AS "sales", --formating FOR display
    TO_CHAR(sales_percentage, 'FM990.00') || '%' AS "SALES %" --here AS well
FROM final_data
ORDER BY 
    total_quantity_sold DESC;


--t2) -- im counting the number of positive growth years by each subcat
WITH yearly_sales AS (--calculating total amount sold
    SELECT
        p.prod_subcategory,
        EXTRACT(YEAR FROM t.time_id) AS sale_year,
        SUM(s.amount_sold) AS total_sales
    FROM
        sales s
    JOIN
        times t ON s.time_id = t.time_id
    JOIN
        products p ON s.prod_id = p.prod_id
    WHERE
        EXTRACT(YEAR FROM t.time_id) BETWEEN 1997 AND 2001 -- INCLUDING 1997 so it IS correctly calculated FOR 1998
        AND p.prod_subcategory IS NOT NULL -- Ensure we don't include NULL subcategories
    GROUP BY
        p.prod_subcategory, EXTRACT(YEAR FROM t.time_id)
),
sales_with_previous AS (--im USING LAG FUNCTION TO GET the VALUES FROM the previous YEAR IN another COLUMN TO make further calculations
    SELECT
        prod_subcategory,
        sale_year,
        total_sales AS current_year_sales,
        LAG(total_sales, 1) OVER (
            PARTITION BY prod_subcategory
            ORDER BY sale_year
        ) AS previous_year_sales
    FROM
        yearly_sales
),
delta_query AS (
    SELECT 
        prod_subcategory,
        sale_year,
        current_year_sales,
        previous_year_sales,
        (current_year_sales - previous_year_sales) AS delta
    FROM 
        sales_with_previous
    WHERE
        sale_year BETWEEN 1998 AND 2001 -- only considering 1998-2001
        AND previous_year_sales IS NOT NULL --making sure that the previous years DATA exists
),
positive_growth_years AS (
    SELECT
        prod_subcategory,
        COUNT(*) AS years_with_positive_growth
    FROM 
        delta_query
    WHERE 
        delta > 0 -- ONLY counting years WITH positive growth
    GROUP BY
        prod_subcategory
)
SELECT
	prod_subcategory
FROM
positive_growth_years
WHERE
years_with_positive_growth = 4 --must have positive 4 YEAR OF growth
ORDER BY
    prod_subcategory;

--t3)
WITH filtered_sales AS (--FILTERING the DATA TO ONLY INCLUDE the aspects we ARE interested IN
    SELECT 
        t.calendar_year,
        t.calendar_quarter_desc,
        p.prod_category,
        c.channel_desc,
        s.amount_sold
    FROM 
        sales s
    JOIN 
        times t ON s.time_id = t.time_id
    JOIN 
        products p ON s.prod_id = p.prod_id
    JOIN 
        channels c ON s.channel_id = c.channel_id
    WHERE 
        t.calendar_year IN (1999, 2000)
        AND p.prod_category IN ('Electronics', 'Hardware', 'Software/Other')
        AND c.channel_desc IN ('Partners', 'Internet')
),
grouped_sales AS (--GROUPING sales BY YEAR, quarter AND prod category
    SELECT 
        calendar_year,
        calendar_quarter_desc,
        prod_category,
        ROUND(SUM(amount_sold), 2) AS sales
    FROM 
        filtered_sales
    GROUP BY 
        calendar_year, calendar_quarter_desc, prod_category
),
q1_based_calc AS (--getting q1 sales value FOR YEAR AND category AND ALSO calculating cumsum
    SELECT 
        calendar_year,
        calendar_quarter_desc,
        prod_category,
        sales,
        FIRST_VALUE(sales) OVER (
            PARTITION BY calendar_year, prod_category 
            ORDER BY calendar_quarter_desc
        ) AS q1_sales,
        SUM(sales) OVER (
            PARTITION BY calendar_year, prod_category 
            ORDER BY calendar_quarter_desc
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_sum
    FROM 
        grouped_sales
),
final_report AS (--formating FOR FINAL display
    SELECT 
        calendar_year AS calendar_year,
        calendar_quarter_desc AS calendar_quarter_desc,
        prod_category AS prod_category,
        TO_CHAR(sales, 'FM99999990.00') AS "sales$",
        CASE 
            WHEN calendar_quarter_desc = 'Q1' THEN 'N/A'
            ELSE TO_CHAR(ROUND(((sales - q1_sales) / q1_sales) * 100, 2), 'FM9999990.00') || '%'
        END AS diff_percent,
        TO_CHAR(cum_sum, 'FM99999990.00') AS "cum_sum$"
    FROM 
        q1_based_calc
)
SELECT * 
FROM final_report
ORDER BY 
    calendar_year, 
    calendar_quarter_desc;





