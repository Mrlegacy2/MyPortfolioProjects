/* Creating Views Off Of My Covid_Deaths Data Exploration Project, 
For Later Visualizations In Tableau. 
RDBMS: POSTGRESQL. */

--> 1. Creating view for global total cases, deaths and death percentage
Create View Overall_Cases_Deaths_DeathPercent As
	(
	 Select Sum(New_Cases) as Total_Cases, Sum(New_Deaths) as Total_Deaths,
	 Round((Sum(New_Deaths)::numeric/Sum(New_Cases)::numeric)*100, 5) as Total_Global_Death_Percent
	 From Covid_Deaths
	 Where Continent Is Not Null
	)
Select *
From Overall_Cases_Deaths_DeathPercent

--> 2. Creating view for total count of death per continent.
Create View Continents_Deaths_Count As
	(
		 Select Location, Coalesce(Continents_Death_Counts, 0) as Continents_Death_Counts
	From (Select Location, Max(Total_Deaths) as Continents_Death_Counts
		  from Covid_Deaths
		  Where Continent Is Null
		  And Location Not In ('World', 'European Union', 'International')
		  Group by Location)
	Order by Continents_Death_Counts desc
	)
Select *
From Continents_Deaths_Count

--> 3. Creating View for the percentage of population infected by covid for each country/percentage of infection count for each contry.
Create View Percent_Of_Pop_Infected As
	(
	 Select Location, Population, Coalesce(High_Cases_Count, 0) as High_Cases_Count,
	 Coalesce(Percent_Of_Pop_Infected, 0) as Percent_Of_Pop_Infected
	 From (
		  Select Location, Population, Sum(New_Cases) as High_Cases_Count, 
		  Round((Sum(New_Cases)::numeric/Population::numeric)*100, 6) as Percent_Of_Pop_Infected
		  from Covid_Deaths
		  Where Continent is not null
		  Group by Location, Population
		  )
	 Order by 4 desc
)
Select *
From Percent_Of_Pop_Infected

--> 4. Creating View for percentage of population infected/Percentage of infection count over time for each country.
Create View Percent_Of_Pop_Infected_Ov_Time As
	(
	 With t1 As
		 (Select Location, Date, Population, Sum(Total_Cases) as High_Cases_Count, 
		 Round((Sum(Total_Cases)::numeric/Population::numeric)*100, 11) as Percent_Of_Pop_Infected
		 from Covid_Deaths
		 Where Continent is not null
		 Group by Location, Population, Date
		 ),
	 t2 As
		(Select Location, Date, Population, Coalesce(High_Cases_Count, 0) as High_Cases_Count, 
		 Coalesce(Percent_Of_Pop_Infected, 0) as Percent_Of_Pop_Infected
		 From t1) 
select * from t2 order by 5 desc	
	)
Select *
From Percent_Of_Pop_Infected_Ov_Time

--> 5. Creating view for the total or highest infection count for each country.
Create view Countries_Tot_Infection_Count As
	(
		 Select Location, Coalesce(Countries_Infection_Counts, 0) as Countries_Infection_Counts
	From (Select Location, Max(Total_Cases) as Countries_Infection_Counts
		  from Covid_Deaths
		  Where Continent is not null
		  Group by Location)
	Order by Countries_Infection_Counts desc	
	)
Select *
From Countries_Tot_Infection_Count

--> 6. Creating view for the rolling count of population vaccinated over time for each country.
Create View Rolling_Count_Of_Pop_Vac As
	(
	Select Continent, Location, Date, Population, Coalesce(New_Vaccinations, 0) as New_Vaccinations,
	Coalesce(Rolling_Count_Of_Pop_Vac, 0) as Rolling_Count_Of_Pop_Vac
	From (Select Cod.Continent, Cod.Location, Cod.Date, Cod.Population, Cov.New_Vaccinations,
		  Sum(Cov.New_Vaccinations) Over(Partition by Cod.Location Order by Cod.Location, Cod.Date)
		  as Rolling_Count_Of_Pop_Vac
		  from Covid_Deaths Cod
		  Join Covid_Vaccinations Cov
			  On Cod.Location = Cov.Location
			  And Cod.Date = Cov.Date
		  Where Cod.Continent is not null
		  Order by 2, 3
	    )	
	)
Select *
From Rolling_Count_Of_Pop_Vac

--> 7. Creating view for the total percentage of population vaccinated in each country.

--> This first view was regarded as a temporary view cos it was created off of a query written on a temporary table
Create View Tot_No_Of_Pop_Vac_Per_Cont As
	(
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
		 ),
	 t3 As
		 (Select Continent, Location, Population, Coalesce(Max_No_Of_Pop_Vac_Per_Con, 0) as Max_No_Of_Pop_Vac_Per_Con,
		  Coalesce(Max_Percent_Of_Pop_Vac_Per_Con, 0) as Max_Percent_Of_Pop_Vac_Per_Con
		  From t2
		  )
Select *
From t3
Order by 2
		)
		
--> Creating a permanent view for it.
Create View Tot_Percent_Of_Pop_Vac_Per_Cont_2 As
	(
	Select Continent, Location, Coalesce(Population, 0) as Population, Coalesce(Max_No_Of_Pop_Vac_Per_Con, 0) as Max_No_Of_Pop_Vac_Per_Con,
	Coalesce(Max_Percent_Of_Pop_Vac_Per_Con, 0) as Max_Percent_Of_Pop_Vac_Per_Con
	From (
		Select *, Round((Max_No_Of_Pop_Vac_Per_Con::numeric/Population::numeric)*100, 7) as Max_Percent_Of_Pop_Vac_Per_Con
		From (
			Select Cod.Continent, Cod.Location, Cod.Population, 
			Sum(Cov.New_Vaccinations) as Max_No_Of_Pop_Vac_Per_Con
			from Covid_Deaths Cod
			Join Covid_Vaccinations Cov
				On Cod.Location = Cov.Location
				And Cod.Date = Cov.Date
			Where Cod.Continent is not null
			Group by Cod.Continent, Cod.Location, Cod.Population
			Order by 2, 3
			 )
		  )
	Order by 5 desc
	);
Select *
From Tot_Percent_Of_Pop_Vac_Per_Cont_2
