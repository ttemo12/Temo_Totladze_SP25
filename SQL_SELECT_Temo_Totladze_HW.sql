--part1 
--1)All animation movies released between 2017 and 2019 with rate more than 1, alphabetical
--i make an assumption that rate > 1 means  ('PG','PG-13', 'R', 'NC-17') so not including 'G'
-- the information to display here is in 3 tables, i join them and filter them by 3 conditions, then order them by alphabetical order. 
SELECT f.title
FROM film f
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category c ON fc.category_id = c.category_id
WHERE c.name='Animation'
AND
f.release_year BETWEEN 2017 AND 2019
AND
f.rental_rate > 1
ORDER BY f.title ASC;

--this query includes year 2019 too if i want to not include year 2019 i would enter between 2017 and 2018, another way of doing this with CTE is 

WITH FilmCategoryCTE AS (
    SELECT *
    FROM film f
    INNER JOIN film_category fc ON f.film_id = fc.film_id
    INNER JOIN category c ON fc.category_id = c.category_id
)
SELECT title 
FROM FilmCategoryCTE
WHERE name='Animation'
AND release_year BETWEEN 2017 AND 2019
AND FilmCategoryCTE.rental_rate > 1
ORDER BY title ASC;

--part1
--2)The revenue earned by each rental store after March 2017
--i sum the revenue of each store filtered by > '2017-03-31'
SELECT  store_id, sum(amount) AS revenue
FROM payment p INNER JOIN staff s
ON p.staff_id = s.staff_id 
WHERE p.payment_date > '2017-03-31'
GROUP BY store_id

-- another way of doing this is with cte

WITH PaymentStaffCTE AS (
    SELECT *
    FROM payment p
    INNER JOIN staff s ON p.staff_id = s.staff_id
    WHERE p.payment_date > '2017-03-31'
)
SELECT store_id, SUM(amount) AS total_revenue
FROM PaymentStaffCTE
GROUP BY store_id
ORDER BY total_revenue DESC;

--i dont know why the question is asking to display adresses when the problem is about stores

--part1
--3)Top-5 actors by number of movies (released after 2015) they took part in 
--(columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
--i first get the ids of the actors filtered by the amount of movies they have been in 
--after 2015. after that i order them, display top 5 of their names

WITH filmactorCTE AS (SELECT fa.actor_id ,count(fa.film_id) AS number_of_movies
						FROM film_actor fa
						INNER JOIN film f ON f.film_id=fa.film_id
						WHERE f.release_year > 2015
						GROUP BY fa.actor_id 
						ORDER BY number_of_movies)
SELECT a.first_name, a.last_name, fmc.number_of_movies
FROM filmactorCTE fmc
INNER JOIN actor a ON fmc.actor_id = a.actor_id
ORDER BY fmc.number_of_movies DESC
LIMIT 5

-- this was with cte without cte we can use subquery 

SELECT 
	a.first_name,
	a.last_name,
	(SELECT COUNT(*)
	FROM film_actor fa 
	INNER JOIN film f ON fa.film_id = f.film_id 
	WHERE fa.actor_id = a.actor_id 
	AND f.release_year > 2015) 
				AS number_of_movies 
				FROM actor a 
				ORDER BY number_of_movies DESC LIMIT 5;

--part1)
--4)Number of Drama, Travel, Documentary per year 
--(columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), 
--sorted by release year in descending order. Dealing with NULL values is encouraged)
--just like in the first question the problem is scattered over 3 tables i join them, 
--each column after year counts the number of occurances of each category per year, to achieve this it is grouped by release year 

SELECT f.release_year,
	COUNT(CASE WHEN c.name = 'Drama' THEN 1 END) AS number_of_drama_movies,
	COUNT(CASE WHEN c.name = 'Travel' THEN 1 END) AS number_of_travel_movies,
	COUNT(CASE WHEN c.name = 'Documentary' THEN 1 END) AS number_of_documentary_movies 
FROM film f
INNER JOIN film_category fc ON f.film_id = fc.film_id 
INNER JOIN category c ON c.category_id = fc.category_id
GROUP BY f.release_year
ORDER BY f.release_year desc;

--this can also be done with subqueries although it has high overhead and not efficient

SELECT f.release_year,
    (SELECT COUNT(*) FROM film f1 INNER JOIN film_category fc1 ON f1.film_id = fc1.film_id INNER JOIN category c1 ON fc1.category_id = c1.category_id WHERE c1.name = 'Drama' AND f1.release_year = f.release_year) AS number_of_drama_movies,
    (SELECT COUNT(*) FROM film f2 INNER JOIN film_category fc2 ON f2.film_id = fc2.film_id INNER JOIN category c2 ON fc2.category_id = c2.category_id WHERE c2.name = 'Travel' AND f2.release_year = f.release_year) AS number_of_travel_movies,
    (SELECT COUNT(*) FROM film f3 INNER JOIN film_category fc3 ON f3.film_id = fc3.film_id INNER JOIN category c3 ON fc3.category_id = c3.category_id WHERE c3.name = 'Documentary' AND f3.release_year = f.release_year) AS number_of_documentary_movies
FROM film f
GROUP BY f.release_year
ORDER BY f.release_year DESC;

--part2)
--1)Which three employees generated the most revenue in 2017?
--They should be awarded a bonus for their outstanding performance.
--grouping the columns after joining 3 tables ands summing the amount that is filtered by year 2017, 
--summing the amount after these filters ordering them by desc so we can get the top performers on top
-- and then displaying the top 3
SELECT 
    p.staff_id,
    s.first_name,
    s.last_name,
    st.store_id,
    SUM(p.amount) AS staff_revenue
FROM payment p
INNER JOIN staff s ON p.staff_id = s.staff_id
INNER JOIN store st ON s.store_id = st.store_id
WHERE EXTRACT(year FROM p.payment_date) = 2017
GROUP BY p.staff_id, s.first_name, s.last_name, st.store_id
ORDER BY staff_revenue DESC
LIMIT 3;

--part2
--2)Which 5 movies were rented more than others (number of rentals),
--and what's the expected age of the audience for these movies? 
--after joining inventory and rental tables counting f.film_id and grouping them by f.film_id
--will give the number of times each film has been rented out, so i filter them by desc and 
--choose top 5 

SELECT f.film_id, f.title, f.rating , count(f.film_id) AS num_of_rentals FROM film f
INNER JOIN inventory i ON f.film_id = i.film_id 
INNER JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title, f.rating
ORDER BY num_of_rentals DESC
LIMIT 5;

--p3)
--Which actors/actresses didn't act for a longer period of time than the others? 

--the logic of mine from the start was to try and make another temporary table f2.release_year
--that would be f.release_year + 1 in cells, that would move every cells up by one point, so i
--tried to use the logic that i had for the other problem ive done in the past, unfortunately 
--this solution would not be possible since after joining the tables that i would need the 
--output from i wouldve needed to check if the difference of the corresponding pks would be 
--1, but the joined table had no such thing to go after and check for each cell, this logic
--was incorrect, but i knew it had to be done this way (by getting another column with cells
--shifted up), this is where i found out about lag that would shift the values by 1 and also
--return null on the cells that it would be incorrect for, this was the perfect solution for
--this problem, the following is my step-to-step solution for the problem 
WITH newCTE AS
		(SELECT fa.actor_id,
		f.release_year,
		LAG(f.release_year, 1) OVER (PARTITION BY fa.actor_id ORDER BY f.release_year) AS prev_year,
		abs(f.release_year - LAG(f.release_year, 1) OVER (PARTITION BY fa.actor_id ORDER BY f.release_year)) AS total_diff
FROM film_actor fa 
INNER JOIN film f ON fa.film_id = f.film_id),
actor_biggest_diff AS
		(SELECT newCTE.actor_id,
		max(newCTE.total_diff) AS biggest_diff 
		FROM newCTE 
		GROUP BY newCTE.actor_id
		ORDER BY biggest_diff DESC),
slowest_actors AS 
		(SELECT actor_biggest_diff.actor_id, 
		 actor_biggest_diff.biggest_diff 
		 FROM actor_biggest_diff 
		 WHERE biggest_diff in 
				   	(SELECT max(actor_biggest_diff.biggest_diff)
				   	FROM actor_biggest_diff))
SELECT a.first_name ||' '|| a.last_name AS actor_name, 
	   sla.biggest_diff 
	   FROM slowest_actors sla 
       INNER JOIN actor a ON a.actor_id=sla.actor_id;

--high overhead, redundant at places but if i find out other way of doing it i will add to it.