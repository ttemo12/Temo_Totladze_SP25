INSERT INTO agency.education_information
(education_level, education_facility) VALUES
('high school','number 32 public school'),
('BA','ISET')
RETURNING *;

INSERT INTO agency.companies
(company_name, company_number, company_poc, company_email) VALUES
('ABC inc.', '521156', 'jerry', 'jerry@abc.com'),
('3 nabiji', '231451', 'sally', 'sally@3n.com')
ON CONFLICT (company_name) DO NOTHING
RETURNING *;

INSERT INTO agency.recruiter
(recruiter_name, recruiter_email, recruiter_number) VALUES
('stacy','stacy@abc.com', '111333'),
('lai', 'lai@aba.com','62314')
ON CONFLICT (recruiter_email) DO NOTHING --IF the email matches the another one already IN the TABLE it wont work
RETURNING *;

INSERT INTO agency.candidates
(education_info_id, candidate_name, candidate_surname, candidate_email, candidate_number) VALUES -- TO NOT hardcode the balue i use SELECT statements FROM now ON AND MATCH it WITH id FROM the TABLE it IS getting reference from
((SELECT education_info_id FROM agency.education_information WHERE education_level = 'high school' LIMIT 1), 'lisha', 'smith', 'lishas@mail.com', '912313'),
((SELECT education_info_id FROM agency.education_information WHERE education_level = 'BA' LIMIT 1), 'janri', 'lolashvili', 'jlo@mail.com', '551351')
ON CONFLICT (candidate_email) DO NOTHING --IF the email matches the another one already IN the TABLE it wont work
RETURNING *;

INSERT INTO agency.skills
(skill_name) VALUES
('python'),
('javascript')
ON CONFLICT (skill_name) DO NOTHING
RETURNING *;

INSERT INTO agency.jobs
(company_id, recruiter_id, job_descr, quantity_needed, job_location, salary) VALUES
((SELECT company_id FROM agency.companies WHERE company_name = 'ABC inc.' LIMIT 1),
 (SELECT recruiter_id FROM agency.recruiter WHERE recruiter_name = 'stacy' LIMIT 1),'wall painter', 2, 'Tbilisi, anapa 414', '5100'),
((SELECT company_id FROM agency.companies WHERE company_name = '3 nabiji' LIMIT 1),
 (SELECT recruiter_id FROM agency.recruiter WHERE recruiter_name = 'lai' LIMIT 1),'wall builder', 3, 'Tbilisi, anapa 414', '4700')
RETURNING *;

INSERT INTO agency.job_application
(candidate_id, job_id, application_date, application_cv_link) VALUES
((SELECT candidate_id FROM agency.candidates WHERE candidate_email = 'lishas@mail.com' LIMIT 1),
 (SELECT job_id FROM agency.jobs WHERE job_descr = 'wall painter' LIMIT 1),'2025-04-01', 'url.com/aE5g'),
((SELECT candidate_id FROM agency.candidates WHERE candidate_email = 'jlo@mail.com' LIMIT 1),
 (SELECT job_id FROM agency.jobs WHERE job_descr = 'wall builder' LIMIT 1),'2025-04-02', 'url.com/h1y4')
RETURNING *;

INSERT INTO agency.interviews_info
(job_application_id, recruiter_id, interview_date, interview_location, interview_type) VALUES
((SELECT job_application_id FROM agency.job_application 
  WHERE candidate_id = (SELECT candidate_id FROM agency.candidates WHERE candidate_email = 'lishas@mail.com' LIMIT 1) LIMIT 1),
 (SELECT recruiter_id FROM agency.recruiter WHERE recruiter_name = 'stacy' LIMIT 1),'2025-04-23', 'Tbilisi, vaja pshavela', 'basic'),
((SELECT job_application_id FROM agency.job_application 
  WHERE candidate_id = (SELECT candidate_id FROM agency.candidates WHERE candidate_email = 'jlo@mail.com' LIMIT 1) LIMIT 1),
 (SELECT recruiter_id FROM agency.recruiter WHERE recruiter_name = 'lai' LIMIT 1),
 '2025-06-13', 'Kutaisi, balakhvari', 'technical')
RETURNING *;

INSERT INTO agency.candidate_skill
(skill_id, candidate_id, candidate_year_of_exp, certification) VALUES
((SELECT skill_id FROM agency.skills WHERE skill_name = 'python' LIMIT 1),
 (SELECT candidate_id FROM agency.candidates WHERE candidate_email = 'jlo@mail.com' LIMIT 1),4, NULL),
((SELECT skill_id FROM agency.skills WHERE skill_name = 'python' LIMIT 1),
 (SELECT candidate_id FROM agency.candidates WHERE candidate_email = 'lishas@mail.com' LIMIT 1),
 2, 'object university')
RETURNING *;

INSERT INTO agency.job_skill
(job_id, skill_id, isRequired) VALUES
((SELECT job_id FROM agency.jobs WHERE job_descr = 'wall painter' LIMIT 1),
 (SELECT skill_id FROM agency.skills WHERE skill_name = 'python' LIMIT 1),TRUE),
((SELECT job_id FROM agency.jobs WHERE job_descr = 'wall builder' LIMIT 1),
 (SELECT skill_id FROM agency.skills WHERE skill_name = 'javascript' LIMIT 1),
 TRUE)
RETURNING *;

--adding record_ts column to each table 
ALTER TABLE agency.education_information 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE agency.companies 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE agency.recruiter 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE agency.candidates 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE agency.skills 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE agency.jobs 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE agency.job_application 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE agency.interviews_info 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE agency.candidate_skill 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE agency.job_skill 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

--i check that the count of total rows matches the count of rows in record_ts in each table so that i can be sure that records_ts has been populated correctly
SELECT 'education_information' as table_name, 
       count(*) as total_rows,
       count(CASE WHEN record_ts IS NOT NULL THEN 1 END) as rows_with_ts
FROM agency.education_information
UNION ALL
SELECT 'companies', count(*), count(CASE WHEN record_ts IS NOT NULL THEN 1 END)
FROM agency.companies
UNION ALL
SELECT 'recruiter', count(*), count(CASE WHEN record_ts IS NOT NULL THEN 1 END)
FROM agency.recruiter
UNION ALL
SELECT 'candidates', count(*), count(CASE WHEN record_ts IS NOT NULL THEN 1 END)
FROM agency.candidates
UNION ALL
SELECT 'skills', count(*), count(CASE WHEN record_ts IS NOT NULL THEN 1 END)
FROM agency.skills
UNION ALL
SELECT 'jobs', count(*), count(CASE WHEN record_ts IS NOT NULL THEN 1 END)
FROM agency.jobs
UNION ALL
SELECT 'job_application', count(*), count(CASE WHEN record_ts IS NOT NULL THEN 1 END)
FROM agency.job_application
UNION ALL
SELECT 'interviews_info', count(*), count(CASE WHEN record_ts IS NOT NULL THEN 1 END)
FROM agency.interviews_info
UNION ALL
SELECT 'candidate_skill', count(*), count(CASE WHEN record_ts IS NOT NULL THEN 1 END)
FROM agency.candidate_skill
UNION ALL
SELECT 'job_skill', count(*), count(CASE WHEN record_ts IS NOT NULL THEN 1 END)
FROM agency.job_skill;


CREATE DATABASE recruitment_agency;

CREATE SCHEMA agency;

CREATE TABLE IF NOT EXISTS companies (
    company_ID SERIAL PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL UNIQUE,
    company_number VARCHAR(20) NOT NULL UNIQUE, --use varchar FOR numbers but bigint IS ALSO okay
    company_POC VARCHAR(255),
    company_email VARCHAR(255) UNIQUE
);

CREATE TABLE IF NOT EXISTS recruiter (
    recruiter_ID SERIAL PRIMARY KEY,
    recruiter_name VARCHAR(20) NOT NULL,
    recruiter_email TEXT NOT NULL UNIQUE,
    recruiter_number VARCHAR(20) NOT NULL UNIQUE --IN production DATABASE there would be a CHECK CONSTRAINT for validity
);

CREATE TABLE IF NOT EXISTS  education_information (
    education_info_ID SERIAL PRIMARY KEY,
    education_level VARCHAR(50),
    education_facility VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS candidates (
    candidate_ID SERIAL PRIMARY KEY,
    education_info_ID BIGINT REFERENCES education_information(education_info_ID) ON DELETE CASCADE,
    candidate_name VARCHAR(20) NOT NULL,
    candidate_surname VARCHAR(20) NOT NULL,
    candidate_email TEXT NOT NULL UNIQUE, 
    candidate_number VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS skills (
    skill_ID SERIAL PRIMARY KEY,
    skill_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS candidate_skill (
    candidate_skill_ID SERIAL PRIMARY KEY,
    skill_ID BIGINT REFERENCES skills(skill_ID) ON DELETE CASCADE,
    candidate_ID BIGINT REFERENCES candidates(candidate_ID) ON DELETE CASCADE,
    candidate_year_of_exp INT CHECK (candidate_year_of_exp > 0), --adding >0 CONSTRAINT here AND wherever neccesary 
    certification VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS jobs (
    job_ID SERIAL PRIMARY KEY,
    company_ID BIGINT REFERENCES companies(company_ID) ON DELETE CASCADE,
    recruiter_ID BIGINT REFERENCES recruiter(recruiter_ID) ON DELETE CASCADE,
    job_descr TEXT NOT NULL,
    quantity_needed BIGINT NOT NULL DEFAULT 1,
    job_location VARCHAR(255),
    salary DECIMAL(10,2) CHECK (salary > 0),
    posting_date DATE NOT NULL DEFAULT CURRENT_DATE CHECK (posting_date > '2000-01-01'),
    closing_date DATE CHECK (closing_date > '2000-01-01'),
    isActive BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS job_skill (
    job_skill_ID SERIAL PRIMARY KEY, -- added this COLUMN it wasn't previously IN the diagram
    job_ID BIGINT REFERENCES jobs(job_ID) ON DELETE CASCADE,
    skill_ID BIGINT REFERENCES skills(skill_ID) ON DELETE CASCADE,
    isRequired BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS job_application (
    job_application_ID SERIAL PRIMARY KEY,
    candidate_ID BIGINT REFERENCES candidates(candidate_ID) ON DELETE CASCADE,
    job_ID BIGINT REFERENCES jobs(job_ID) ON DELETE CASCADE,
    application_date DATE NOT NULL DEFAULT CURRENT_DATE CHECK (application_date > '2000-01-01'),
    application_CV_link TEXT NOT NULL --i use TEXT FOR url but varchar IS ALSO okay
);

CREATE TABLE IF NOT EXISTS interviews_info (
    interview_ID SERIAL PRIMARY KEY,
    job_application_ID BIGINT REFERENCES job_application(job_application_ID) ON DELETE CASCADE,
    recruiter_ID BIGINT REFERENCES recruiter(recruiter_ID) ON DELETE CASCADE,
    interview_date DATE NOT NULL CHECK (order_date > '2000-01-01'),
    interview_location VARCHAR(255),
    interview_type VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS interview_feedback (
    feedback_ID SERIAL PRIMARY KEY,
    interview_ID BIGINT REFERENCES interviews_info(interview_ID) ON DELETE CASCADE,
    candidate_ID BIGINT REFERENCES candidates(candidate_ID) ON DELETE CASCADE,
    rating INT CHECK (rating > 0 AND rating < 100) NOT NULL,
    strengths VARCHAR(50),
    weaknesses VARCHAR(50)
);
