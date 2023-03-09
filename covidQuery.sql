-- Selecting initial data

Select location, date, total_cases, new_cases, total_deaths, population
From CovidProject..CovidDeaths
Where continent is not null
order by 1,2


-- Comparing Total Cases to Total Deaths

Select location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as deathRate
From CovidProject..CovidDeaths
where continent is not null
order by 1,2


-- Comparing Total Cases to Population

Select location, date, population, total_cases, (total_cases/population)*100 as infectionRate
From CovidProject..CovidDeaths
where continent is not null
order by 1,2


-- Analyzing Countries with Highest Peak Infection Spread (Reproduction) Rates

Select location, 
	   population, 
	   MAX(reproduction_rate) as peakReproduction, 
	   MAX((total_cases/population))*100 as peakInfectionRate,
	   peakReprDate = CAST(RIGHT(MAX(FORMAT(CAST([reproduction_rate] AS DECIMAL(10, 0)), '0000000000')
                                    + FORMAT([date], 'yyyy-MM-dd')), 10) AS DATE)
From CovidProject..CovidDeaths
where continent is not null
Group by location, population
order by peakReproduction desc


-- Analyzing Countries with Highest Peak Death Rates (per population)

Select location, 
	   population,
	   MAX(CAST(total_deaths as int)) as peakDeathCount, 
	   MAX((total_deaths/population))*100 as peakDeathRate
From CovidProject..CovidDeaths
Where continent is not null
Group by location, population
order by peakDeathRate desc

-- Highest Death Count by Continent

Select continent,
	   MAX(CAST(total_deaths as int)) as peakDeathCount 
From CovidProject..CovidDeaths
Where continent is not null
Group by continent
order by peakDeathCount desc

-- Global Figures

Select date, 
	   SUM(new_cases) as totalNewCases, 
	   SUM(CAST(new_deaths as int)) as totalNewDeaths, 
	   100 * SUM(CAST(new_deaths as int))/SUM(new_cases) as deathRate
From CovidProject..CovidDeaths
where continent is not null
Group by date
order by date asc


-- Analyzing Total Population compared to Vaccincations (using CTE)

With popVsVac (continent, location, date, population, new_vaccinations, cumulVaccination)
as
(
Select cdea.continent, 
	   cdea.location, 
	   cdea.date, 
	   cdea.population, 
	   cvac.new_vaccinations, 
	   SUM(CAST(cvac.new_vaccinations as int)) over (partition by cdea.location 
													 order by cdea.location, cdea.date) as cumulVaccination
From CovidProject..CovidDeaths as cdea
Join CovidProject..CovidVaccinations as cvac
	on cdea.location = cvac.location
	and cdea.date = cvac.date
where cdea.continent is not null
)
Select *, (cumulVaccination/population)*100 as proportionVaccinated
From popVsVac

-- CREATE VIEWS FOR TABLEAU VIZ

-- Proportion Vaccinated (with rolling count)

Create View proportionVaccinated as
With popVsVac (continent, location, date, population, new_vaccinations, cumulVaccination)
as
(
Select cdea.continent, 
	   cdea.location, 
	   cdea.date, 
	   cdea.population, 
	   cvac.new_vaccinations, 
	   SUM(CAST(cvac.new_vaccinations as int)) over (partition by cdea.location 
													 order by cdea.location, cdea.date) as cumulVaccination
From CovidProject..CovidDeaths as cdea
Join CovidProject..CovidVaccinations as cvac
	on cdea.location = cvac.location
	and cdea.date = cvac.date
where cdea.continent is not null
)
Select *, (cumulVaccination/population)*100 as proportionVaccinated
From popVsVac


-- Peak Reproduction Rate (Countries)
Create View peakReproduction as
Select location, 
	   population, 
	   MAX(reproduction_rate) as peakReproduction, 
	   MAX((total_cases/population))*100 as peakInfectionRate,
	   peakReprDate = CAST(RIGHT(MAX(FORMAT(CAST([reproduction_rate] AS DECIMAL(10, 0)), '0000000000')
                                    + FORMAT([date], 'yyyy-MM-dd')), 10) AS DATE)
From CovidProject..CovidDeaths
where continent is not null
Group by location, population


-- Highest Peak Death Rate (Countries)
Create View peakDeaths as
Select location, 
	   population,
	   MAX(CAST(total_deaths as int)) as peakDeathCount, 
	   MAX((total_deaths/population))*100 as peakDeathRate
From CovidProject..CovidDeaths
Where continent is not null
Group by location, population


-- Global Totals
Create View globalTotals as
Select date, 
	   SUM(new_cases) as totalNewCases, 
	   SUM(CAST(new_deaths as int)) as totalNewDeaths, 
	   100 * SUM(CAST(new_deaths as int))/SUM(new_cases) as deathRate
From CovidProject..CovidDeaths
where continent is not null
Group by date


-- Total Infection Rates (Countries)
Create View totalInfections as
Select location, 
	   population,
	   MAX(total_cases) as peakCaseCount, 
	   MAX((total_cases/population))*100 as peakInfectionRate
From CovidProject..CovidDeaths
Where continent is not null
Group by location, population