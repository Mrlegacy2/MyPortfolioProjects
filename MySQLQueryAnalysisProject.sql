/* SQL Project: Solving Twenty(20) different problems with SQL from a real Dataset.
Dataset Source: Kaggle.
Dataset Name: "120 Years Of Olympique History". 
Project Description: Writing queries to analize data and answer questions.
RDBMS: POSTGRESQL. */

select *
from Athlete_Events_History

select *
from Noc_Regions_History

-- 1. How many Olympique Games have been held

Select Count(1) as Total_No_Games
From (Select distinct games
	  From Athlete_Events_History)

-- 2. List down all Olympics games held so far. 

Select distinct *
From (Select Year, Season, City
	  From Athlete_Events_History)
Order by Year

-- OR

Select distinct *
From (Select Games, City
	  From Athlete_Events_History)
Order by Games

-- 3. Mention the total no of nations who participated in each olympics game?

With t1 As
	(Select Games, Region
	  From Athlete_Events_History ath
	  Join Noc_Regions_History noc
		  On ath.noc = noc.noc),
t2 As
	 (Select distinct *
	  From t1)
Select Games, Count(*) as Total_Countries
From t2
Group by Games
Order by Total_Countries desc

-- 4. Which year saw the highest and lowest no of countries participating in olympics

With t1 As
	(Select Games, Region
	 From Athlete_Events_History ath
	 Join Noc_Regions_History noc
		On ath.noc = noc.noc),
t2 As
	 (Select distinct *
	  From t1),
t3 As
	  (Select Games, Count(*) as Total_Countries
	   From t2
	   Group by Games
	   Order by Games)
Select Concat(First_Value(Games) Over(order by Total_Countries),
' - ', First_Value(Total_Countries) Over(order by Total_Countries)) as Lowest_Countries,
Concat(First_Value(Games) Over(order by Total_Countries desc),
' - ', First_Value(Total_Countries) Over(order by Total_Countries desc)) as Highest_Countries
From t3
Limit 1;

-- 5. Which nation(s) has participated in all of the olympic games

Select Region, Total_No_Games
From (Select *, Rank() Over(order by Total_No_Games desc) as rnk
	  From (Select Region, Count(distinct Games) as Total_No_Games
		    From (Select Region, Games
				  From Athlete_Events_History ath
				  Join Noc_Regions_History noc
				    On ath.noc = noc.noc)
	  Group by Region))
Where rnk = 1

-- 6. Identify the sport which was played in all summer olympics.

With t1 As
	(Select Sport, Count(distinct Games) as No_Sports
	From (Select Sport, Games
		  From Athlete_Events_History
		  Where Games Like '%S%')
	Group by Sport),
t2 As 
     (Select distinct Games
	  From Athlete_Events_History
	  Where Games Like '%S%'),
t3 As
	  (Select Count(*) as Total_Sports
	   From t2)
Select Sport, No_Sports, Total_Sports
From t3
Join t1
	On t3.Total_Sports = t1.No_Sports

-- OR

Select Sport,No_Sports, Total_Sports
From (Select Sport, Count(distinct Games) as No_Sports
	  From (Select Sport, Games
		    From Athlete_Events_History
		    Where Games Like '%S%')
	  Group by Sport) y
Join (Select Count(distinct Games) as Total_Sports 
      From Athlete_Events_History
      Where Games Like '%S%') z
   On y.No_Sports = z.Total_Sports

-- 7. Which Sports were just played only once in the olympics.

Select y.Sport, No_Sports, Games
from (Select Sport, Count(distinct Games) as No_Sports
	  From (Select Sport, Games
			From Athlete_Events_History)
	  Group by Sport) y
Join (Select Sport, Games, Count(distinct 1) as No_dist_Sports
	  From Athlete_Events_History
	  Group by Sport, Games) z
	On y.No_Sports = z.No_dist_Sports
	And y.Sport = z.Sport

-- 8. Fetch the total no of sports played in each olympic games.

Select Games, Count(distinct Sport) as No_Of_Sports
From Athlete_Events_History
Group  by Games
Order by No_Of_Sports desc

-- 9. Fetch oldest athletes to win a gold medal.

Select name, sex, age, height, weight, team, 
games, city, sport, event, medal
From (Select *,
	  Rank() Over(Order by Age desc) as rnk
	  From Athlete_Events_History
	  Where Age != 'NA' And Medal = 'Gold') y
Where y.rnk = 1

-- 10. Find the Ratio of male and female athletes participated in all olympic games.

With t1 as
	(Select *, Row_Number() Over(Order by Sx_Cnt) as Row_Num
	 From (Select Sex, Count(2) as Sx_Cnt
	 	   From Athlete_Events_History
	 	   Group by Sex)),
l_Sx_Cnt As
	(Select Sx_Cnt
	 From t1
	 Where Row_Num = 1),
H_Sx_Cnt As
	(Select Sx_Cnt
	 From t1
	 Where Row_Num = 2)
Select Concat('1 : ', Round(H_Sx_Cnt.Sx_Cnt::decimal/l_Sx_Cnt.Sx_Cnt, 2)) as Ratio
From H_Sx_Cnt, l_Sx_Cnt

-- Male To Female Ratio

With t1 As
	(Select Count(1) as Total_Sex
	 From Athlete_Events_History),
t2 As
	(Select *, Row_Number() Over(Order by Sx_Cnt) as Row_Num
	 From (Select Sex, Count(2) as Sx_Cnt
	 	   From Athlete_Events_History
	 	   Group by Sex)),
l_Sx_Cnt As
	(Select Sx_Cnt
	 From t2
	 Where Row_Num = 1),
H_Sx_Cnt As
	(Select Sx_Cnt
	 From t2
	 Where Row_Num = 2)
Select Concat(Round(H_Sx_Cnt.Sx_Cnt::decimal/t1.Total_Sex, 2),
' : ', Round(l_Sx_Cnt.Sx_Cnt::decimal/t1.Total_Sex, 2)) as M_To_F_Ratio
From t1, H_Sx_Cnt, l_Sx_Cnt

-- 11. Fetch the top 5 athletes who have won the most gold medals.

Select Name, Team, Total_Gold_medal
From (Select y.*, dense_rank() Over(Order by Total_Gold_medal desc) as drnk
      From (Select distinct Name, Team, Count(Medal) 
	        Over(Partition by Name) as Total_Gold_medal
	        From Athlete_Events_History
	        Where Medal = 'Gold'
	        Order by Total_Gold_medal desc) y) z
Where z.drnk <= 5

-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

Select Name, Team, Total_No_medal
From (Select y.*, dense_rank() Over(Order by Total_No_medal desc) as drnk
      From (Select distinct Name, Team, Count(Medal) 
	        Over(Partition by Name) as Total_No_medal
	        From Athlete_Events_History
	        Where Medal != 'NA'
	        Order by Total_No_medal desc) y) z
Where z.drnk <= 5

-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

Select *
From (Select y.*, Rank() Over(Order by Total_Country_medals desc) as Rank_Num
      From (Select distinct Region, Count(Medal) 
	        Over(Partition by Region) as Total_Country_medals
	        From Athlete_Events_History ath
			Join Noc_Regions_History noc
				ON ath.noc = noc.noc
	        Order by Total_Country_medals desc) y) z
Where z.Rank_Num <= 5

-- 14. List down total gold, silver and bronze medals won by each country.

Select Country,
Coalesce(Bronze, 0) as Bronze,
Coalesce(Gold, 0) as Gold,
Coalesce(Silver, 0) as Silver
From Crosstab('Select Region as Country, Medal, Count(Medal) 
			  as Total_Country_medals
			  From Athlete_Events_History ath
			  Join Noc_Regions_History noc       
				 ON ath.noc = noc.noc
			  Where Medal  != ''NA''
			  Group by Region, Medal
			  Order by Region, Medal',
			  'Values (''Bronze''), (''Gold''), (''Silver'')')
	As Cross_Result (Country Varchar, Bronze Bigint, Gold Bigint, Silver Bigint)
Order by Bronze desc, Gold desc, Silver desc

-- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

Select Substring(Games_Country, 1, Position(' - ' in Games_Country) -1 ) as Games,
Substring(Games_Country, Position(' - ' in Games_Country) +3 ) as Country,
Coalesce(Bronze, 0) as Bronze,
Coalesce(Gold, 0) as Gold,
Coalesce(Silver, 0) as Silver
From crosstab('Select Concat(Games, '' - '', Region) as Games_Country,
			  Medal, Count(2) as Total_Medals
			  From Athlete_Events_History ath
			  Join Noc_Regions_History noc       
				   ON ath.noc = noc.noc
			  Where Medal != ''NA''
			  Group by Games, Region, Medal
			  Order by Games, Region, Medal',
			  'Values (''Bronze''), (''Gold''), (''Silver'')'
			  )
	 As Cross_Result (Games_Country text, Bronze Bigint, Gold Bigint, Silver Bigint)

-- 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.

With t1 As
	(Select Substring(Games_Country, 1, Position(' - ' in Games_Country) -1 ) as Games,
	 Substring(Games_Country, Position(' - ' in Games_Country) +3 ) as Country,
	 Coalesce(Bronze, 0) as Bronze,
	 Coalesce(Gold, 0) as Gold,
	 Coalesce(Silver, 0) as Silver
	 From crosstab('Select Concat(Games, '' - '', Region) as Games_Country,
				  Medal, Count(2) as Total_Medals
				  From Athlete_Events_History ath
				  Join Noc_Regions_History noc       
					   ON ath.noc = noc.noc
				  Where Medal != ''NA''
				  Group by Games, Region, Medal
				  Order by Games, Region, Medal',
				  'Values (''Bronze''), (''Gold''), (''Silver'')'
				  )
	 As Cross_Result (Games_Country text, Bronze Bigint, Gold Bigint, Silver Bigint))
Select Distinct Games,
Concat(First_Value(Country) Over(Partition by Games Order by Gold desc),
	   ' - ',
	   First_Value(Gold) Over(Partition by Games Order by Gold desc)) as Max_Gold,
Concat(First_Value(Country) Over(Partition by Games Order by Silver desc),
	   ' - ',
	   First_Value(Silver) Over(Partition by Games Order by Silver desc)) as Max_Silver,
Concat(First_Value(Country) Over(Partition by Games Order by Bronze desc),
	   ' - ',
	   First_Value(Bronze) Over(Partition by Games Order by Bronze desc)) as Max_Bronze
From t1
Order by Games

-- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

With t1 As
	(Select Substring(Games_Country, 1, Position(' - ' in Games_Country) -1 ) as Games,
	 Substring(Games_Country, Position(' - ' in Games_Country) +3 ) as Country,
	 Coalesce(Bronze, 0) as Bronze,
	 Coalesce(Gold, 0) as Gold,
	 Coalesce(Silver, 0) as Silver
	 From crosstab('Select Concat(Games, '' - '', Region) as Games_Country,
				  Medal, Count(2) as Total_Medals
				  From Athlete_Events_History ath
				  Join Noc_Regions_History noc       
					   ON ath.noc = noc.noc
				  Where Medal != ''NA''
				  Group by Games, Region, Medal
				  Order by Games, Region, Medal',
				  'Values (''Bronze''), (''Gold''), (''Silver'')'
				  )
	 As Cross_Result (Games_Country text, Bronze Bigint, Gold Bigint, Silver Bigint))
Select Distinct t1.Games,
Concat(First_Value(t1.Country) Over(Partition by t1.Games Order by Gold desc),
	   ' - ',
	   First_Value(Gold) Over(Partition by t1.Games Order by Gold desc)) as Max_Gold,
Concat(First_Value(t1.Country) Over(Partition by t1.Games Order by Silver desc),
	   ' - ',
	   First_Value(Silver) Over(Partition by t1.Games Order by Silver desc)) as Max_Silver,
Concat(First_Value(t1.Country) Over(Partition by t1.Games Order by Bronze desc),
	   ' - ',
	   First_Value(Bronze) Over(Partition by t1.Games Order by Bronze desc)) as Max_Bronze,
Concat(First_Value(y.Country) Over(Partition by y.Games Order by Total_Country_Medals desc),
	   ' - ',
	   First_Value(Total_Country_Medals) Over(Partition by y.Games Order by Total_Country_Medals desc)) as Max_Medals
From t1
Join (Select Games, Region as Country, Sum(Total_Medal) as Total_Country_Medals
	  From (Select Games, Region,
	  		Medal, Count(1) as Total_Medal
	  		From Athlete_Events_History ath
	  		Join Noc_Regions_History noc       
	  	  		ON ath.noc = noc.noc
	  		Where Medal  != 'NA'
	  		Group by Games, Region, Medal
	  		Order by Games, Region)
	  Group by Games, Country
	  Order by Games, Total_Country_Medals desc) y
	  	On t1.Games = y.Games
		AND t1.Country = y.Country
Order by Games

-- 18. Which countries have never won gold medal but have won silver/bronze medals?
				  
Select Country, Gold, Silver, Bronze
From (Select Country,
	  Coalesce(Bronze, 0) as Bronze,
	  Coalesce(Gold, 0) as Gold,
	  Coalesce(Silver, 0) as Silver
	  From Crosstab('Select Region as Country, Medal, Count(Medal) 
				  as Total_Country_medals
				  From Athlete_Events_History ath
				  Join Noc_Regions_History noc       
					 ON ath.noc = noc.noc
				  Where Medal  != ''NA''
				  Group by Region, Medal
				  Order by Region',
				  'Values (''Bronze''), (''Gold''), (''Silver'')')
	  As Cross_Result (Country Varchar, Bronze Bigint, Gold Bigint, Silver Bigint))
Where Gold = 0


-- 19. In which Sport/event, India has won highest medals.

With t1 As
	(Select Sport, Count(Medal) as Total_Country_medal
	 From Athlete_Events_History
	 Where Medal != 'NA'
	 And Team = 'India'
	 Group by Sport
	 Order by Total_Country_medal desc),
t2 As
	(Select *, Rank() Over(Order by Total_Country_medal desc) as rnk
	 From t1)
Select Sport, Total_Country_medal
From t2
Where rnk = 1

-- 20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games.

Select distinct Games, Sport, Team, Count(Medal) 
Over(Partition by Games) as Total_Country_Medals
From Athlete_Events_History
Where Medal != 'NA'
And Team = 'India'
And Sport = 'Hockey'
Order by Total_Country_Medals desc
