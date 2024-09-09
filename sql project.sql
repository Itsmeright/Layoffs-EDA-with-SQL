--Data Cleaning project
--viewing the data
Select * from layoffs;

--creating a copy
--create table layoffs_copy as table layoffs;
--viewing table copy
select * from layoffs_copy;

--Identifying Duplicates
with layoffs_duplicate_cte as (
select *, row_number() over(partition by
						   company, location, industry, total_laid_off,
						   percentage_laid_off, date, stage,country,
						   funds_raised_millions) as row_num from
						   layoffs_copy)
select * from layoffs_duplicate_cte where row_num>1;

/*created cte because after adding the row number column, I was unable to view 
duplicate rows, hence the need to create a new table to delete the duplicate by
Table creation through the pgAdmin interface so that the table layoffs_copy_2
inherit the same columns as layoffs_copy and I included a new column row_nums 
where 2 means thats the second instance of that row*/

--viewing the new table layoffs_copy_2
select * from layoffs_copy_2;

insert into layoffs_copy_2 
select *, row_number() over(partition by
						   company, location, industry, total_laid_off,
						   percentage_laid_off, date, stage,country,
						   funds_raised_millions) as row_num from
						   layoffs_copy;
--viewing duplicates in the duplicate_layoff table
select * from layoffs_copy_2 where row_num >1; 
--the above query shows that ther are 5 rows where the row_num is greater than 1

--deleting the duplicate from the data
delete from layoffs_copy_2 where row_num >1;

--standardizing the data
--removing the leading and trailing spaces in the company name
select company, trim(company) from layoffs_copy_2;

--updating the company names with the trimmed version
update layoffs_copy_2 
set company = trim(company);

--cleaning the industry column
select distinct industry from layoffs_copy_2
order by industry;
/*from the above query, we observe that there null values, 3 instance of 
"Crypto", "Crypto Currency","CryptoCurrency"*/

update layoffs_copy_2 
set industry = 'Crypto'
where industry like 'Crypto%'; 


--observing the country column
select distinct country from layoffs_copy_2
order by country;
/*the result of the above query show that united states appears twice with the
second instance having full-stop at the end*/
--printing out instances where there a full stop at the end of country name

select * from layoffs_copy_2 where country 
like '%.';

--updating the table for the countries to no longer include (.)
update layoffs_copy_2 
set country = 'United States'
where country like '%.';

--Dealing with NULL values or blank columns
select * from layoffs_copy_2 
where industry is null or 
industry = '';
--change blanks in the industry column to null using update  
update layoffs_copy_2
set industry = null
where industry = '';
/*seeing that there are 4 null values, in industry, I decided to 
find out if there are other companys in the dataset where the industry 
is inputed*/
select * from layoffs_copy_2 where 
company in ('Airbnb',
			'Carvana', 
			'Juul', 'Bally''s Interactive');
					
/*above query shows that 'Airbnb','Carvana','Juul' has other rows where
company, location and industry are not hence null values can be filled 
with that value by doing a self join to fill value*/
update layoffs_copy_2 as t1
set industry = t2.industry
from layoffs_copy_2 as t2
where t1.company = t2.company
and t1.industry is null and
	  t2.industry is not null;
--checking if industry has been correctly updated
select * from layoffs_copy_2 
where industry is null;

/*above query shows that 'Airbnb','Carvana','Juul' has been updated and
'Bally's Interactive' industry remains null because the company has no 
other rows to input value from*/

--deleting rows where total_laid_off and percentage_laid_off is null
delete from layoffs_copy_2 
where total_laid_off is null 
and percentage_laid_off is null;

--observing the new data
select * from layoffs_copy_2;

--deleting the row_num column as it no longer adds value to the dataset
alter table layoffs_copy_2 drop column row_num;

--observing the new data
select * from layoffs_copy_2;
/*changing the datatype of total_laid_off to numeric, percentage_laid_off and 
funds_raised_millions to numeric*/
--checking to see if changing the datatype to numeric works
select funds_raised_millions, cast(funds_raised_millions as numeric) as 
funds_raised_millions_2 from layoffs_copy_2;
--detaching layoffs_copy_2 from the parent table so as to be able to change datatype
ALTER TABLE layoffs_copy_2 NO INHERIT layoffs_copy;
--altering the table to have the new datatype
ALTER TABLE layoffs_copy_2 
    ALTER COLUMN total_laid_off TYPE numeric 
	using total_laid_off::numeric,
    ALTER COLUMN percentage_laid_off TYPE numeric 
	using percentage_laid_off::numeric,
	ALTER COLUMN funds_raised_millions TYPE numeric
	using funds_raised_millions::numeric;
	
	
--verifying that change has happened
select * from layoffs_copy_2;
	

--Exploratory data analysis
--what is the maximum number of layoffs and maximum lay off percentage
select max(total_laid_off), max(percentage_laid_off)
from layoffs_copy_2;
--above query shows max layoff is 12,000 and 100% percentage_laid_off

--what is the industry with the highest and least number of total layoffs
select industry, sum(total_laid_off) as total_layoffs 
from layoffs_copy_2 group by industry order by total_layoffs desc;
/*the query shows consumer has the highest number of layoffs with 45182 and 
manufacturing  has the least with 20*/

--which company has the highest number of total layoffs
select company, sum(total_laid_off) as total_layoffs 
from layoffs_copy_2 where total_laid_off is not null
group by company
order by total_layoffs desc;

--Amazon had the highest layoffs with 18150 total_layoffs

--which company made the least layoffs
select company, sum(total_laid_off) as total_layoffs 
from layoffs_copy_2 where total_laid_off is not null
group by company
order by total_layoffs;
--branch has the lowest number of layoffs

--companies that laid off all their staff
select * from layoffs_copy_2 where percentage_laid_off=1
order by stage;
--from the data 116 companies laid off all of their staff

--what date range does the data cover?
select min("date"), max("date") from layoffs_copy_2;

--what year was the worst for layoffs
select EXTRACT(YEAR FROM "date") as year, 
sum(total_laid_off) as total_layoffs
from layoffs_copy_2 group by 
EXTRACT(YEAR FROM "date") order by year desc;

--what stage of company has the highest layoffs
select stage, sum(total_laid_off) as total_layoffs 
from layoffs_copy_2 where total_laid_off is not null
group by stage
order by total_layoffs DESC;
--companies in post-ipo laid off the most and subsidiaries laid off the least

--which country had the most and least layoffs
with country_cte as 
(select country, sum(total_laid_off) as total_laid_off
	  from layoffs_copy_2 where total_laid_off is not null
		group by country
		)

(select country, total_laid_off 
from country_cte 
order by total_laid_off 
limit 1)

union all

(select country, total_laid_off 
from country_cte 
order by total_laid_off DESC
limit 1);
--result shows poland has the least layoffs and united states has the most
		


--which month and year had the most layoffs
select To_char(date, 'yyyy-mm') as yearmon, 
	sum(total_laid_off) as total_laid_off
	from layoffs_copy_2 
	where To_char(date, 'yyyy-mm') is not null
	group by yearmon
	order by total_laid_off desc;
--for the top 5 companies that laid off the most, what month and year was the worst
--finding the top 5 companies
select company, sum(total_laid_off) as total_layoffs 
	from layoffs_copy_2 where total_laid_off is not null
	group by company
	order by total_layoffs desc
	limit 5;
	
	
select company, date, total_laid_off
from layoffs_copy_2 
where company in ('Amazon','Google','Meta','Salesforce','Microsoft')
;