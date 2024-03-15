

--If there were NULLs in the dataset that you want to always exclude, add below e.g. if continent column was the issue:
--where continent is not null

--If a datatype is incorrect, change it to a new one by using:
--cast(new_deaths as int)

-- % of cases which led to death by country
SELECT
    location,
    MAX(total_cases) as total_cases,
    MAX(total_deaths) as total_deaths, 
    (CONVERT(float, MAX(total_deaths)) / NULLIF(CONVERT(float, MAX(total_cases)), 0)) * 100 AS Deathpercentage
FROM PortfolioProject..GlobalCovidDeaths
GROUP BY location
ORDER BY 2 DESC;

-- % of cases which led to death by continent
SELECT
    continent,
    MAX(total_cases) as total_cases,
    MAX(total_deaths) as total_deaths, 
    (CONVERT(float, MAX(total_deaths)) / NULLIF(CONVERT(float, MAX(total_cases)), 0)) * 100 AS Deathpercentage
FROM PortfolioProject..GlobalCovidDeaths
GROUP BY continent
ORDER BY 2 DESC;

-- Max % of population who had Covid and who died by country
SELECT
    location,
    population,
    MAX(total_cases) as total_cases,
    MAX(total_deaths) as total_deaths, 
	(CONVERT(float, MAX(total_cases)) / population) * 100 AS case_percentage,
    (CONVERT(float, MAX(total_deaths)) / population) * 100 AS death_percentage,
	((CONVERT(float, MAX(total_cases)) / population) * 100 - (CONVERT(float, MAX(total_deaths)) / population) * 100) as case_vs_death_var
FROM PortfolioProject..GlobalCovidDeaths
GROUP BY location, population
ORDER BY 2 DESC;

-- Max % of population who had Covid and who died by continent
SELECT
    continent,
    SUM(CAST(population AS BIGINT)) AS total_population,
	SUM(new_deaths) as total_new_deaths,
	SUM(new_cases) as total_new_cases,
	(SUM(ISNULL(new_cases, 0)) / NULLIF(SUM(CAST(population AS FLOAT)), 0)) * 100 AS case_percentage,
	(SUM(ISNULL(new_deaths, 0)) / NULLIF(SUM(CAST(population AS FLOAT)), 0)) * 100 AS death_percentage
FROM
	(SELECT DISTINCT continent,
	population,
	new_deaths,
	new_cases
    FROM PortfolioProject..GlobalCovidDeaths) AS subquery
GROUP BY continent
ORDER BY 2 DESC;


-- Join the two tables together and create a running total of new vaccinations, plus % of population vaccinated
-- Creating a CTE- no. of columns in CTE must match no. of columns in query

WITH PopVSVac AS (
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS running_total_vaccinations
    FROM PortfolioProject..GlobalCovidDeaths dea
    JOIN PortfolioProject..GlobalCovidVaccinations vac ON dea.LOCATION = vac.LOCATION AND TRY_CONVERT(DATE, dea.DATE) = TRY_CONVERT(DATE, vac.DATE)
)
SELECT
    *,
    running_total_vaccinations / (CONVERT(FLOAT, population)) * 100 AS vaccinated_population_percentage
FROM PopVSVac;

--% vaccinated by country
--Start from 1hr7

--Creating vaccination temp table
--Good idea to add DROP TABLE IF EXISTS followed by the name of the table before you create a table sos you can make changes

DROP TABLE IF EXISTS #PercentagePopulationVaccinated
Create Table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date date,
Population numeric,
New_Vaccinations varchar(50),
running_total_vaccinations numeric,
)

Insert into #PercentagePopulationVaccinated
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS running_total_vaccinations
    FROM PortfolioProject..GlobalCovidDeaths dea
    JOIN PortfolioProject..GlobalCovidVaccinations vac ON dea.LOCATION = vac.LOCATION AND TRY_CONVERT(DATE, dea.DATE) = TRY_CONVERT(DATE, vac.DATE)

SELECT
    *,
    running_total_vaccinations / (CONVERT(FLOAT, population)) * 100 AS vaccinated_population_percentage
FROM #PercentagePopulationVaccinated;


--Creating view to store data ready for visualisations (views are permament, unlike temp table and can be queried from)

Create View PercentagePopulationVaccinated as
SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS running_total_vaccinations
    FROM PortfolioProject..GlobalCovidDeaths dea
    JOIN PortfolioProject..GlobalCovidVaccinations vac ON dea.LOCATION = vac.LOCATION AND TRY_CONVERT(DATE, dea.DATE) = TRY_CONVERT(DATE, vac.DATE)





