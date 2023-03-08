-- this code is utilizing COVID data from 02/24/2020 - 02/02/2023

-- test code to see that the database has been added successfully
Select *
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4


Select Location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
From PortfolioProject..CovidDeaths
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- shows likelihood of dying if you contract covid in your country
Select Location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
-- WHERE location like '%states%'
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
Select Location, 
	date, 
	population, 
	total_cases,  
	(total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--WHERE location like '%states%'
order by 1,2


-- Looking at countries with highest infection rate compared to population
Select Location,  
	population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX((total_cases/population))*100 as PercentPopulationInfected,
	MAX(cast(total_deaths as int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
--WHERE location like '%states%'
Group BY Location, population
order by PercentPopulationInfected DESC

-- Showing countries with highest death count by population
Select Location, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
--WHERE location like '%states%'
Where continent is not null
Group BY Location
Order By TotalDeathCount desc


-- Let's break things down by continent (Incorrect)
Select continent, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
--WHERE location like '%states%'
Where continent is null
Group By continent
Order By TotalDeathCount desc


-- TOTAL DEATHS BY INCOME 
Select location, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
WHERE location like '%income%'
AND continent is null
Group By location
Order By TotalDeathCount desc


-- Let's break things down by continent correct
-- Showing continents with the highest death count per population
Select continent, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
--WHERE location like '%states%'
Where continent is not null
Group BY continent
Order By TotalDeathCount desc



-- GLOBAL NUMBERS

-- now that we added the sum of new cases/deaths we should see total death percentage globally 
Select  date, 
	Sum(new_cases) as total_cases, 
	SUM(cast(new_deaths as int))as total_deaths, 
	SUM(cast(new_deaths as int))/Sum(new_cases) *100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2

-- remove date to show total overall globally
Select Sum(new_cases) as total_cases, 
	SUM(cast(new_deaths as int))as total_deaths, 
	SUM(cast(new_deaths as int))/Sum(new_cases) *100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- Looking at Total Population vs Vaccinations

Select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location=vac.location 
	and dea.date = vac.date
	where dea.continent is not null
Order By 2, 3

Select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(Cast (vac.new_vaccinations as bigint)) OVER (Partition by dea.location ) AS RollingCount
-- note you can also use Convert(int, vac.new_vaccinations) to do the same int thing
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location=vac.location 
	and dea.date = vac.date
	--where dea.continent is not null
Order By 2, 3
-- the problem is that this above one just chunks all of the vacs together by location 
-- so we need to order by date and location to get it properly rolling

Select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM( Convert(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) AS RollingPeopleVaccinated
-- note you can also use Convert(int, vac.new_vaccinations) to do the same int thing
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location=vac.location 
	and dea.date = vac.date
--	where dea.continent is not null
Order By 2, 3


-- Looking at Total Population vs Vaccinations fr this time

Select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(Cast (vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) AS RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location=vac.location 
	and dea.date = vac.date
	where dea.continent is not null
Order By 2, 3

-- over here the attempt was to do MAX(RollingPeopleVaccinated/Population)*100
-- it doesn't work as RollingPeopleVaccinated was just created.
-- so there are two options:

-- option 1 - Use CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(Cast (vac.new_vaccinations as bigint)) 
	OVER (Partition by dea.location Order by dea.location, dea.date) AS RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location=vac.location 
	and dea.date = vac.date

)
-- test code
Select *,
	(RollingPeopleVaccinated/Population)*100 as PercentPopVaccinated
From PopvsVac

-- option 2 - TEMP TABLE

Drop Table if exists #PercentPopVaccinated
Create Table #PercentPopVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
New_vaccinations numeric, 
RollingPeopleVaccinated numeric
)

Insert into #PercentPopVaccinated
Select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	Sum(Convert(bigint, vac.new_vaccinations)) Over (Partition by dea.location order by dea.location, dea.date) as RollingPopulationVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

-- test code
Select *, 
	(RollingPeopleVaccinated/Population)*100 as PercentPopVaccinated
from #PercentPopVaccinated


-- CREATING A VIEW
-- Creating a view so I can create global population affected, and total global vaccinations percentage table
Use PortfolioProject
GO 
Create View PercentPopulationVaccinated as
Select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	dea.new_cases, 
	dea.new_deaths,
	Sum(Convert(bigint, vac.new_vaccinations)) Over (Partition by dea.location order by dea.location, dea.date) as RollingPopulationVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

-- test code to see if PercentPopulationVaccinated is working as a view
Select *
From PercentPopulationVaccinated

-- adding the overall percentage of vaccinations as a new column
Select *, 
	(RollingPopulationVaccinated/Population)*100 as PercentPopVaccinated
from PercentPopulationVaccinated


-- remove date to show total overall globally
Select Sum(ppv.new_cases) as total_cases, 
	SUM(cast(ppv.new_deaths as int))as total_deaths, 
	SUM(cast(ppv.new_deaths as int))/Sum(ppv.new_cases) *100 as DeathPercentage,
	Sum(Cast(ppv.new_vaccinations as bigint)) as totalVaccinations, 
	MAX(ppv.RollingPopulationVaccinated)/Max(ppv.population) *100  as PercentageVaccinated 
From PercentPopulationVaccinated as ppv
where continent is not null
-- note: this data came out wrong as it adds up all the vaccination cells and not the MAX for each country
-- the way around this was to add the location column, and group by location

-- CASES, DEATHS, VACCINATIONS, AND PERCENTAGES BY COUNTRY
Select location,
	Sum(ppv.new_cases) as total_cases, 
	SUM(cast(ppv.new_deaths as int))as total_deaths, 
	SUM(cast(ppv.new_deaths as int))/Sum(ppv.new_cases) *100 as DeathPercentage,
	Sum(Cast(ppv.new_vaccinations as bigint)) as totalVaccinations, 
	MAX(ppv.RollingPopulationVaccinated)/Max(ppv.population) *100  as PercentageVaccinated 
From PercentPopulationVaccinated as ppv
where continent is not null
group by location



-- GLOBAL PERCENTAGES BY CONTINENT
-- to get this result you group by the continent
Select continent, 
	Sum(new_cases) as total_cases, 
	SUM(cast(new_deaths as int))as total_deaths, 
	SUM(cast(new_deaths as int))/Sum(new_cases) *100 as DeathPercentage,
	Sum(Cast(ppv.new_vaccinations as bigint)) as totalVaccinations, 
	MAX(ppv.RollingPopulationVaccinated)/Max(ppv.population) *100  as PercentageVaccinated 
From PercentPopulationVaccinated ppv
where continent is not null
group by continent
order by 1,2