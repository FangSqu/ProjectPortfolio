

--OBJECTIVE: Looking at total Population vs Vaccinations 
--ADDING UP the newly vaccinated count as each date goes, like a ROLLING COUNT effect

-- Here, I return and join the relevant data 
SELECT death.location,  death.continent, death.date, death.population, vax.new_vaccinations
FROM COVID_Deaths as death
JOIN COVID_Vaccination as vax
On death.location = vax.location 
	and death.date = vax.date
WHERE vax.continent is not null
--NOTES
-- Duplicated 'DATE' Troubleshooting 
-- the WHERE statment is what give the duplication,
-- use WHERE 'vax.continent is not null' instead of 'death.continent'
-- ALSO make sure 'death.continent' is in SELECT Statement 
	


-- Circumvent with a Subquery to creat an adjested rolling count (RollingCountVAX_adj) where I devided in half. undo the double counting. 
SELECT location, continent, date, population, new_vaccinations, unadj.RollingCountVAX/2 as RollingCountVAX_adj
FROM (SELECT death.location,  death.continent, death.date, death.population, vax.new_vaccinations
	, SUM (CAST(vax.new_vaccinations as bigint)) OVER (PARTITION BY vax.location ORDER BY vax.date, vax.location) as RollingCountVAX
FROM COVID_Deaths as death
	JOIN COVID_Vaccination as vax On death.location = vax.location 
	and death.date = vax.date
WHERE vax.continent is not null) unadj
--NOTES
-- Apparently the PARTITION fuction duplicated the 'date' again with the ORDER BY Statement 
-- Duplicating the date mean it double counted the rolling count
-- DATA is still repeated to match with the date but at least is not double counting. 





--HERE is another version done with Temp Table (Should be Recomended than Subquery) 
SELECT death.location,  death.continent, death.date, death.population, vax.new_vaccinations
		, SUM (CAST(vax.new_vaccinations as bigint)) OVER (PARTITION BY vax.location ORDER BY vax.date, vax.location) as RollingCountVAX

INTO #temp_RollingVax_unadj

FROM COVID_Deaths as death
JOIN COVID_Vaccination as vax
On death.location = vax.location 
		and death.date = vax.date
WHERE vax.continent is not null

SELECT *, RollingCountVAX/2
FROM #temp_RollingVax_unadj
WHERE location = 'Canada'

--Use Canada to check if it works, Since it has earlier vaccination than other countries





--USE CTE (Common Table Expressions) 

With PopvsVax (location, continent, date, population, new_vaccinations, RollingCountVAX_adj)

AS
(
SELECT location, continent, date, population, new_vaccinations, unadj.RollingCountVAX/2 as RollingCountVAX_adj
FROM (SELECT death.location,  death.continent, death.date, death.population, vax.new_vaccinations
	, SUM (CAST(vax.new_vaccinations as bigint)) OVER (PARTITION BY vax.location ORDER BY vax.date, vax.location) as RollingCountVAX
FROM COVID_Deaths as death
	JOIN COVID_Vaccination as vax On death.location = vax.location 
	and death.date = vax.date
WHERE vax.continent is not null) unadj
)

-- Use the CTE just made to find the percentage of vax compared to population in proportion. 
SELECT *, (RollingCountVAX_adj/population)*100
FROM PopvsVax
WHERE location = 'Albania'

 --TEMP TABLE
--NOTE: the next line is usefull for changing content for the temp table. 
DROP TABLE if exists #temp_PercentPopVaxed
Create Table #temp_PercentPopVaxed
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingCountVAX_adj numeric
)

INSERT INTO #temp_PercentPopVaxed

SELECT location, continent, date, population, new_vaccinations, unadj.RollingCountVAX/2 as RollingCountVAX_adj
FROM (SELECT death.location,  death.continent, death.date, death.population, vax.new_vaccinations
	, SUM (CAST(vax.new_vaccinations as bigint)) OVER (PARTITION BY vax.location ORDER BY vax.date, vax.location) as RollingCountVAX
FROM COVID_Deaths as death
	JOIN COVID_Vaccination as vax On death.location = vax.location 
	and death.date = vax.date
WHERE vax.continent is not null ) unadj


SELECT *, (RollingCountVAX_adj/population)*100
FROM #temp_PercentPopVaxed


--Creating View to store data for visualization 
--NOTE: 'VIEW' makes a perminent tabel (access from the side bar view tab)
CREATE VIEW temp_PercentPopVaxed as
SELECT location, continent, date, population, new_vaccinations, unadj.RollingCountVAX/2 as RollingCountVAX_adj
FROM (SELECT death.location,  death.continent, death.date, death.population, vax.new_vaccinations
	, SUM (CAST(vax.new_vaccinations as bigint)) OVER (PARTITION BY vax.location ORDER BY vax.date, vax.location) as RollingCountVAX
FROM COVID_Deaths as death
	JOIN COVID_Vaccination as vax On death.location = vax.location 
	and death.date = vax.date
WHERE vax.continent is not null ) unadj


--Now, the VIEW table can be queried 
SELECT *, (RollingCountVAX_adj/population)*100 as PercentagePopVaxed
FROM temp_PercentPopVaxed

--Concluding Remarks
--Some countries has rate above 100%. This may suggests that citizens from that country recieves more than the frist dose.
--The collumn New_vaccinations only accounts for every vaccine given without accounting for the number of dose reciever already have which may explain the "unusa" rate.

