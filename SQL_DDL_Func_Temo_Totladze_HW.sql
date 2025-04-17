--t1

CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
	SELECT c.name,
    SUM(CASE WHEN EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM CURRENT_DATE)
             AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
             THEN p.amount ELSE 0 END) AS current_quarter_sales,
    SUM(p.amount) AS total_sales
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film_category fc ON i.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
HAVING SUM(CASE WHEN EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM CURRENT_DATE)
             AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
             THEN p.amount ELSE 0 END) > 0;

--Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one PARAMETER
--representing the current quarter and year and returns the same result as the 'sales_revenue_by_category_qtr' view.
--t2
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(curr_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(c_name TEXT, current_quarter_sales NUMERIC)
LANGUAGE sql
AS $$
SELECT 
    c.name,
    SUM(CASE WHEN EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM curr_date)
             AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM curr_date)
             THEN p.amount ELSE 0 END) AS current_quarter_sales
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film_category fc ON i.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
HAVING SUM(CASE WHEN EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM curr_date)
                AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM curr_date)
                THEN p.amount ELSE 0 END) > 0;
$$
;

--t3
CREATE OR REPLACE FUNCTION most_popular_films_by_countries(
    p_countries VARCHAR[]
)
RETURNS TABLE (
    "Country" VARCHAR,
    "Film" VARCHAR,
    "Rating" TEXT,
    "Language" VARCHAR,
    "Length" INTEGER,
    "Release year" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	
	IF p_countries IS NULL OR array_length(p_countries, 1) IS NULL THEN --exception handling for when p_countries is null or inside the array is null
        RAISE EXCEPTION 'Countries parameter cannot be null or empty';
    END IF;

    RETURN QUERY
    WITH movie_rentals_by_country AS (
        SELECT
            ctry.country,
            f.film_id,
            f.title,
            COUNT(*) AS rental_count
        FROM public.rental r
        JOIN public.inventory i ON r.inventory_id = i.inventory_id
        JOIN public.film f ON i.film_id = f.film_id
        JOIN public.customer cust ON r.customer_id = cust.customer_id
        JOIN public.address addr ON cust.address_id = addr.address_id
        JOIN public.city ct ON addr.city_id = ct.city_id
        JOIN public.country ctry ON ct.country_id = ctry.country_id
        WHERE ctry.country = ANY(p_countries)
        GROUP BY ctry.country, f.film_id, f.title
    ),
    max_rental_counts AS (
        SELECT
            mrbc.country,
            MAX(mrbc.rental_count) AS max_rental_count
        FROM movie_rentals_by_country mrbc
        GROUP BY mrbc.country
    )
    SELECT --had to cast each value into matching return table or else it wouldn't work
        mrc.country::VARCHAR AS "Country",
        mrc.title::VARCHAR AS "Film",
        f.rating::TEXT AS "Rating",
        l.name::VARCHAR AS "Language",
        f.length::INTEGER AS "Length",
        f.release_year::INTEGER AS "Release year"
    FROM movie_rentals_by_country mrc
    JOIN max_rental_counts mrc_max
        ON mrc.country = mrc_max.country
        AND mrc.rental_count = mrc_max.max_rental_count
    JOIN public.film f ON mrc.film_id = f.film_id
    JOIN public.language l ON f.language_id = l.language_id
    ORDER BY mrc.country, mrc.title;

END;
$$;

--t4
CREATE OR REPLACE FUNCTION films_in_stock_by_title(film_like VARCHAR)
RETURNS TABLE (
    "Row_num" BIGINT,
    "Film Title" VARCHAR,
    "Language" VARCHAR,
    "Customer name" VARCHAR,
    "Rental date" TIMESTAMP
)
LANGUAGE plpgsql
AS $$
DECLARE
    found_rows INTEGER := 0;
BEGIN

    RETURN QUERY
    SELECT
        ROW_NUMBER() OVER (ORDER BY r.rental_date DESC, f.title) AS "Row_num",
        f.title::VARCHAR AS "Film Title",
        l.name::VARCHAR AS "Language",
        (c.first_name || ' ' || c.last_name)::VARCHAR AS "Customer name",
        r.rental_date::TIMESTAMP AS "Rental date"
    FROM
        rental r
    JOIN
        inventory i ON r.inventory_id = i.inventory_id
    JOIN
        film f ON i.film_id = f.film_id
    JOIN
        language l ON f.language_id = l.language_id
    JOIN
        customer c ON r.customer_id = c.customer_id
    WHERE
        f.title ILIKE film_like --ilike instead of like so we dont care about upper letters 
        AND r.return_date IS NULL
    ORDER BY
        r.rental_date DESC, f.title;

    GET DIAGNOSTICS found_rows = ROW_COUNT; --this way i check if above query returned anything if not than nothing matched 
											--and i raise notice below to notify that nothing matched

	IF found_rows = 0 THEN
    RAISE NOTICE 'No currently rented films matching "%" were found.', film_like;
END IF;
END;
$$;

--Create a procedure language function called 'new_movie' that takes a movie title as a parameter and 
--inserts a new movie with the given title in the film table. The function should generate a new unique 
--film ID, set the rental rate to 4.99, the rental duration to three days, the replacement cost to 19.99. 
--The release year and language are optional and by default should be current year and Klingon respectively. 
--The function should also verify that the language exists in the 'language' table.
--Then, ensure that no such function has been created before; if so, replace it.
--t5

CREATE OR REPLACE FUNCTION new_movie(movie_name VARCHAR)
RETURNS VOID
LANGUAGE plpgsql
AS 
$$
DECLARE
	lang_id INTEGER;
BEGIN
	SELECT language_id
	INTO lang_id
	FROM "language"
	WHERE "name"='Klingon';
	
	IF lang_id IS NULL THEN 
		RAISE EXCEPTION 'Language ID is NULL';
	END IF;

	INSERT INTO film (
        title,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost
    )
    VALUES (
        movie_name,
        EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER,
        lang_id,
        3,
        4.99,
        19.99
    );
END;
$$;