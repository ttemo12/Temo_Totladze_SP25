CREATE DATABASE IF NOT EXISTS museum;

CREATE SCHEMA IF NOT EXISTS museum;

DROP SCHEMA IF EXISTS museum CASCADE;


CREATE TABLE IF NOT EXISTS locations (
    l_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    l_name VARCHAR(255) NOT NULL,
    l_floor SMALLINT NOT NULL
);

CREATE TABLE IF NOT EXISTS artifacts (
    a_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    a_name VARCHAR(255) NOT NULL,
    a_origin VARCHAR(255),
    a_condition VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS staff (
    s_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    s_name VARCHAR(255) NOT NULL,
    s_surname VARCHAR(255) NOT NULL,
    s_mail TEXT NOT NULL,
    s_number TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS visitors (
    v_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    v_name VARCHAR(255) NOT NULL,
    v_mail TEXT NOT NULL,
    v_visiting_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS payments (
    p_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    v_id BIGINT NOT NULL REFERENCES museum.visitors(v_id),
    p_amount BIGINT NOT NULL,
    p_method VARCHAR(255) NOT NULL,
    p_date DATE NOT NULL 
);

CREATE TABLE IF NOT EXISTS exhibitions (
    e_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    s_id BIGINT NOT NULL REFERENCES museum.staff(s_id),
    l_id BIGINT NOT NULL REFERENCES museum.locations(l_id),
    e_name VARCHAR(255) NOT NULL,
    e_start_date DATE NOT NULL,
    e_end_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS donations (
    d_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    d_name VARCHAR(255) NOT NULL,
    d_donation_date DATE NOT NULL,
    d_donation_type VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS artifacts_exhibitions (
    ae_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    e_id BIGINT NOT NULL REFERENCES museum.exhibitions(e_id),
    a_id BIGINT NOT NULL REFERENCES museum.artifacts(a_id)
);

CREATE TABLE IF NOT EXISTS donations_artifacts (
    da_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    a_id BIGINT NOT NULL REFERENCES museum.artifacts(a_id),
    d_id BIGINT NOT NULL REFERENCES museum.donations(d_id)
);

CREATE TABLE IF NOT EXISTS visitors_exhibitions (
    ve_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    e_id BIGINT NOT NULL REFERENCES museum.exhibitions(e_id),
    v_id BIGINT NOT NULL REFERENCES museum.visitors(v_id)
);

CREATE TABLE IF NOT EXISTS staff_exhibitions (
    se_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    s_id BIGINT NOT NULL REFERENCES museum.staff(s_id),
    e_id BIGINT NOT NULL REFERENCES museum.exhibitions(e_id)
);

ALTER TABLE museum.exhibitions 
ADD CONSTRAINT chk_exhibition_date_min 
CHECK (e_start_date >= '2024-01-01');

ALTER TABLE museum.payments 
ADD CONSTRAINT chk_payment_positive 
CHECK (p_amount > 0);

ALTER TABLE museum.artifacts 
ADD CONSTRAINT chk_artifact_condition_values 
CHECK (a_condition IN ('Excellent', 'Good', 'Fair', 'Poor', 'Fragile')); -- checking that conditions IS one OF these ones

ALTER TABLE museum.payments 
ADD CONSTRAINT chk_payment_method_values 
CHECK (p_method IN ('Credit Card', 'Cash','Mobile Payment')); -- checking that method IS one OF these ones

ALTER TABLE museum.exhibitions 
ADD CONSTRAINT chk_exhibition_end_after_start 
CHECK (e_end_date > e_start_date); --checking that the END date IS MORE than START date

ALTER TABLE museum.payments 
ALTER COLUMN p_date SET DEFAULT CURRENT_DATE; --payment date IS CURRENT date unless specified otherwise

ALTER TABLE museum.visitors 
ALTER COLUMN v_visiting_date SET DEFAULT CURRENT_DATE;

ALTER TABLE museum.staff
ADD CONSTRAINT unique_staff_email UNIQUE (s_mail);

ALTER TABLE museum.visitors
ADD CONSTRAINT unique_visitor_email UNIQUE (v_mail);


INSERT INTO museum.locations (l_name, l_floor) VALUES
('Egyptian Gallery', 1),
('Modern Gallery', 2),
('History Wing', 1),
('European Section', 3),
('Asian Gallery', 2),
('Special Hall', 1);

INSERT INTO museum.artifacts (a_name, a_origin, a_condition) VALUES
('Egyptian Coffin', 'Egypt', 'Excellent'),
('Chinese Vase', 'China', 'Good'),
('Renaissance Painting', 'Italy', 'Fair'),
('Ancient Greek Helm', 'Greece', 'Good'),
('Viking Sword', 'Sweden', 'Fair'),
('Mexican Ceremonial Mask', 'Mexico', 'Fragile'),
('Samurai Armor', 'Japan', 'Excellent');

INSERT INTO museum.staff (s_name, s_surname, s_mail, s_number) VALUES
('janri', 'Lolashvili', 'j.lolashvili@mail.com', '555515223'),
('ferran', 'Torres', 'f.torres@mail.com', '515525121'),
('mo', 'salah', 'm.salah@mail.com', '123555555'),
('lamine', 'yamal', 'l.yamal@mail.com', '513234123'),
('carlo', 'ancelotti', 'c.ancelotti@mail.com', '213455111'),
('khvicha', 'kvaratskhelia', 'kh.kvaratskhelia@mail.com', '111222333');

INSERT INTO museum.visitors (v_name, v_mail, v_visiting_date) VALUES
('giorgi', 'giorgi@email.com', '2025-02-15'),
('temo', 'temo@email.com', '2025-02-20'),
('alex', 'alex@email.com', '2025-03-01'),
('dato', 'dato@email.com', '2025-03-10'),
('luka', 'luka@email.com', '2025-03-15'),
('ani', 'ani@email.com', '2025-03-25');

--dynamically adding v_ids in payments table
INSERT INTO museum.payments (v_id, p_amount, p_method, p_date) VALUES
((SELECT v_id FROM museum.visitors WHERE v_name = 'giorgi'), 25, 'Credit Card', '2025-02-15'),
((SELECT v_id FROM museum.visitors WHERE v_name = 'temo'), 25, 'Cash', '2025-02-20'),
((SELECT v_id FROM museum.visitors WHERE v_name = 'alex'), 40, 'Mobile Payment', '2025-03-01'),
((SELECT v_id FROM museum.visitors WHERE v_name = 'dato'), 35, 'Mobile Payment', '2025-03-10'),
((SELECT v_id FROM museum.visitors WHERE v_name = 'luka'), 25, 'Credit Card', '2025-03-15'),
((SELECT v_id FROM museum.visitors WHERE v_name = 'ani'), 35, 'Mobile Payment', '2025-03-25');

--dynamically adding values here as well
INSERT INTO museum.exhibitions (s_id, l_id, e_name, e_start_date, e_end_date) VALUES
((SELECT s_id FROM museum.staff WHERE s_name = 'janri' AND s_surname = 'Lolashvili'),
 (SELECT l_id FROM museum.locations WHERE l_name = 'Egyptian Gallery'),
 'ancient egypt', '2025-02-01', '2025-04-30'),
((SELECT s_id FROM museum.staff WHERE s_name = 'ferran' AND s_surname = 'Torres'),
 (SELECT l_id FROM museum.locations WHERE l_name = 'Modern Gallery'),
 'modern art', '2025-02-15', '2025-05-15'),
((SELECT s_id FROM museum.staff WHERE s_name = 'mo' AND s_surname = 'salah'),
 (SELECT l_id FROM museum.locations WHERE l_name = 'History Wing'),
 'Dinosaurs', '2025-03-01', '2025-06-01'),
((SELECT s_id FROM museum.staff WHERE s_name = 'lamine' AND s_surname = 'yamal'),
 (SELECT l_id FROM museum.locations WHERE l_name = 'European Section'),
 'EU wonders', '2025-03-15', '2025-06-15'),
((SELECT s_id FROM museum.staff WHERE s_name = 'carlo' AND s_surname = 'ancelotti'),
 (SELECT l_id FROM museum.locations WHERE l_name = 'Asian Gallery'),
 'Silky road', '2025-04-01', '2025-07-01'),
((SELECT s_id FROM museum.staff WHERE s_name = 'khvicha' AND s_surname = 'kvaratskhelia'),
 (SELECT l_id FROM museum.locations WHERE l_name = 'Special Hall'),
 'first humans', '2025-04-15', '2025-07-15');

INSERT INTO museum.donations (d_name, d_donation_date, d_donation_type) VALUES
('abc Foundation', '2025-02-05', 'Financial'),
('stv Collection', '2025-02-25', 'Artifact'),
('pap Estate', '2025-03-10', 'Artifact'),
('brill fund', '2025-03-20', 'Financial'),
('stormwind Society', '2025-04-05', 'Artifact'),
('undercity club', '2025-04-15', 'Financial');

INSERT INTO museum.artifacts_exhibitions (e_id, a_id) VALUES
((SELECT e_id FROM museum.exhibitions WHERE e_name = 'ancient egypt'),
 (SELECT a_id FROM museum.artifacts WHERE a_name = 'Egyptian Coffin')),
((SELECT e_id FROM museum.exhibitions WHERE e_name = 'EU wonders'),
 (SELECT a_id FROM museum.artifacts WHERE a_name = 'Renaissance Painting')),
((SELECT e_id FROM museum.exhibitions WHERE e_name = 'Silky road'),
 (SELECT a_id FROM museum.artifacts WHERE a_name = 'Chinese Vase')),
((SELECT e_id FROM museum.exhibitions WHERE e_name = 'Dinosaurs'),
 (SELECT a_id FROM museum.artifacts WHERE a_name = 'Ancient Greek Helm')),
((SELECT e_id FROM museum.exhibitions WHERE e_name = 'first humans'),
 (SELECT a_id FROM museum.artifacts WHERE a_name = 'Samurai Armor')),
((SELECT e_id FROM museum.exhibitions WHERE e_name = 'modern art'),
 (SELECT a_id FROM museum.artifacts WHERE a_name = 'Renaissance Painting')),
((SELECT e_id FROM museum.exhibitions WHERE e_name = 'first humans'),
 (SELECT a_id FROM museum.artifacts WHERE a_name = 'Mexican Ceremonial Mask'));

INSERT INTO museum.donations_artifacts (a_id, d_id) VALUES
((SELECT a_id FROM museum.artifacts WHERE a_name = 'Egyptian Coffin'),
 (SELECT d_id FROM museum.donations WHERE d_name = 'stv Collection')),
((SELECT a_id FROM museum.artifacts WHERE a_name = 'Chinese Vase'),
 (SELECT d_id FROM museum.donations WHERE d_name = 'pap Estate')),
((SELECT a_id FROM museum.artifacts WHERE a_name = 'Ancient Greek Helm'),
 (SELECT d_id FROM museum.donations WHERE d_name = 'stormwind Society')),
((SELECT a_id FROM museum.artifacts WHERE a_name = 'Mexican Ceremonial Mask'),
 (SELECT d_id FROM museum.donations WHERE d_name = 'pap Estate')),
((SELECT a_id FROM museum.artifacts WHERE a_name = 'Samurai Armor'),
 (SELECT d_id FROM museum.donations WHERE d_name = 'stormwind Society'));

INSERT INTO museum.visitors_exhibitions (e_id, v_id) VALUES
((SELECT e_id FROM museum.exhibitions WHERE e_name = 'ancient egypt'),
 (SELECT v_id FROM museum.visitors WHERE v_name = 'giorgi')),
((SELECT e_id FROM museum.exhibitions WHERE e_name = 'modern art'),
 (SELECT v_id FROM museum.visitors WHERE v_name = 'temo')),
((SELECT e_id FROM museum.exhibitions WHERE e_name = 'ancient egypt'), 
 (SELECT v_id FROM museum.visitors WHERE v_name = 'alex')),
((SELECT e_id FROM museum.exhibitions WHERE e_name = 'Dinosaurs'),
 (SELECT v_id FROM museum.visitors WHERE v_name = 'dato')),
((SELECT e_id FROM museum.exhibitions WHERE e_name = 'EU wonders'),
 (SELECT v_id FROM museum.visitors WHERE v_name = 'luka')),
((SELECT e_id FROM museum.exhibitions WHERE e_name = 'Silky road'),
 (SELECT v_id FROM museum.visitors WHERE v_name = 'ani'));

INSERT INTO museum.staff_exhibitions (s_id, e_id) VALUES
((SELECT s_id FROM museum.staff WHERE s_name = 'janri' AND s_surname = 'Lolashvili'),
 (SELECT e_id FROM museum.exhibitions WHERE e_name = 'ancient egypt')),
((SELECT s_id FROM museum.staff WHERE s_name = 'janri' AND s_surname = 'Lolashvili'),
 (SELECT e_id FROM museum.exhibitions WHERE e_name = 'EU wonders')),
((SELECT s_id FROM museum.staff WHERE s_name = 'ferran' AND s_surname = 'Torres'),
 (SELECT e_id FROM museum.exhibitions WHERE e_name = 'modern art')),
((SELECT s_id FROM museum.staff WHERE s_name = 'mo' AND s_surname = 'salah'),
 (SELECT e_id FROM museum.exhibitions WHERE e_name = 'Dinosaurs')),
((SELECT s_id FROM museum.staff WHERE s_name = 'lamine' AND s_surname = 'yamal'),
 (SELECT e_id FROM museum.exhibitions WHERE e_name = 'Silky road')),
((SELECT s_id FROM museum.staff WHERE s_name = 'carlo' AND s_surname = 'ancelotti'),
 (SELECT e_id FROM museum.exhibitions WHERE e_name = 'first humans'));

--DROP FUNCTION change_artifacts_table(integer,character varying,text)

CREATE OR REPLACE FUNCTION change_artifacts_table( --this FUNCTION takes 3 inputs(rowid, column name and value to change it to) AND RETURNS void, it changes
    rowid_to_update INTEGER,					   --the exact cell that IS specified inside the INPUT parameters, value_to_insert works dynamically AND can
    column_to_update VARCHAR,					   --CHANGE ACCORDING TO the DATA TYPE OF the COLUMN TYPE (although value_to_insert has to be text type)
    value_to_insert TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS
$$
DECLARE --3 variables defined here defined
    dt VARCHAR; --this variable takes the data type value of input column
    is_castable BOOLEAN := FALSE; --boolean by default set to false, becomes true once checked that value to insert can be cast as appropriate data type
    cast_sql TEXT; --this variable saves the sql query that casts value into a data type
BEGIN
   
	--getting the data type from the column that i chose to update, afterwards saving it to dt variable
    SELECT data_type INTO dt 
    FROM information_schema.columns
    WHERE table_name = 'artifacts'
        AND table_schema = 'museum'
        AND column_name = column_to_update;

   
    BEGIN --creating a new code block here, this part casts value_to_insert to dt data type, sets is_castable boolean accordingly
        cast_sql := format('SELECT $1::%I', dt);
        EXECUTE cast_sql USING value_to_insert;
        is_castable := TRUE;
    EXCEPTION WHEN OTHERS THEN
        is_castable := FALSE;
    END;

    
    EXECUTE format(
		'UPDATE museum.artifacts SET %I = $1 WHERE a_id = $2', --here is the main part where the update is made into the table
		column_to_update									   --%i is placeholder for the column identifier, $1 and $2 is parameter placeholder
        )													   --for value_to_insert and row_to_update
    USING value_to_insert, row_to_update;


	RAISE NOTICE 'Row updated successfully.'; --printing successful message if succesful
   	
EXCEPTION		
	WHEN OTHERS THEN
		RAISE NOTICE 'Error occured.'; -- when error occurs this message is printed
	
END;
$$;


CREATE OR REPLACE FUNCTION add_to_payment( --adding the payment OF the visitor that already EXISTS IN the visitor table
	your_name VARCHAR(50),
	amount INT, 
	method_of_pay VARCHAR(50),
	date_of_pay DATE
)
RETURNS VOID
LANGUAGE plpgsql
AS
$$
DECLARE
	id INT; --declaring a variable to later store the id of the visitor whose record is being added
BEGIN
	IF method_of_pay NOT IN ('Credit Card', 'Cash','Mobile Payment') THEN
        RAISE EXCEPTION 'Invalid payment method: "%". Must be one of Credit Card, Cash, Mobile Payment', method_of_pay;
    END IF; --if the method of payment is incorrect the error is raised
	
	SELECT v_id INTO id -- selecting and storing visitor id into id where v_name is name that is input into the function
	FROM museum.visitors
	WHERE v_name = your_name
	LIMIT 1; -- limiting one record to return, doesnt matter for the user but matters for the database to reduce complexity and be consistent with the
			 -- returned value
	IF NOT FOUND THEN
        RAISE EXCEPTION 'No visitor found with the name "%".', your_name;
    END IF; -- if the name isn't found this error message is displayed
	
	INSERT INTO museum.payments(v_id, p_amount, p_method, p_date) 
	VALUES(id, amount, method_of_pay, date_of_pay) 
	ON CONFLICT DO NOTHING;

	RAISE NOTICE 'record successfully added'; --raising notice once the record is added successfully

END;
$$;

--Create a view that presents analytics for the most recently added quarter in your database.
--Ensure that the result excludes irrelevant fields such as surrogate keys and duplicate entries.

CREATE OR REPLACE VIEW last_quarter_analytics AS --getting the analytical measurements (sum, count, avg) FROM the LAST quarter
SELECT 
    SUM(p_amount) AS total_amount,
    COUNT(*) AS total_payments,
    AVG(p_amount) AS average_payment
FROM museum.payments
WHERE EXTRACT(QUARTER FROM CURRENT_DATE) = EXTRACT(QUARTER FROM p_date) --logic IS that the YEAR AND quarter extracted FROM the date this VIEW IS used on
AND 																	--and the records in the database should be the same
EXTRACT(YEAR FROM CURRENT_DATE) = EXTRACT(YEAR FROM p_date);

--Create a read-only role for the manager. This role should have permission to perform SELECT queries on the database tables,
--and also be able to log in. Please ensure that you adhere to best practices for database security when defining this role

CREATE ROLE manager WITH LOGIN PASSWORD '1234qwerty'; --creating manager ROLE WITH login privilege AND a password

GRANT USAGE ON SCHEMA museum TO manager; --granting USAGE OF the schema

GRANT SELECT ON ALL TABLES IN SCHEMA museum TO manager; --has READ ONLY privilege ON EVERY TABLE IN the museum SCHEMA;






