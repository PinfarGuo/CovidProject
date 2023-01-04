Select * 
From CovidPortfolioProject..CovidDeaths
Order by 3,4
;

Select * 
From CovidPortfolioProject..CovidVaccines
Order by 3,4
;

-- Select specific Data to be used
Select location, date, total_cases, new_cases, total_deaths, population
From CovidPortfolioProject..CovidDeaths
order by 1,2
;


-- Total Cases vs Total Deaths in US
-- showcase: simple math (percentage), alias, use of LIKE operator
Select location, date, total_cases, total_deaths, 
  (total_deaths/total_cases)*100 as DeathPercentage
From CovidPortfolioProject..CovidDeaths
Where location LIKE '%states%'
order by 1,2
;


-- Total Cases vs Population in US - percentage of population that got Covid
Select location, date, population, total_cases, 
  (total_cases/population)*100 as DeathPercentage
From CovidPortfolioProject..CovidDeaths
Where location LIKE '%states%'
order by 1,2
;


-- Countries with highest infection percentage
-- Showcase: use of MAX function, Group by statement
select location, population, 
  MAX(total_cases) as HighestInfectionCount,
  MAX(total_cases/population)*100 as PercentageInfected
from CovidPortfolioProject..CovidDeaths
Group by location, population
order by PercentageInfected desc
;


-- Countries with highest infection percentage over time
select location, population, date,
  MAX(total_cases) as HighestInfectionCount,
  MAX(total_cases/population)*100 as PercentageInfected
from CovidPortfolioProject..CovidDeaths
Group by location, population, date
order by PercentageInfected desc
;



-- Countries with highest death percentage
-- Showcase: CAST function to change data type
select location, 
  MAX(CAST (total_deaths as int)) as HighestDeathCount
From CovidPortfolioProject..CovidDeaths
Group by location
Order by HighestDeathCount desc
;

-- Note: location came up with weird results such as 'World', 'High income', 'Upper middle income', etc
-- Showcase: Distinct statement on location to view distinct values
Select Distinct location
From CovidPortfolioProject..CovidDeaths
;
-- confirmed that weird results are seen so need to look at base query to see what happen in table. Can see that weird results are shown when Continent column is null
Select Distinct continent, location
From CovidPortfolioProject..CovidDeaths
;

-- Adding continent column to query to show correct results
Select continent, location, 
  MAX(CAST (total_deaths as int)) as HighestDeathCount
From CovidPortfolioProject..CovidDeaths
Where continent IS NOT NULL
Group by continent, location
Order by 1,2
;
-- Results are showing correctly, confirmed by comparing values to google results.
-- This can be used for drill down in Tableau



-- Continents with highest death count
--Showcase: SUM function
Select continent,
  SUM (CAST (new_deaths as int)) as TotalDeathCount
From CovidPortfolioProject..CovidDeaths
Where continent IS NOT NULL
Group by continent
Order by TotalDeathCount desc
;


-- Global Numbers
Select SUM(new_cases) as TotalCases,
 SUM(CAST(new_deaths as int)) as TotalDeaths,
 SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From CovidPortfolioProject..CovidDeaths
Where continent IS NOT NULL
Order by 1,2
;


-- Total Population vs Vaccinations
-- Showcase: joining tables, using CONVERT instead of CAST, use of OVER PARTITION BY to get rolling count of vaccinations so far
Select cdea.continent, cdea.location, cdea.date, cdea.population, cvac.new_vaccinations,
 SUM(CONVERT(bigint, cvac.new_vaccinations)) OVER (PARTITION BY cdea.location Order by cdea.location, cdea.date) as RollingCountVaccinated
From CovidPortfolioProject..CovidDeaths cdea
 Join CovidPortfolioProject..CovidVaccines cvac
 on cdea.location = cvac.location
 and cdea.date = cvac.date
Where cdea.continent IS NOT NULL
Order by 2,3
;


-- Rolling count of vaccinated with percentage
Select cdea.continent, cdea.location, cdea.date, cdea.population, cvac.new_vaccinations,
 SUM(CONVERT(bigint, cvac.new_vaccinations)) OVER (PARTITION BY cdea.location Order by cdea.location, cdea.date) as RollingCountVaccinated,
 (SUM(CONVERT(bigint, cvac.new_vaccinations)) OVER (PARTITION BY cdea.location Order by cdea.location, cdea.date)/Population)*100 as TotalVacPercentage
From CovidPortfolioProject..CovidDeaths cdea
 Join CovidPortfolioProject..CovidVaccines cvac
 on cdea.location = cvac.location
 and cdea.date = cvac.date
Where cdea.continent IS NOT NULL
;

-- The above can be done using CTE and temp tables as well. With CTE and temp tables its easier to read because of separate queries
-- Showcase: CTE - Used to allow a newly created temp column as part of a query that needs to use the temp column as part of operator/function
with PopvsVac (Continent, Location, Date, Population, NewVaccinations, RollingCountVaccinated)
as
(
Select cdea.continent, cdea.location, cdea.date, cdea.population, cvac.new_vaccinations,
 SUM(CONVERT(bigint, cvac.new_vaccinations)) OVER (PARTITION BY cdea.location Order by cdea.location, cdea.date) as RollingCountVaccinated
From CovidPortfolioProject..CovidDeaths cdea
 Join CovidPortfolioProject..CovidVaccines cvac
 on cdea.location = cvac.location
 and cdea.date = cvac.date
Where cdea.continent IS NOT NULL
)
Select *, (RollingCountVaccinated/Population)*100 as TotalVacPercentage
From PopvsVac
Order by 1,2
;

--Showcase: Temp Table
Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
 Continent nvarchar(255),
 Location nvarchar(255),
 Date datetime,
 Population numeric,
 NewVaccination numeric,
 RollingCountVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select cdea.continent, cdea.location, cdea.date, cdea.population, cvac.new_vaccinations,
 SUM(CONVERT(bigint, cvac.new_vaccinations)) OVER (PARTITION BY cdea.location Order by cdea.location, cdea.date) as RollingCountVaccinated
From CovidPortfolioProject..CovidDeaths cdea
 Join CovidPortfolioProject..CovidVaccines cvac
 on cdea.location = cvac.location
 and cdea.date = cvac.date
;
Select *, (RollingCountVaccinated/Population)*100 as TotalVacPercentage
From #PercentPopulationVaccinated
Order by 1,2
;


-- create view
Create view PercentPopulationVaccinated as
Select cdea.continent, cdea.location, cdea.date, cdea.population, cvac.new_vaccinations,
 SUM(CONVERT(bigint, cvac.new_vaccinations)) OVER (PARTITION BY cdea.location Order by cdea.location, cdea.date) as RollingCountVaccinated
From CovidPortfolioProject..CovidDeaths cdea
 Join CovidPortfolioProject..CovidVaccines cvac
 on cdea.location = cvac.location
 and cdea.date = cvac.date
Where cdea.continent IS NOT NULL
;