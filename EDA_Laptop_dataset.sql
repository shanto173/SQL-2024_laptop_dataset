#------------------Performing EDA-------------------------------

 # first we will be doing univariate data analysis 
 # second we will be doing bivariate data analysis
 # in bivariate analysis there are 3 thing (numerical-numerical)
 # (categorical-categorical) then (categorical to numerical) 
 
 ##-- After doing univariate and bivariate analysis we have the idea 
 ## about data and now we can fill the null value based on the knowldge
 ## then outliers find out and then feature Engineering for creating 
 ## new column for example if we use (height,width,inches) to find out
 ## PPI(pixel per inches) that is a good indicator of laptop price
 ## lastly we encode the categorical data into one hot encoding 
 
 
 ##---* Head, Tail and sample -- Data preview 
 #head
 select * from laptop order by `index` limit 5;
 #Tail
 select * from laptop order by `index` desc limit 5;
 # Sample
 select * from laptop order by rand() limit 5;
 
 
 #----- for numerical columns univariate alanaysis
 # lets focus on Price column since it is numerical column and main column
 # what can we do with numerical data (8 number summary, missing value,outliers)

# creating a new index in order to find out Q1 and Q2 and Q3 because there are no function there to find out percentile
## creating new column for new index bases on sorted price value to find out correct index value;


WITH temp AS (
  SELECT `index`,price, ROW_NUMBER() OVER(ORDER BY price) AS new_row  -- Assuming each row has a unique 'index'
  FROM laptop
)
UPDATE laptop t1
JOIN temp t2 ON t1.index = t2.index  -- Match rows using a unique identifier (e.g., 'index')
SET t1.new_index = t2.new_row;



select count(price),
min(price),
max(price),
avg(price),
STD(price),
(select price from laptop where new_index in (floor((25*(select count(*) from laptop)+1)/100))) as 'Q1',
(select price from laptop where new_index in (floor((50*(select count(*) from laptop)+1)/100))) as 'Median',
(select price from laptop where new_index in (floor((75*(select count(*) from laptop)+1)/100))) as 'Q3'

from laptop;

# -- missing value : finding the price null VALUES

select * from laptop where price is null;

# -- finding outliers
select * from laptop;
select* from (select *,
(select price from laptop where new_index in (floor((25*(select count(*) from laptop)+1)/100))) as Q1,
(select price from laptop where new_index in (floor((75*(select count(*) from laptop)+1)/100))) as Q3
from laptop) t
where t.price < (Q1-(1.5*(t.Q3-t.Q1))) or 
t.price > (Q1+(1.5*(t.Q3-t.Q1)));

# creating horizontal histograme of price useing repeat  

select t.bucket,count(price),repeat('*',count(price)/5) from (select price,
case 
	WHEN price between 0 and 25000 then '0-25k'
    WHEN price between 25001 and 50000 then '25k-50k'
    WHEN price between 50001 and 75000 then '50k-175k'
    when price between 75001 and 100000 then '50k-100k'
    else '>100K'
end as bucket
 from laptop) t
 group by t.bucket;
 
 
 ## working with weight column 
 select count(Weight),
 min(Weight),
 max(Weight),
 Avg(Weight),
 std(weight)
 from laptop;

## This is outliers so we have to remove this form out data 
select * from laptop where Weight = 0.0002;

## There are 2 laptop weight that weight is more than 8 kg which might likely to be an outliers so i have to remove this 2 from dataset 
select * from laptop where Weight > 5;

## outliers removed 
delete from laptop where `index` = 349;
delete from laptop where `index` in (326,587); 

# ploting histograme

select bucket,count(bucket),repeat('*',count(bucket)/6) from (select Weight,
case
		WHEN Weight between 0.5 and 3 then '0.5kg-3kg'
        WHEN Weight between 3.1 and 5 then '3kg-5kg'
        else '>5kg'
end as bucket from laptop) t group by bucket;


select * from laptop;


## Working with Cpu_speed categories
 ## working with weight column 
 select count(cpu_speed),
 min(cpu_speed),
 max(cpu_speed),
 Avg(cpu_speed),
 std(cpu_speed)
 from laptop;


 select * from laptop where cpu_speed  < 1.2;
 
 
 # studying categorical data 
 
 select company , count(company) from laptop GROUP BY company
 ;
 
 
select touchscreen,count(touchscreen) touchscreen_count,count(touchscreen)/(
select count(*) from laptop) touchscreen_percentage from laptop
group by touchscreen
;

select OpSys,count(OpSys) OpSys_count,(count(OpSys)/(
select count(*) from laptop)*100) OpSys_percentage from laptop
group by OpSys;

select * from laptop;


## Bivariate analysis

select Company,
sum(case when touchscreen = 1 then 1 else 0 end) 'touchscreen_yes',
sum(case when touchscreen = 0 then 1 else 0 end) 'TouchScreen_No'
from laptop
group by Company,touchscreen 
;

select company,
sum(case when cpu_brand = 'Intel' then 1 else 0 end) 'intel',
sum(case when cpu_brand = 'AMD' then 1 else 0 end) 'AMD',
sum(case when cpu_brand = 'Samsung' then 1 else 0 end) 'Samsung'
from laptop group by company;
 
 



# Bivarate analysis on numerical-categorical
  
 select Company,avg(weight)
 from laptop
 group by Company
 ;
  

  
 update laptop 
 set price = NULL
 where `index` in (7,869,1148,827,865,821,1056,1043,
 692,1114);
  
 # for missing value treatment the first thing we can do is delete those rows
 # second approach is we can fill those value with avg price 
 # third approach is we can fill those value with there avg price of there company laptop group
 # 4th approach us we can fill those value with there avg price of corresponding company + processor
 
#  update laptop
#  set price = (select avg(price) from laptop)
#  where price is null;

select company,cpu_name,avg(price) from laptop GROUP BY Company,cpu_name;
 
update laptop t1
set price = (select avg(price) from (select * from laptop) t2 where t2.Company = t1.Company and t2.cpu_name = t1.cpu_name)
where price is null;
 

select * from laptop where price is null;
 
 
 delete price from laptop where price is null;
 
 
 
 
 
 
 # After performing EDA now i have better knowledge about the data set but there are some column that are not 
 # usefull for analysis such as Height and width and inches, so with this three i can now create new column PPI which is much more helpfull
 # for analysis.
 
 # diagonal = root((width*width) + (height*height))
 # PPI = Diagonal in Pixels / diagonal in inches 
 
 alter table laptop
 add column ppi integer;
 
 
 
 update laptop t1
 set ppi = (select round(sqrt((width*width) + (height*height))/Inches) from (select * from laptop) t2 where t1.index = t2.index);
 
 # anthere column creat to correct the inches column
 
 alter table laptop
 add column screen_size varchar(255) after inches;
 
 with temp as (select inches,
 case 
		when  inches <= 14 then 'Small_size'
        when inches >14.1 and Inches < 16 then 'medium'
        when inches >= 16 then 'large'
 end 'scren_size'
 from laptop)
 
 update laptop t1
 join temp t2 on t1.Inches = t2.Inches
 set t1.screen_size = t2.scren_size;
 
 select * from laptop;
 
 
 
select gpu_brand,
case when gpu_brand = 'Inter' then 1 else 0 end as 'inter',
case when gpu_brand = 'AMD' then 1 else 0 end as 'amd', 
case when gpu_brand = 'nvidia' then 1 else 0 end as 'nvidia',
case when gpu_brand = 'arm' then 1 else 0 end as 'arm'
from laptop;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 