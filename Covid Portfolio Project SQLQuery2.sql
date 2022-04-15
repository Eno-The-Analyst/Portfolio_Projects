SELECT *
 FROM PortfolioProject.dbo.CovidDeaths$
  WHERE continent is not null
   ORDER BY 3,4


 --SELECT *
 --FROM PortfolioProject.dbo.CovidVaccinations$
 --ORDER BY 3,4

 --Select Data that I am going to be using.

 SELECT Location, date, total_cases, new_cases, total_deaths, population 
  FROM PortfolioProject.dbo.CovidDeaths$
   WHERE continent is not null
    ORDER BY 1,2

--Looking at Total Cases vs Total Deaths.
--This query shows the likelihood of dying if you contract covid in Canada.

 SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
  FROM PortfolioProject.dbo.CovidDeaths$
   WHERE location like '%Canada%'
    And continent is not null
	ORDER BY 1,2

--Looking at Total Cases vs Population.
--Shows what percentage of the population got covid.

SELECT Location, date, population, total_cases, (total_cases/population)*100 AS Percent_Population_Infected
  FROM PortfolioProject.dbo.CovidDeaths$
   WHERE location like '%Canada%'
    And continent is not null
	ORDER BY 1,2

--Looking at Countries with Highest Infection Rate compared to Population.

SELECT Location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population))*100 AS Percent_Population_Infected
  FROM PortfolioProject.dbo.CovidDeaths$
   --WHERE location like '%Canada%'
       And continent is not null
     GROUP BY Location, population
      ORDER BY Percent_Population_Infected desc

--Showing Countries with the Highest Death Count per population.

SELECT Location, MAX(CAST(total_deaths AS int)) AS Total_death_Count 
  FROM PortfolioProject.dbo.CovidDeaths$
   --WHERE location like '%Canada%'
     WHERE continent is not null
      GROUP BY Location
       ORDER BY Total_death_Count desc


--Showing Continents with the Highest Death Count.

SELECT continent, MAX(CAST(total_deaths AS int)) AS Total_death_Count 
  FROM PortfolioProject.dbo.CovidDeaths$
     --WHERE continent is not null
      GROUP BY continent
       ORDER BY Total_death_Count desc

--Looking at the Global Numbers

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS Global_Death_Percentage
  FROM PortfolioProject.dbo.CovidDeaths$
 --WHERE location like '%Canada%'
   WHERE continent is not null
    GROUP BY date
	ORDER BY 1,2

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS Global_Death_Percentage
  FROM PortfolioProject.dbo.CovidDeaths$
 --WHERE location like '%Canada%'
   WHERE continent is not null
	ORDER BY 1,2

--Looking to join the Covid deaths table and Covid Vaccinations table.

SELECT *
 FROM PortfolioProject.dbo.CovidDeaths$ dea
  JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date

--Looking at Total Population vs Vaccinations.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
 FROM PortfolioProject.dbo.CovidDeaths$ dea
  JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--Looking at the Sum of new vaccinations partitioned by location/country.


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location)
 FROM PortfolioProject.dbo.CovidDeaths$ dea
  JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--The CONVERT function works!

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location)
 FROM PortfolioProject.dbo.CovidDeaths$ dea
  JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) AS Rolling_People_Vaccinated
 FROM PortfolioProject.dbo.CovidDeaths$ dea
  JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--Using CTE 

WITH Pop_vs_Vac (continent, location, date, population, new_vaccinations, Rolling_People_Vaccinated)
 AS 
 (
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) AS Rolling_People_Vaccinated
 FROM PortfolioProject.dbo.CovidDeaths$ dea
  JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (Rolling_People_Vaccinated/population)*100 AS Percent_Vac
 FROM Pop_vs_Vac

--TEMP TABLE AND DROP TABLE

DROP table if exists #Percent_Population_Vaccinated
CREATE table #Percent_Population_Vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime, 
population numeric,
new_vaccinations numeric,
Rolling_People_Vaccinated numeric
)

INSERT into #Percent_Population_Vaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) AS Rolling_People_Vaccinated
 FROM PortfolioProject.dbo.CovidDeaths$ dea
  JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (Rolling_People_Vaccinated/population)*100 AS Percent_Vac
 FROM #Percent_Population_Vaccinated

--Creating view to store data for visualization.

Create View Percent_Population_Vaccinated as
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) AS Rolling_People_Vaccinated
 FROM PortfolioProject.dbo.CovidDeaths$ dea
  JOIN PortfolioProject.dbo.CovidVaccinations$ vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *
 FROM Percent_Population_Vaccinated