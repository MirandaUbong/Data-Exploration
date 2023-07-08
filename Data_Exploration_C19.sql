--SELECTING THE DATA 

select location, date, total_cases, new_cases, total_deaths, population
from dbo.CovidDeaths
where continent is not null
order by 1,2


--TOTAL CASES VS. TOTAL DEATHS (by Location)

select location, date, total_cases, total_deaths,
(try_convert(decimal(18,2),total_deaths)/try_convert(decimal(18,2),total_cases))*100 as DeathPercentage
from dbo.CovidDeaths
where continent is not null
order by 1,2

select location, date, total_cases, total_deaths,
(try_convert(decimal(18,2),total_deaths)/try_convert(decimal(18,2),total_cases))*100 as DeathPercentage
from dbo.CovidDeaths
where continent is not null and location like '%Nigeria%'
order by 1,2


--TOTAL CASES VS. POPULATION (by Location)

select location, date, total_cases, population,
(try_convert(decimal(18,2),total_cases)/try_convert(decimal(18,2),population))*100 as InfectedPopulationPercentage
from dbo.CovidDeaths
where continent is not null
order by 1,2


--COUNTRIES WITH HIGHEST INFECTION RATE VS. POPULATION (by Location)

select location, max(total_cases) as HighestInfectionCount, population,
(max(try_convert(decimal(18,2),total_cases)/try_convert(decimal(18,2),population)))*100 as InfectedPopulationPercentage
from dbo.CovidDeaths
where continent is not null
group by location, population
order by InfectedPopulationPercentage desc


--COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION (by Location)

select location, max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc

select location, max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths
where continent is null
group by location
order by TotalDeathCount desc


--CONTINENT WITH HIGHEST DEATH COUNT PER POPULATION

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from dbo.CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc


--GLOBAL FIGURES

select date, total_cases, total_deaths,
(try_convert(decimal(18,2),total_deaths)/try_convert(decimal(18,2),total_cases))*100 as DeathPercentage
from dbo.CovidDeaths
where continent is not null
order by 1,2

select date, sum(new_cases)
from dbo.CovidDeaths
where continent is not null
group by date
order by 1,2

select date, sum(new_cases) as TotalNewcases, sum(new_deaths) as TotalNewDeaths,
(sum(new_deaths)/sum(nullif(new_cases,0)))*100 as DeathToNewCasePercentage
from dbo.CovidDeaths
where continent is not null
group by date
order by 1,2


select date, sum(new_cases) as TotalNewcases, sum(new_deaths) as TotalNewDeaths,
isnull((sum(new_deaths)/sum(nullif(new_cases,0))),0)*100 as DeathToNewCasePercentage
from dbo.CovidDeaths
where continent is not null
group by date
order by 1,2

select sum(new_cases) as TotalNewcases, sum(new_deaths) as TotalNewDeaths,
isnull((sum(new_deaths)/sum(nullif(new_cases,0))),0)*100 as DeathToNewCasePercentage
from dbo.CovidDeaths
where continent is not null
order by 1,2


--JOINING BOTH COVID DEATHS AND VACCINATIONS TABLES

select *
from dbo.CovidDeaths as CD
join dbo.CovidVaccinations as CV
on CD.location = CV.location and CD.date = CV.date 


--TOTAL POPULATION VS. VACCINATIONS

select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
from dbo.CovidDeaths as CD
join dbo.CovidVaccinations as CV
on CD.location = CV.location and CD.date = CV.date
where CD.continent is not null
order by 2,3


--ROLLING SUM

select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, sum(nullif(try_convert(bigint,new_vaccinations),0)) over(partition by CD.location order by CD.location, CD.date) as RollingSumOfVaccinations
from dbo.CovidDeaths as CD
join dbo.CovidVaccinations as CV
on CD.location = CV.location and CD.date = CV.date
where CD.continent is not null
group by  CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
order by 2,3


--USING A CTE

With PopulationvsVaccinations as
(
select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, sum(nullif(try_convert(bigint,new_vaccinations),0)) over(partition by CD.location order by CD.location, CD.date) as RollingSumOfVaccinations
from dbo.CovidDeaths as CD
join dbo.CovidVaccinations as CV
on CD.location = CV.location and CD.date = CV.date
where CD.continent is not null
group by  CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
)

select *, (RollingSumOfVaccinations/population)*100 as PercentageOfPopulationVaccinated
from PopulationvsVaccinations


--USING A TEMP TABLE

create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingSumOfVaccinations numeric
)


Insert into #PercentPopulationVaccinated

select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, sum(nullif(try_convert(bigint,new_vaccinations),0)) over(partition by CD.location order by CD.location, CD.date) as RollingSumOfVaccinations
from dbo.CovidDeaths as CD
join dbo.CovidVaccinations as CV
on CD.location = CV.location and CD.date = CV.date
where CD.continent is not null
group by  CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations

select *, (RollingSumOfVaccinations/population)*100 as PercentageOfPopulationVaccinated
from #PercentPopulationVaccinated


drop table if exists #PercentPopulationVaccinated

create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingSumOfVaccinations numeric
)


Insert into #PercentPopulationVaccinated

select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, sum(nullif(try_convert(bigint,new_vaccinations),0)) over(partition by CD.location order by CD.location, CD.date) as RollingSumOfVaccinations
from dbo.CovidDeaths as CD
join dbo.CovidVaccinations as CV
on CD.location = CV.location and CD.date = CV.date
group by  CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations

select *, (RollingSumOfVaccinations/population)*100 as PercentageOfPopulationVaccinated
from #PercentPopulationVaccinated
go


--CREATING VIEWS FOR DATA STORAGE FOR VISUALISATION

create view ViewPopulationvsVaccinations as

select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, sum(nullif(try_convert(bigint,new_vaccinations),0)) over(partition by CD.location order by CD.location, CD.date) as RollingSumOfVaccinations
from dbo.CovidDeaths as CD
join dbo.CovidVaccinations as CV
on CD.location = CV.location and CD.date = CV.date
where CD.continent is not null
group by  CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
go
select *
from ViewPopulationvsVaccinations


