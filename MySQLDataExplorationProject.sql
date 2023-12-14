/* SQL Project: SQL Data Exploration.
Data Source: Our_World_In_Data.
Data Name: "Covid Deaths". 
Project Description: Writing queries to explore data.*/

Select *
from Covid_Deaths

Select *
from Covid_Vaccinations

--> Looking at the death rates Percentage over time.

Select Location, Date, Total_Cases, Total_Deaths, 
Round((Total_Deaths::numeric/Total_Cases::numeric)*100, 2) as Death_Rate_Percentage
from Covid_Deaths
Where Continent is not null
Order by 1, 2

--> Looking at a specific Location.

Select Location, Date, Total_Cases, Total_Deaths, 
Round((Total_Deaths::numeric/Total_Cases::numeric)*100, 2) as Death_Rate_Percentage
from Covid_Deaths
Where Location like '%Nigeria%'
Order by 1, 2

--> Showing the total percentage of population infected for each country.

Select Location, Population, Coalesce(Total_Cases, 0) as Total_Cases,
Coalesce(Percent_Of_Pop_Infected, 0) as Percent_Of_Pop_Infected
From (
	  Select Location, Population, Sum(New_Cases) as High_Cases_Count, 
	  Round((Sum(New_Cases)::numeric/Population::numeric)*100, 6) as Percent_Of_Pop_Infected
	  from Covid_Deaths
	  Where Continent is not null
	  Group by Location, Population
	  )
Order by 4 desc

--> Looking at the percentage of population that has been infected by covid over time.

Select Location, Date, Population, Total_Cases, 
Round((Total_Cases::numeric/Population::numeric)*100, 6) as Percent_Of_Pop_Infected
from Covid_Deaths
Where Continent is not null
Order by 1, 2

--> Showing the highest infection count for each Country.

Select Location, Coalesce(Countries_Infection_Counts, 0) as Countries_Infection_Counts
From (Select Location, Max(Total_Cases) as Countries_Infection_Counts
	  from Covid_Deaths
	  Where Continent is not null
	  Group by Location)
Order by Countries_Infection_Counts desc

--> Showing Maximum infection rates for each Country.

Select Location, Coalesce(Population, 0) as Population,
Coalesce(Max_Cases, 0) as Max_Cases,
Coalesce(Max_Percent_Of_Pop_Infected, 0) as Max_Percent_Of_Pop_Infected
From (Select Location, Population, Max(Total_Cases) as Max_Cases, 
	  Round(Max(Total_Cases::numeric/Population::numeric)*100, 4) as Max_Percent_Of_Pop_Infected
	  from Covid_Deaths
	  Where Continent is not null
	  Group by Location, Population)
Order by Max_Percent_Of_Pop_Infected desc

--> Looking at the percentage of population that died of covid over time.

Select Location, Date, Population, Total_Deaths, 
Round((Total_Deaths::numeric/Population::numeric)*100, 7) as Percent_Of_Dead_Ppl
from Covid_Deaths
Where Continent is not null
Order by 1, 2

--> Showing The highest death count for each Country.

Select Location, Coalesce(Countries_Death_Counts, 0) as Countries_Death_Counts
From (Select Location, Max(Total_Deaths) as Countries_Death_Counts
	  from Covid_Deaths
	  Where Continent is not null
	  Group by Location)
Order by Countries_Death_Counts desc

--> Showing Maximum Death rates for each Country/maximum death percentage for each country.

Select Location, Coalesce(Population, 0) as Population,
Coalesce(Max_Deaths, 0) as Max_Deaths,
Coalesce(Max_Percent_Of_Dead_Ppl, 0) as Max_Percent_Of_Dead_Ppl
From (Select Location, Population, Max(Total_Deaths) as Max_Deaths, 
	  Round(Max(Total_Deaths::numeric/Population::numeric)*100, 4) as Max_Percent_Of_Dead_Ppl
	  from Covid_Deaths
	  Where Continent is not null
	  Group by Location, Population)
Order by Max_Percent_Of_Dead_Ppl desc

--> Looking at death count by each continent

Select Continent, Coalesce(Continents_Death_Counts, 0) as Continents_Death_Counts
From (Select Continent, Max(Total_Deaths) as Continents_Death_Counts
	  from Covid_Deaths
	  Where Continent Is Not Null
	  Group by Continent)
Order by Continents_Death_Counts desc

--> OR

Select Location, Coalesce(Continents_Death_Counts, 0) as Continents_Death_Counts
From (Select Location, Max(Total_Deaths) as Continents_Death_Counts
	  from Covid_Deaths
	  Where Continent Is Null
	  And Location Not In ('World', 'European Union', 'International')
	  Group by Location)
Order by Continents_Death_Counts desc

/*LOOKING AT THINGS GLOBALLY.*/

--> Showing the percentages of global population that contracted covid over time

Select Date, Location,
Sum(New_Cases) as Total_Cases_Per_Day, 
Round((Sum(New_Cases)::numeric/Max(population)::numeric)*100, 7) as Global_Pop_Percent_Infected_Per_Day 
From Covid_Deaths
Group by date, location
Having Max(population) = 7794798729
Order by 1

--> Looking at the overall percentage of global population that were infected by covid.

With T_Cases as
	(Select Sum(new_cases) as Total_Cases
	 From Covid_Deaths
	 Where Continent Is Not Null),
T_Pop As
	(Select Max(population) as Total_Population
	 From Covid_Deaths),
Overall As
	(Select *, Round((Total_Cases::numeric/Total_Population::numeric)*100, 7) 
	 as Global_Pop_Percent_Infected  
	 From T_Cases, T_Pop)
Select * 
From Overall

--> Showing the percentage of global death over time/global death rate over time.

Select Date, Sum(New_Cases) as Total_Cases, Sum(New_Deaths) as Total_Deaths,
Round((Sum(New_Deaths)::numeric/Sum(New_Cases)::numeric)*100, 5) as Global_Death_Percent_Per_Day
From Covid_Deaths
Where Continent Is Not Null
Group by Date
--Having Sum(New_Cases) is null

--> Looking at global total cases, total deaths and the percentage of population that died by being infected.

Select Sum(New_Cases) as Total_Cases, Sum(New_Deaths) as Total_Deaths,
Round((Sum(New_Deaths)::numeric/Sum(New_Cases)::numeric)*100, 5)||'%' as Total_Global_Death_Percent
From Covid_Deaths
Where Continent Is Not Null

--> Looking at the overall percentage of global population that died of covid.

With T_Deaths as
	(Select Sum(New_Deaths) as Total_Deaths
	 From Covid_Deaths
	 Where Continent Is Not Null),
T_Pop As
	(Select Max(population) as Total_Population
	 From Covid_Deaths),
Overall As
	(Select *, Round((Total_Deaths::numeric/Total_Population::numeric)*100, 7) 
	 as Global_Pop_Percent_Infected  
	 From T_Deaths, T_Pop)
Select * 
From Overall

--> Looking at the rolling number of population that has been vaccinated as time progresses in each country.

Select Cod.Continent, Cod.Location, Cod.Date, Cod.Population, Cov.New_Vaccinations,
Sum(Cov.New_Vaccinations) Over(Partition by Cod.Location Order by Cod.Location, Cod.Date)
as Rolling_Count_Of_Ppl_Vac
from Covid_Deaths Cod
Join Covid_Vaccinations Cov
	On Cod.Location = Cov.Location
	And Cod.Date = Cov.Date
Where Cod.Continent is not null
Order by 2, 3

--> Looking at the percentage of population vaccinated in each country.

/* CREATING TEMP TABLE TO BE ABLE TO GET THE CORRECT OUTPUT. */

DROP Table If Exists Count_Of_Pop_Vac
Create Temporary Table Count_Of_Pop_Vac
(
Continent VarChar(100),
Location VarChar(100),
Date date,
Population Bigint,
New_Vaccinations Int,
Rolling_Count_Of_Pop_Vac Int
)
Insert Into Count_Of_Pop_Vac
(
Select Cod.Continent, Cod.Location, Cod.Date, Cod.Population, Cov.New_Vaccinations,
Sum(Cov.New_Vaccinations) Over(Partition by Cod.Location Order by Cod.Location, Cod.Date)
as Rolling_Count_Of_Pop_Vac
from Covid_Deaths Cod
Join Covid_Vaccinations Cov
	On Cod.Location = Cov.Location
	And Cod.Date = Cov.Date
Where Cod.Continent is not null
Order by 2, 3
)

--> Showing the total percentage of population vaccinated in each country.

With t1 As
	(Select Continent, Location, Date, Population, New_Vaccinations, Rolling_Count_Of_Pop_Vac,
	 Round((Rolling_Count_Of_Pop_Vac::numeric/Population::numeric)*100, 7)as Tot_Percent_Of_Pop_Vac_Per_Con
	 From Count_Of_Pop_Vac
	 ),
t2 As
	(Select Continent, Location, Population,
	 Max(Rolling_Count_Of_Pop_Vac) as Max_No_Of_Pop_Vac_Per_Con,
	 Max(Tot_Percent_Of_Pop_Vac_Per_Con) as Max_Percent_Of_Pop_Vac_Per_Con
	 From t1
	 Group by Continent, Location, Population
	 )
Select *
From t2
Order by 2