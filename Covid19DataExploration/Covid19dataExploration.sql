
select * from PortfolioProject..CovidDeath
where continent is not NULL
order by 3,4

-- Select data to start with
select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeath
where continent is not NULL
order by 1,2

-- Total cases vs total deaths
-- Shows likelihood of dying if you contract covid in India
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from PortfolioProject..CovidDeath
where location = 'India' and continent is not NULL
order by 1,2

-- Total cases vs population
-- Shows what percentage of population in India infected with Covid
select location, date, total_cases, population, (total_cases/population)*100 as infection_percentage
from PortfolioProject..CovidDeath
where location = 'India' and continent is not NULL
order by 1,2

-- Countries with highest infection rate compared to population
select location, MAX(total_cases) as high_cases, population, MAX(total_cases/population)*100 as High_infection_percentage
from PortfolioProject..CovidDeath
where continent is not NULL
group by location,population
order by High_infection_percentage desc


-- Countries with Highest Death Count per Population
select location, MAX(cast(total_deaths as bigint)) as HighDeathCount
from PortfolioProject..CovidDeath
where continent is not NULL
group by location
order by HighDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population
select continent, MAX(cast(total_deaths as bigint)) as HighDeathCount
from PortfolioProject..CovidDeath
where continent is not NULL
group by continent
order by HighDeathCount desc

-- Global death numbers
select SUM(new_cases) as TotalCases,SUM(cast(new_deaths as bigint)) as TotalDeaths, SUM(cast(new_deaths as bigint))/SUM(new_cases)*100 as DeathPercent
from PortfolioProject..CovidDeath
where continent is not NULL
--group by date
order by 1,2 desc

-- Total Populations Vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, (SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.date,dea.location)) as CumilativePeopleVaccine
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccination vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not NULL
order by 2,3 

-- Using CTE to perform Calculation on Partition By in previous query

with popvsvac(continent,location,date,population,new_vaccinations,CumilativePeopleVaccine)
as
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, (SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.date,dea.location)) as CumilativePeopleVaccine
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccination vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not NULL
--order by 2,3 
)
select *, (CumilativePeopleVaccine/population)*100
from popvsvac

--Using Temp table Table to perform Calculation on Partition By in previous query
drop table if exists #PercentPopulationVaccinated 
Create table #PercentPopulationVaccinated
(continent nvarchar(255),
 location nvarchar(255),
 date datetime,
 population numeric,
 new_vaccinations numeric,
 CumilativePeopleVaccine numeric
)
insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, (SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.date,dea.location)) as CumilativePeopleVaccine
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccination vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not NULL

select *, (CumilativePeopleVaccine/population)*100 as PercentPopulationVaccinated
from #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

create view CumilativePopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, (SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.date,dea.location)) as CumilativePeopleVaccine
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccination vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not NULL
--order by 2,3 

select *
from CumilativePopulationVaccinated