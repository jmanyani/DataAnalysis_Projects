-- SQL Data Exploration on COVID-19 Dataset
-- This project analyzes COVID-19 data to gain insights into cases, deaths, and vaccination rates across different locations.

-- Importing data on COVID-19 cases and deaths to explore key metrics by location and date.
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM AnalystProject..covidDeaths
ORDER BY Location, date;

-- Analyzing Total Cases vs. Total Deaths to understand mortality rates.
SELECT Location, date, total_cases, total_deaths, 
       (total_deaths / total_cases) * 100 AS 'Death Percentage'
FROM AnalystProject..covidDeaths
WHERE Location LIKE '%states'
ORDER BY Location, date;

-- Investigating the spread of cases relative to the population.
SELECT Location, date, total_cases, population, 
       (total_cases / population) * 100 AS 'Percentage Cases'
FROM AnalystProject..covidDeaths
WHERE Location LIKE '%states'
ORDER BY Location, date;

-- Identifying countries with the highest infection rates compared to their populations.
SELECT location, 
       MAX(total_cases) AS total_cases, 
       population, 
       (MAX(total_cases) / population) * 100 AS 'Percentage Cases'
FROM AnalystProject..covidDeaths
GROUP BY location, population
ORDER BY 'Percentage Cases' DESC;

-- Analyzing countries with the highest death rates relative to population.
SELECT location, population, 
       MAX(total_deaths) AS total_deaths, 
       (MAX(total_deaths) / population) * 100 AS 'Death Percentage'
FROM AnalystProject..covidDeaths
GROUP BY location, population
ORDER BY 'Death Percentage' DESC;

-- Calculating the total death count for each country to see where mortality was highest.
SELECT location, 
       MAX(CAST(total_deaths AS INT)) AS 'Total Deaths'
FROM AnalystProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 'Total Deaths' DESC;

-- Calculating total death count by continent for a broader regional view.
SELECT continent, 
       MAX(CAST(total_deaths AS INT)) AS 'Total Deaths'
FROM AnalystProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 'Total Deaths' DESC;

-- Summarizing global cases and deaths over time to understand worldwide trends.
SELECT date, 
       SUM(CAST(new_cases AS INT)) AS 'Total Cases', 
       SUM(CAST(new_deaths AS INT)) AS 'Total Deaths'
FROM AnalystProject..covidDeaths
GROUP BY date
ORDER BY date;

-- Exploring the relationship between COVID-19 deaths and vaccinations using a JOIN on both datasets.
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
       SUM(CONVERT(INT, vaccinations.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS 'Rolling People Vaccinated'
FROM AnalystProject..covidDeaths deaths
JOIN AnalystProject..covidVaccinations vaccinations 
ON deaths.location = vaccinations.location AND deaths.date = vaccinations.date
WHERE deaths.continent IS NOT NULL;

-- Using a CTE to organize population versus vaccination data for easier manipulation and analysis.
WITH PopulationVsVaccination AS (
    SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
           SUM(CONVERT(INT, vaccinations.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS 'Rolling People Vaccinated'
    FROM AnalystProject..covidDeaths deaths
    JOIN AnalystProject..covidVaccinations vaccinations 
    ON deaths.location = vaccinations.location AND deaths.date = vaccinations.date
    WHERE deaths.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS 'Percent Vaccinated'
FROM PopulationVsVaccination;

-- Using a temporary table to calculate vaccination percentage over population by country.
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS 'Rolling People Vaccinated'
FROM AnalystProject..covidDeaths dea
JOIN AnalystProject..covidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date;

-- Selecting data with calculated percentage for further analysis.
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS 'Percent Vaccinated'
FROM #PercentPopulationVaccinated;

-- Creating a view to streamline analysis of vaccination data over time by country.
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS 'Rolling People Vaccinated'
FROM AnalystProject..covidDeaths dea
JOIN AnalystProject..covidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Querying the view to easily retrieve vaccination data by country.
SELECT * 
FROM PercentPopulationVaccinated;
