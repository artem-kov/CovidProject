
/*
Data for Tableau visualisations
 */

-- 1.
	
SELECT 
	 SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
	SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
FROM 
	covid_deaths 
WHERE 
	continent IS NOT NULL
-- GROUP BY 
	-- date 
ORDER BY 
	1,2
	

-- 2. 
	
SELECT
	continent, SUM(max_deaths) as total_death_count
FROM
	(
	SELECT
		location, continent, MAX(total_deaths) as max_deaths
	FROM
		covid_deaths
	WHERE
		continent IS NOT NULL
	GROUP BY
		location, continent ) as max_death_location
GROUP BY
	continent
ORDER BY
	total_death_count DESC
	
	
-- 3. 
-- Change NULL values to 0, for future visualization 

SELECT
	location, IFNULL(population, 0) as population, IFNULL(MAX(total_cases), 0) as highest_infection_rate, 
	IFNULL(MAX((total_cases/population))*100, 0) as percent_population_infected
FROM
	covid_deaths 
WHERE 
	continent IS NOT NULL
GROUP BY
	location, population
ORDER BY 
	percent_population_infected DESC


-- 4. 

SELECT 
	location, COALESCE(population, 0) as population, 
	`date`, COALESCE(MAX(total_cases), 0) as highest_infection_rate, 
	COALESCE(MAX((total_cases/population))*100, 0) as percent_population_infected
FROM 
	covid_deaths 
WHERE 
	continent IS NOT NULL	
GROUP BY
	location, population, date
ORDER BY 
	1,2
