#### Feature Engineering
ALTER Table Amazon
Add Column timeoftheday Varchar(20);

Update Amazon
Set timeoftheday = 
	case
    when Hour(Time) >=0 and Hour(Time) < 12 Then 'Morning'
	when Hour(Time) >=12 and Hour(Time) < 18 Then 'Afternoon'
    else 'Evening'
end;

Alter Table Amazon
Add Column dayname Varchar(20);

Update Amazon
set dayname = Left(Dayname(Date),3);

Alter Table Amazon
Add Column monthname Varchar(20);

Update Amazon
Set monthname = Left(Monthname(Date),3);


select * from Amazon;


########## Exploratory Data Analysis

#### 1. What is the count of distinct cities in the dataset?
 select count(distinct city) from Amazon;
 # Ans : 3
 
#### 2. For each branch, what is the corresponding city?
select distinct branch, city 
from Amazon
group by branch, city;
# Ans : A- Yangon, B-Mandalay, C-Naypyitaw

#### 3. What is the count of distinct product lines in the dataset?
select count(distinct `Product line`)
from Amazon;
# Ans : 6

#### 4. Which payment method occurs most frequently?
select `Payment`, count(Payment)
from Amazon
group by Payment
order by count(Payment) desc
;
# Ans : Ewallet (345) max; followed by Cash (344) and Credit Card (311)


#### 5. Which product line has the highest sales?
select `Product line`, round(sum(`unit price` * quantity),2) as Sales
from Amazon
group by `Product line` 
order by sum(`unit price` * quantity) desc
limit 2; #Top 2
# Ans : Food and beverages (53,471.28);  Sports and travel (52,497.93) etc


#### 6. How much revenue is generated each month?
select distinct monthname, round(sum(`gross income`),2) as Total_Revenue
from Amazon
group by monthname;
# Ans : January = 5537.71;  March = 5212.17;  February = 4629.49


#### 7. In which month did the cost of goods sold reach its peak?
select monthname, round(sum(cogs),2) as Total_COGS
from Amazon
group by monthname
order by Total_COGS desc;
# Ans : January = 1,10,754.16 ; March = 1,04,243.34 ;  February = 93589.88


#### 8. Which product line generated the highest revenue?
select `Product line`, round(sum(`gross income`),2) as Total_Revenue
from Amazon
group by `Product line` 
order by sum(`gross income`) desc
limit 1;
# Ans : Food and beverages = 2673.56


#### 9. In which city was the highest revenue recorded?
select City, round(sum(`gross income`),2) as Total_Revenue
from Amazon
group by `City` 
order by sum(`gross income`) desc
limit 1;
# Ans : Naypyitaw = 5265.17


#### 10. Which product line incurred the highest Value Added Tax?
with highestVAT as
(
	select `Product line`, `Tax 5%`,
    row_number() over(partition by `Product line` order by `Tax 5%` desc) as R
    from Amazon
)
select `Product line`, `Tax 5%`
from highestVAT
where R ;
# Ans : Fashion and accessories 49.65%, Food and beverages = 49.25%, Home and lifestyle 48.75%, Sports and travel 47.72%, Electronic accessories 44.87%
 


#### 11. For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."
WITH AvgSales AS (
    SELECT `Product line`, 
           AVG(`Unit price` * Quantity) AS AvgSales
    FROM Amazon
    GROUP BY `Product line`
)
SELECT a.`Product line`, 
       CASE
           WHEN a.`Unit price` * a.Quantity > s.AvgSales THEN 'Good'
           ELSE 'Bad'
       END AS Sales_Performance
FROM Amazon a
JOIN AvgSales s ON a.`Product line` = s.`Product line`;
 ########### count of above and below average sales
WITH Performance AS (
    SELECT `Product line`,
        CASE
            WHEN Quantity * `Unit price` > AVG(Quantity * `Unit price`) OVER(PARTITION BY `Product line`) THEN 'Good'
            ELSE 'Bad'
        END AS Sales_Performance
    FROM Amazon
),
PerformanceCount AS (
    SELECT `Product line`,
        SUM(CASE WHEN Sales_Performance = 'Good' THEN 1 ELSE 0 END) AS Good_Count,
        SUM(CASE WHEN Sales_Performance = 'Bad' THEN 1 ELSE 0 END) AS Bad_Count
    FROM Performance
    GROUP BY `Product line`
)
SELECT `Product line`, Good_Count, Bad_Count
FROM PerformanceCount
ORDER BY `Product line`;
# Ans : Each Product lines majority sales < avg sales

#### 12. Identify the branch that exceeded the average number of products sold.
select Branch
from Amazon a
group by Branch
having  avg(quantity) > (select avg(quantity) from Amazon);
# Ans : Branch C 


#### 13. Which product line is most frequently associated with each gender?
with gendercounts as 
( 	select `Product line`, gender, count(*) as Count,
		row_number() over(partition by `Product line` order by count(*) desc) as R
	from Amazon
    group by `Product line`, gender
)
select `Product line`, gender
from gendercounts
where R = 1;
# Ans : Electronic accessories - Male, Fashion accessories - Female, Food and beverages - Female, Health and beauty - Male, Home and lifestyle - Male, Sports and travel - Female

#### 14. Calculate the average rating for each product line.
select `Product line`, round(avg(Rating),2)
from Amazon
group by `Product line`;
# Ans : Electronic accessories - 6.92, Fashion accessories - 7.03, Food and beverages - 7.11, Health and beauty - 6.84, Home and lifestyle - 6.84, Sports and travel - 6.92

#### 15. Count the sales occurrences for each time of day on every weekday.
select dayname, timeoftheday, count(*) as Count_of_Sales
from amazon
group by dayname, timeoftheday
order by 
	case dayname
    when 'Mon' then 1
    when 'Tue' then 2
    when 'Wed' then 3
    when 'Thu' then 4
    when 'Fri' then 5
    when 'Sat' then 6
    when 'Sun' then 7
	end,
timeoftheday desc
 ;
 # Sales highest in Afternoon on any day
 
#### 16. Identify the customer type contributing the highest revenue.
select  `Customer type`, round(sum(`gross income`), 2) as Revenue
from amazon
group by `Customer type`
order by Revenue desc
limit 1;
# Ans : Customer type - Member (7820.16) 


#### 17. Determine the city with the highest VAT percentage.
select  City, round(max(`Tax 5%`),2) as Highest_VAT
from amazon
group by city
order by Highest_VAT desc ;
# Ans : Naypyitaw - 49.65%


#### 18. Identify the customer type with the highest VAT payments.
select  `Customer type`, round(sum(`Tax 5%` * Total/100),2) as Total_VAT_Payment
from amazon
group by `Customer type`
order by Total_VAT_Payment desc ;
# Ans : Customer Type - Member 40,276.89


#### 19. What is the count of distinct customer types in the dataset?
select distinct `Customer type`, count(*) as Count
from amazon
group by `Customer type`;
# Ans :Member - 501; Normal - 499


#### 20. What is the count of distinct payment methods in the dataset?
select distinct Payment, count(*) as Count
from amazon
group by Payment;
# Ans : Ewallet - 345, Cash - 344, Credit card - 311


#### 21. Which customer type occurs most frequently?
select `Customer type`, count(*) as Frequency 
from Amazon
group by `Customer type`
order by Frequency desc  
limit 1;
# Ans : Member - 501; Normal - 499


#### 22. Identify the customer type with the highest purchase frequency.
select `Customer type`, count(*) as Frequency 
from Amazon
group by `Customer type`
order by Frequency desc  
limit 1;


#### 23. Determine the predominant gender among customers.
select gender, count(*) as Count
from amazon
group by gender
order by count(*) desc;
# Female 501, Male 499

#### 24. Examine the distribution of genders within each branch.
select branch, gender, count(*) as Count
from amazon
group by branch, gender
order by branch asc;
# A - Female 161, Male 179;  B - Female 162, Male 170;  C - Female 178, Male 150


#### 25. Identify the time of day when customers provide the most ratings.
select timeoftheday, Count(Rating) as Count_Rating
from Amazon
group by timeoftheday
order by Count_Rating desc limit 1;
# Ans: Afternoon 528 ratings

#### 26. Determine the time of day with the highest customer ratings for each branch.
with Customer_Rating_Branchwise as
(
	select Branch, timeoftheday, Count(Rating) as Count_Rating,
			row_number() over(partition by Branch order by Count(Rating) desc) as R
	from Amazon
	group by Branch, timeoftheday
)
select Branch, timeoftheday, Count_Rating
from Customer_Rating_Branchwise
where R =1;
# Ans : A - Afternoon - 185 ratings ;  B - Afternoon - 162 ratings;  C - Afternoon - 181 ratings


#### 27. Identify the day of the week with the highest average ratings.
select dayname, Round(Avg(Rating),2) as Average_Rating
from Amazon
group by dayname
order by Average_Rating desc 
limit 1;
# Ans : Monday - 7.15 average rating

#### 28. Determine the day of the week with the highest average ratings for each branch.
with Average_Rating_Day_Branchwise as
(
	select Branch, dayname, Round(Avg(Rating),2) as Average_Rating,
			row_number() over(partition by Branch order by Avg(Rating) desc) as R
	from Amazon
	group by Branch, dayname
)
select Branch, dayname, Average_Rating
from Average_Rating_Day_Branchwise
where R =1;
# Ans : A - Friday - 7.31 average rating;  B - Monday - 7.34 average rating;   C -  Friday - 7.28 average rating