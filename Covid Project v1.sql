
/*
Exploration of Covid 19 data 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types, Nested Queries
*/


-- Observing the data

SELECT
	*
FROM
	portfolio_project.covid_deaths
ORDER BY
	3,4
	
	
-- Convert Date to date format

UPDATE portfolio_project.covid_deaths SET date = STR_TO_DATE(date, '%c/%e/%y')

ALTER TABLE covid_deaths CHANGE COLUMN `date` `date` DATE


UPDATE portfolio_project.covid_vaccinations SET date = STR_TO_DATE(date, '%c/%e/%y')

ALTER TABLE covid_vaccinations CHANGE COLUMN `date` `date` DATE


-- Update empty continent values to be NULL

UPDATE
	portfolio_project.covid_deaths
SET
	continent = NULL
WHERE
	LENGTH(continent) = 0

	
UPDATE
	portfolio_project.covid_vaccinations 
SET
	continent = NULL
WHERE
	LENGTH(continent) = 0


-- Select data to initial explorarion
	
SELECT
	location, `date`, total_cases, new_cases, total_deaths, population
FROM
	portfolio_project.covid_deaths
WHERE continent 
	IS NOT NULL
ORDER BY 
	1,2
	
	
-- Total Cases vs Total Deaths
-- Represent chances of dying from covid in a country (example: Russia)
	
SELECT 
	location, date, total_cases, total_deaths, 
	(total_deaths/total_cases)*100 as death_percentage
FROM 
	covid_deaths 
WHERE 
	location LIKE '%Russia%' and continent IS NOT NULL 
ORDER BY 
	1,2


-- Total Cases vs Population
-- Shows percentage of population which got Covid (example: Russia)
	
SELECT 
	location, date, total_cases, population, 
	(total_cases/population)*100 as percent_population_infected
FROM 
	covid_deaths 
WHERE 
	location LIKE '%Russia%'
ORDER BY 
	1,2


-- Countries with Highest Infection Rate compared to Population

SELECT
	location, population, MAX(total_cases) as highest_infection_rate, 
	MAX((total_cases/population))*100 as percent_population_infected
FROM
	covid_deaths 
GROUP BY
	location, population
ORDER BY percent_population_infected DESC

	
-- Countries with Highest Death Count per Population

SELECT 
	location, MAX(total_deaths) as total_deaths 
FROM 
	covid_deaths 
WHERE 
	continent IS NOT NULL 
GROUP BY
	location
ORDER BY 
	total_deaths DESC


-- Look at Deaths by Continent
-- Countinents with Highest Death Count per Population

SELECT
	continent, SUM(total_deaths) as total_death_continent
FROM
	(
	SELECT
		location, continent, MAX(total_deaths) as total_deaths
	FROM
		covid_deaths
	WHERE
		continent IS NOT NULL
	GROUP BY
		location, continent ) as max_death_location
GROUP BY
	continent
ORDER BY
	total_death_continent DESC
	

-- Global summary statistics by date
	
SELECT 
	date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
	SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
FROM 
	covid_deaths 
WHERE 
	continent IS NOT NULL
GROUP BY 
	date 
ORDER BY 
	1,2
	

-- Global statistics
	
SELECT 
	SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
	SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
FROM 
	covid_deaths 
WHERE 
	continent IS NOT NULL
-- GROUP BY 
-- 	date 
ORDER BY 
	1,2
	

-- Total Population vs Vaccinations
-- Calculate running total of people vaccinated
	
SELECT
	cd.continent, cd.location, cd.`date`, cd.population, cv.new_vaccinations,
	SUM(cv.new_vaccinations) OVER (PARTITION BY location ORDER BY location, `date`) as running_people_vaccinated_total
	-- (running_people_vaccinated_total/cv.population)*100 as vacinated_percentage
FROM
	covid_deaths cd JOIN covid_vaccinations cv 
	ON cd.location = cv.location 
	AND cd.`date` = cv.`date` 
WHERE 
	cd.continent IS NOT NULL
ORDER BY 
	2,3
	

-- Use CTE to perform calculation on Partition By in previous query

With population_vaccination 
(continent, location, `date`, population, new_vaccinations, running_people_vaccinated_total)
AS 
(
SELECT
	cd.continent, cd.location, cd.`date`, cd.population, cv.new_vaccinations,
	SUM(cv.new_vaccinations) OVER (PARTITION BY location ORDER BY location, `date`) as running_people_vaccinated_total
	-- (running_people_vaccinated_total/cv.population)*100 as vacinated_percentage
FROM
	covid_deaths cd JOIN covid_vaccinations cv 
	ON cd.location = cv.location 
	AND cd.`date` = cv.`date` 
WHERE 
	cd.continent IS NOT NULL
)
SELECT 
	*, running_people_vaccinated_total/population *100 as vaccinated_percantage
FROM 
	population_vaccination
	

-- Creating tempt table to perform calculation on partition by in previous query
-- Total percentage of people vaccinated per country
	
DROP TEMPORARY TABLE if exists population_vaccination

CREATE TEMPORARY TABLE population_vaccination
(
continent VARCHAR(255),
location VARCHAR(255),
population BIGINT,
new_vaccinations INT,
running_people_vaccinated_total REAL
)

INSERT INTO population_vaccination
SELECT
	cd.continent, cd.location, cd.population, cv.new_vaccinations,
	SUM(cv.new_vaccinations) OVER (PARTITION BY location ORDER BY location) as running_people_vaccinated_total
FROM
	covid_deaths cd JOIN covid_vaccinations cv 
	ON cd.location = cv.location 
	AND cd.`date` = cv.`date` 
WHERE 
	cd.continent IS NOT NULL
	
SELECT 
	continent, location, population,running_people_vaccinated_total, 
	(running_people_vaccinated_total / population) * 100 as total_vaccinated_percentage
FROM 
	population_vaccination
GROUP BY 
	continent, location, population,running_people_vaccinated_total


-- Creating view to store data for future visualizations

CREATE OR REPLACE VIEW population_vaccination as
SELECT
	cd.continent, cd.location, cd.population, cv.new_vaccinations,
	SUM(cv.new_vaccinations) OVER (PARTITION BY location ORDER BY location) as running_people_vaccinated_total
FROM
	covid_deaths cd JOIN covid_vaccinations cv 
	ON cd.location = cv.location 
	AND cd.`date` = cv.`date` 
WHERE 
	cd.continent IS NOT NULL


CREATE OR REPLACE VIEW global_summary
SELECT 
	date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
	SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
FROM 
	covid_deaths 
WHERE 
	continent IS NOT NULL
GROUP BY 
	date 
ORDER BY 
	1,2
