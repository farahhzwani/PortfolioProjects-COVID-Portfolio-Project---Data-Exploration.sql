/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

--SELECT *
--FROM CovidDeaths$
--ORDER BY 3,4

--SELECT *
--FROM CovidVaccination
--ORDER BY 3,4

SELECT location, date,total_cases, new_cases, total_deaths, population
FROM CovidDeaths$
ORDER BY 1,2

--CALCULATION -> Looking at total cases vs total death
-- Shows likelihood of dying if you contract covid in your country


SELECT location, date,total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths$
WHERE location='Malaysia'
ORDER BY 1,2

SELECT location, date,total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths$
WHERE location like '%Malaysia%'
ORDER BY 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
FROM CovidDeaths$
WHERE location like '%Malaysia%'
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population

SELECT location,population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM CovidDeaths$
--WHERE location like '%Malaysia%'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

SELECT location,population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM CovidDeaths$
--WHERE location like '%Malaysia%'
GROUP BY location, population
ORDER BY 4 DESC

-- Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) as totaldeathcount
FROM CovidDeaths$
WHERE continent is not null
GROUP BY location
ORDER BY totaldeathcount DESC

SELECT continent, MAX(cast(total_deaths as int)) as totaldeathcount
FROM CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY totaldeathcount DESC

SELECT location, MAX(cast(total_deaths as int)) as totaldeathcount
FROM CovidDeaths$
WHERE continent is null
GROUP BY location
ORDER BY totaldeathcount DESC

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) as totaldeathcount
FROM CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY totaldeathcount DESC

-- GLOBAL NUMBERS

SELECT continent, SUM(new_cases) as totalcases, SUM(CAST(new_deaths as int))as totaldeath, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as deathpercentage
FROM CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY deathpercentage DESC

SELECT date, SUM(new_cases) as totalcases, SUM(CAST(new_deaths as int))as totaldeath, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as deathpercentage
FROM CovidDeaths$
WHERE continent is not null
GROUP BY date
ORDER BY deathpercentage DESC

SELECT SUM(new_cases) as totalcases, SUM(CAST(new_deaths as int))as totaldeath, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as deathpercentage
FROM CovidDeaths$
WHERE continent is not null
ORDER BY deathpercentage DESC

SELECT continent, SUM(CAST(icu_patients as int)) as total_icu_submission, SUM(CAST(hosp_patients as int))as total_hosp_submission
FROM CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY total_hosp_submission DESC

SELECT location, SUM(CAST(icu_patients as int)) as total_icu_submission, SUM(CAST(hosp_patients as int))as total_hosp_submission
FROM CovidDeaths$
WHERE location like '%malaysia%' and location is not null
GROUP BY location

SELECT location, SUM(CAST(icu_patients as int)) as total_icu_submission
FROM CovidDeaths$
WHERE  icu_patients is not null and location like '%ireland%'
GROUP BY location


-- Total Population vs Vaccinations

SELECT*
FROM  CovidDeaths$ as death
JOIN CovidVaccination as vacc
on death.location=vacc.location
and death.date=vacc.date

SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations
FROM  CovidDeaths$ as death
JOIN CovidVaccination as vacc
on death.location=vacc.location
and death.date=vacc.date
where death.continent is not null and vacc.new_vaccinations is not null and death.location like '%malaysia%'
order by 2,3

SELECT death.continent, death.location, death.date, vacc.new_vaccinations,
SUM(CAST(vacc.new_vaccinations as int)) OVER (Partition By death.location ORDER BY death.location, death.date) as sumnewvaccinations
FROM  CovidDeaths$ as death
JOIN CovidVaccination as vacc
on death.location=vacc.location
and death.date=vacc.date
where death.continent is not null and death.location like '%canada%'
order by 2,3



-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT death.continent, death.location, death.date, vacc.new_vaccinations,
SUM(CAST(vacc.new_vaccinations as int)) OVER (Partition By death.location ORDER BY death.location, death.date) as sumnewvaccinations,
--(sumnewvaccinations/population)*100
FROM  CovidDeaths$ as death
JOIN CovidVaccination as vacc
on death.location=vacc.location
and death.date=vacc.date
--where death.continent is not null and death.location like '%canada%'
order by 2,3 

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopVSvacc (continent, location, date, new_vaccinations, population, sumnewvaccinations)
as
(SELECT death.continent, death.location, death.date, vacc.new_vaccinations, death.population,
SUM(CAST(vacc.new_vaccinations as int)) OVER (Partition By death.location ORDER BY death.location, death.date) as sumnewvaccinations
--(sumnewvaccinations/population)*100
FROM CovidDeaths$ as death
JOIN CovidVaccination as vacc
on death.location=vacc.location
and death.date=vacc.date
where death.continent is not null
--order by 2,3 
)
SELECT *, (sumnewvaccinations/Population)*100
FROM PopVSvacc

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
new_vaccination numeric,
population numeric,
sumnewvaccinations numeric,
)

Insert into #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, vacc.new_vaccinations, death.population,
SUM(CAST(vacc.new_vaccinations as int)) OVER (Partition By death.location ORDER BY death.location, death.date) as sumnewvaccinations
--(sumnewvaccinations/population)*100
FROM CovidDeaths$ as death
JOIN CovidVaccination as vacc
on death.location=vacc.location
and death.date=vacc.date
where death.continent is not null
--order by 2,3 

SELECT *, (sumnewvaccinations/Population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT death.continent, death.location, death.date, vacc.new_vaccinations, death.population,
SUM(CAST(vacc.new_vaccinations as int)) OVER (Partition By death.location ORDER BY death.location, death.date) as sumnewvaccinations
--(sumnewvaccinations/population)*100
FROM CovidDeaths$ as death
JOIN CovidVaccination as vacc
on death.location=vacc.location
and death.date=vacc.date
where death.continent is not null
--order by 2,3 