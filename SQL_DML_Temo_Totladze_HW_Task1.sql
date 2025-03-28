INSERT INTO public.film
(title, description, release_year, language_id, rental_duration, rental_rate, length, rating, fulltext)
VALUES('The dark knight', 
		'When a menace known as the Joker wreaks havoc and chaos on the people of Gotham', 
		2008, 
		(SELECT language_id FROM "language" l WHERE name='English'), 
		1, 
		4.99, 
		152, 
		'PG-13', 
		to_tsvector('Batman and joker fight harvey dent is also there')),
	('Interstellar', 
    	'A group of astronauts travels through a wormhole in search of a new home for humanity.', 
    	2014, 
    	(SELECT language_id FROM "language" l WHERE name='English'), 
    	2, 
    	9.99, 
    	169, 
    	'PG-13', 
    	to_tsvector('space time wormhole blackhole family survival')),
    ('Back to the Future Part II', 
    	'Marty McFly travels to the future and must fix the timeline to save his family.', 
   		1989, 
    	(SELECT language_id FROM "language" l WHERE name='English'), 
    	3, 
    	19.99, 
    	108, 
    	'PG', 
    	to_tsvector('Marty McFly and Doc Brown time travel to future to save the family')
) ON CONFLICT (film_id) DO NOTHING;

INSERT INTO public.actor (first_name, last_name)
VALUES
    ('Christian','Bale'),
    ('Anne','Hathaway'),
    ('Matthew','McConaughey'),
    ('Jessica','Chastain'),
    ('Michael', 'Fox'),
    ('Christopher', 'Lloyd')
ON CONFLICT (actor_id) DO NOTHING;

INSERT INTO public.film_actor (actor_id, film_id)
SELECT a.actor_id, f.film_id
FROM public.actor a, public.film f
WHERE (a.first_name = 'Christian' AND a.last_name = 'Bale' AND f.title = 'The Dark Knight')
   OR (a.first_name = 'Anne' AND a.last_name = 'Hathaway' AND f.title = 'Interstellar')
   OR (a.first_name = 'Matthew' AND a.last_name = 'McConaughey' AND f.title = 'Interstellar')
   OR (a.first_name = 'Jessica' AND a.last_name = 'Chastain' AND f.title = 'Interstellar')
   OR (a.first_name = 'Michael' AND a.last_name = 'Fox' AND f.title = 'Back to the Future Part II')
   OR (a.first_name = 'Christopher' AND a.last_name = 'Lloyd' AND f.title = 'Back to the Future Part II')
ON CONFLICT DO NOTHING
RETURNING actor_id, film_id;


INSERT INTO public.inventory 
(film_id, store_id)
VALUES
((SELECT film_id FROM public.film WHERE title = 'The dark knight'),2)
ON CONFLICT DO NOTHING
RETURNING film_id, store_id;

SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id), COUNT(p.payment_id)
FROM public.customer c
LEFT JOIN public.rental r ON c.customer_id = r.customer_id
LEFT JOIN public.payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(r.rental_id) >= 43 AND COUNT(p.payment_id) >= 43
;

--i chose the random one from the query above and chose that id from now on if i didn't want to hardcode that i would make that query cte and limit 1

UPDATE public.customer
SET first_name = 'TEMO',
    last_name = 'TOTLADZE', 
    address_id = 5
WHERE customer_id = 184
RETURNING customer_id, first_name, last_name;

DELETE FROM public.rental
WHERE customer_id = 184
RETURNING customer_id;

DELETE FROM public.payment
WHERE customer_id = 184
RETURNING customer_id;

INSERT INTO rental (
    rental_date,
    inventory_id,
    customer_id,
    return_date,
    staff_id
)
SELECT
    '2017-03-15 10:30:00' AS rental_date,
    i.inventory_id,
    (SELECT customer_id
     FROM customer
     WHERE first_name = 'TEMO' AND last_name = 'TOTLADZE'), --i get my id
    NULL AS return_date,
    (SELECT staff_id
     FROM staff
     WHERE store_id = i.store_id --here i make sure that the staff that is in the right store
     LIMIT 1)
FROM inventory i
WHERE i.film_id = (SELECT film_id FROM film WHERE title = 'The dark knight')
LIMIT 1
RETURNING rental_id, customer_id, staff_id;

INSERT INTO payment (
    customer_id,
    staff_id,
    rental_id,
    amount,
    payment_date
)
SELECT
    (SELECT customer_id
     FROM customer
     WHERE first_name = 'TEMO' AND last_name = 'TOTLADZE') AS customer_id,
    (SELECT staff_id
     FROM staff
     WHERE store_id = i.store_id
     LIMIT 1) AS staff_id,
    rental_id,         
    4.99 AS amount,  
    '2017-03-15 12:00:00' AS payment_date
FROM rental, inventory i 
WHERE customer_id = 184
  AND staff_id = (SELECT staff_id
     FROM staff
     WHERE store_id = i.store_id
     LIMIT 1)
  AND rental_date = '2017-03-15 10:30:00'
LIMIT 1
ON CONFLICT DO NOTHING
RETURNING payment_id, customer_id, staff_id;






























