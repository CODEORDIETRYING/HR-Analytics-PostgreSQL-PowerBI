DROP TABLE IF EXISTS hr_new;
CREATE TABLE hr_new (
	id varchar,
	first_name varchar,
	last_name varchar,
	birthdate varchar,
	gender varchar,
	race varchar,
	department varchar,
	jobtitle varchar,
	location varchar,
	hire_date varchar,
	termdate varchar,
	location_city varchar,
	location_state varchar
);

-- Renaming the id column to emp_id
ALTER TABLE hr_new
RENAME COLUMN id TO emp_id

-- Cleaning the birthdate column
UPDATE hr_new
SET birthdate =	
	CASE WHEN birthdate LIKE '%/%' 
			THEN TO_DATE(birthdate, 'MM/DD/YYYY')
		WHEN birthdate LIKE '%-%' AND RIGHT(EXTRACT(YEAR FROM TO_DATE(birthdate, 'MM-DD-YY'))::varchar, 2)::int < 70
			THEN (TO_DATE(birthdate, 'MM-DD-YY') - INTERVAL '100 years')
		WHEN birthdate LIKE '%-%' AND RIGHT(EXTRACT(YEAR FROM TO_DATE(birthdate, 'MM-DD-YY'))::varchar, 2)::int >= 70
			THEN TO_DATE(birthdate, 'MM-DD-YY') 
	ELSE NULL END;
	
-- To change the birthdate data type
ALTER TABLE hr_new
ALTER COLUMN birthdate TYPE DATE
USING (birthdate::date)

-- Cleaning the hire_date column

UPDATE hr_new
SET hire_date =	
	CASE WHEN hire_date LIKE '%/%' 
			THEN TO_DATE(hire_date, 'MM/DD/YYYY')
		WHEN hire_date LIKE '%-%' 
			THEN TO_DATE(hire_date, 'MM-DD-YY') 
	ELSE NULL END;

-- To change the hire_date data type
ALTER TABLE hr_newate
ALTER COLUMN hire_date TYPE DATE
USING (hire_date::date)

-- To change the termdate data type
ALTER TABLE hr_new
ALTER COLUMN termdate TYPE DATE
USING (termdate::date)  

-- Creating an Age column
ALTER TABLE hr_new
ADD COLUMN age int;

UPDATE hr_new
SET Age = EXTRACT(YEAR FROM AGE(CURRENT_DATE,birthdate))

-- Excluding retired employees
SELECT * FROM hr_new
WHERE age < 65

-- ANALYSIS QUESTIONS --
-- 1. What is the gender breakdown of the employees in the company?
SELECT gender, 
	COUNT(*) as gender_distribution
FROM hr_new
WHERE age < 65 AND termdate is NULL --removing those above retiring age and those no longer in the company
GROUP BY gender;

-- 2. What is the race/ethnicity breakdown of employees in the company?
SELECT race, COUNT(*) as race_distribution
FROM hr_new
WHERE age < 65 AND termdate is NULL
GROUP BY race
ORDER BY COUNT(*) DESC;

-- 3. What is the age distribution of employees in the company?
SELECT 
	CASE 
		WHEN age >=18 AND age <= 24 THEN  '18-24'
		WHEN age >=25 AND age <= 34 THEN  '25-34'
		WHEN age >=35 AND age <= 44 THEN  '35-44'
		WHEN age >=45 AND age <= 54 THEN  '45-54'
		WHEN age >=55 AND age <= 64 THEN  '55-64'
		ELSE '65+'
	END AS age_group,
	COUNT(*) AS count
FROM hr_new
WHERE age < 65 AND termdate IS NULL
GROUP BY age_group
ORDER BY age_group;


SELECT 
	CASE 
		WHEN age >=18 AND age <= 24 THEN  '18-24'
		WHEN age >=25 AND age <= 34 THEN  '25-34'
		WHEN age >=35 AND age <= 44 THEN  '35-44'
		WHEN age >=45 AND age <= 54 THEN  '45-54'
		WHEN age >=55 AND age <= 64 THEN  '55-64'
		ELSE '65+'
	END AS age_group,
	gender,
	COUNT(*) AS count
FROM hr_new
WHERE age < 65 AND termdate IS NULL
GROUP BY age_group, gender
ORDER BY age_group, gender;

-- 4. How many employees work at Headquarters versus remote locations?
SELECT location, COUNT(*) AS count 
FROM hr_new
WHERE age < 65 AND termdate IS NULL
GROUP BY location;

-- 5. What is the average length of employment for employees who have been terminated?
SELECT DATE_TRUNC('months', AVG(AGE(termdate, hire_date))) AS avg_emp
FROM hr_new
WHERE age < 65 AND
		termdate <= CURRENT_DATE AND 
		termdate IS NOT NULL

-- 6a. How does the gender distribution vary across departments?
SELECT department,
		gender,
		COUNT(*) AS count
FROM hr_new
WHERE age < 65 AND termdate IS NULL
GROUP BY department, gender
ORDER BY department, gender;

-- 6b. How does the gender distribution vary across jobtitles?
SELECT jobtitle,
		gender,
		COUNT(*) AS count
FROM hr_new
WHERE age < 65 AND termdate IS NULL
GROUP BY jobtitle, gender
ORDER BY jobtitle, gender;

-- 7. What is the distribution of jobtitles across the company?
SELECT jobtitle,
		COUNT(*) AS count
FROM hr_new
WHERE age < 65 AND termdate IS NULL
GROUP BY jobtitle
ORDER BY jobtitle DESC;

-- 8. Which department as the highest turnover rate?
WITH turn_over_cte AS (
	SELECT department,
		COUNT(*) as total_count,
		SUM(CASE 	
				WHEN termdate IS NOT NULL AND termdate <= CURRENT_DATE
					THEN 1 ELSE 0 END) AS terminated_count
	FROM hr_new
	WHERE age < 65
	GROUP BY department
)
SELECT department,
		total_count,
		terminated_count,
		(terminated_count::NUMERIC/total_count::NUMERIC) AS turnover_rate
FROM turn_over_cte
ORDER BY turnover_rate DESC;

-- 9. What is the distribution of employees across locations by city and state?
SELECT location_state, COUNT(*) AS count
FROM hr_new
WHERE age < 65 AND termdate IS NULL
GROUP BY location_state
ORDER BY count DESC;

-- 10. How has the company's employee count changed over time based on hire and term dates?
SELECT 
	year,
	hires,
	terminations,
	(hires-terminations) AS net_change,
	ROUND((hires-terminations)/hires::NUMERIC*100, 2) AS net_change_percent 
FROM (
	SELECT EXTRACT(year FROM hire_date) as year,
			COUNT(*) as hires,
			SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURRENT_DATE
			   		THEN 1 ELSE 0 END) as terminations
	FROM hr_new
	WHERE age < 65 
	GROUP BY year
	ORDER BY year
) AS hire_term 

-- 11. What is the tenure distribution for each department.
SELECT department,
		DATE_TRUNC('month', AVG(AGE(termdate, hire_date))) AS avg_tenure
FROM hr_new
WHERE age < 65 AND 
	termdate IS NOT NULL AND 
	termdate <= CURRENT_DATE
GROUP BY department
ORDER BY avg_tenure