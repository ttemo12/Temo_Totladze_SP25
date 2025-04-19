CREATE USER rentaluser PASSWORD 'rentalpassword';

GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

GRANT SELECT ON customer TO rentaluser;

SELECT * FROM film f --done from rentaluser 

CREATE ROLE rental;

GRANT rental TO rentaluser;

GRANT INSERT, UPDATE ON rental TO rental;

GRANT USAGE ON SEQUENCE rental_rental_id_seq TO rental;--ERROR said that i didnt have PERMISSION TO use this STATEMENT so i had TO GRANT it

INSERT INTO public.rental--this was done USING USER rentaluser
(rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
VALUES(nextval('rental_rental_id_seq'::regclass), CURRENT_DATE, 1, 1, CURRENT_DATE, 1, now())
ON CONFLICT (rental_id) DO NOTHING;

UPDATE rental--had TO SET ROLE TO rental OR ELSE it wouldnt work this was done USING USER rentaluser
SET last_update = CURRENT_TIMESTAMP
WHERE rental_id = 1;

REVOKE INSERT ON rental FROM rental;

INSERT INTO public.rental--this was done USING USER rentaluser
(rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
VALUES(nextval('rental_rental_id_seq'::regclass), CURRENT_DATE, 2, 2, CURRENT_DATE, 2, now())
ON CONFLICT (rental_id) DO NOTHING; --PERMISSION denied 

SELECT c.customer_id, c.first_name, c.last_name, --query to find the user that task specified
       COUNT(p.payment_id) AS payment_count,
       COUNT(r.rental_id) AS rental_count
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(p.payment_id) > 0 AND COUNT(r.rental_id) > 0
LIMIT 1;

CREATE ROLE client_mary_smith;

ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

CREATE POLICY rental_policy_mary ON rental --creating policy for mary smith for RLS
    FOR SELECT TO client_mary_smith
    USING (customer_id = 1);

CREATE POLICY payment_policy_mary ON payment
    FOR SELECT TO client_mary_smith
    USING (customer_id = 1);

GRANT SELECT ON rental TO client_mary_smith;
GRANT SELECT ON payment TO client_mary_smith;

SET ROLE client_mary_smith;--changing role to mary smith so i can tests its functionality 

SELECT current_user, session_user; --checking that current_user IS mary smith

SELECT * FROM rental;--BOTH work AS intended 
SELECT * FROM payment;