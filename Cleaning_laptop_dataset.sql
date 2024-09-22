
SELECT * FROM data_cleaning_project.laptop;

# Creating backup: 1st step

# 1.step is create the table structure
create table laptop_backup like laptop;
# 2.step insert all the value into backup table 
insert into laptop_backup 
select * from laptop; 
 
# step 2: cheking how many rows and columns are there 
select count(*) from laptop;

# step 3: cheking how much memory does the data occuipy;
select * from information_schema.tables 
where TABLE_SCHEMA = 'data_cleaning_project' and
table_name = 'laptop'; 

# 278528 bytes in order to convert bytes into kb divid it 1024
select data_length/1024 from information_schema.tables 
where TABLE_SCHEMA = 'data_cleaning_project' and
table_name = 'laptop'; 

# step 4 Drop non important columns
# unnamed: 0 columns is unrelevent so drop
select * from laptop; 
Alter table laptop drop column `Unnamed: 0`;

# Step 5 Drop null values 

with ind as (select * from laptop 
where company is null and TypeName is null and Inches is null
and ScreenResolution is null and Cpu is null and Ram is null
and Memory is null and Gpu is NULL and OpSys is null
and Weight is null and Price is null)

# so now i have to find all those index that have null value
delete from laptop where `index` in (select `index` from ind);


# Step 6 drop duplicate

select count(*) from laptop;

with duplicates as(select Company,TypeName,Inches,ScreenResolution
,cpu,ram,Memory,gpu,opsys,Weight,Price,min(`index`) as duplicate_index
 from laptop group by Company,TypeName,Inches,ScreenResolution
,cpu,ram,Memory,gpu,opsys,Weight,Price)

DELETE from laptop where `index` not in (select duplicate_index from duplicates)
;
select * from laptop;

# Step 7 cleaning coumns:

select distinct(Company) from laptop; # This column is perfect fine no null value are there 

select distinct(TypeName) from laptop; # This column is perfect no null value are there

# Inches datatype is text data i need to convert it into integer or double;
Alter table laptop modify column Inches decimal(10,1);
select * from laptop;

# Removing gb word from ram column  8Gb,16Gb....

UPDATE laptop t1
SET Ram = (
    SELECT replace(t2.ram, 'GB', '')
    FROM (SELECT * FROM laptop) t2
    WHERE t2.index = t1.index
);
# Converting text column into integer 
alter table laptop modify column ram integer;

# cleaning on memory
update laptop t1
set memory = '64GB' 
where t1.index = 720;

# Working on weight column
update laptop t1
set weight = '2.5kg' 
where t1.index = (select `index` from (select * from laptop) t2 where weight = '?');
# Replace kg with ''
update laptop t1
set weight = 
(select replace(weight,'kg','') from (select * from laptop) t2 where t2.`index` = t1.index);

# round the avg price and set the value
update laptop t1
set price = (
select round(price) from (select * from laptop) t2 where t1.index = t2.index);

select * from laptop;

# Modifying the price column into integer for memory efficency
ALTER table laptop modify column price integer;

# Now workng with difficult column;
# working with operating system
-- mac
-- windows
-- linux
-- no os
-- android chrome(others)
select opsys,
case
	when opsys like '%mac%' then 'macos'
    when opsys like '%windows%' then 'windows'
    when opsys like '%linux%' then 'linux'
    when opsys like '%No OS%' then 'NA'
    else 'others'
end as osbrand
from laptop;

update laptop 
set opsys = case
	when opsys like '%mac%' then 'macos'
    when opsys like '%windows%' then 'windows'
    when opsys like '%linux%' then 'linux'
    when opsys like '%No OS%' then 'NA'
    else 'others'
end;

select * from laptop;

alter table laptop
add column gpu_brand varchar(255) after gpu,
add column gpu_name varchar(255) after opsys ;

update laptop t1
set gpu_brand = (
select substring_index(gpu,' ',1) as gp_brand from (select * from laptop) t2 where t1.index = t2.index);


update laptop t1
set gpu_name = (
select replace(gpu,gpu_brand,'') as gp_name from (select * from laptop) t2 where t1.index = t2.index);

alter table laptop drop column Gpu;


select * from laptop;

## cleaning the CPU column
## Creating 3 column in order to stor CPus 3 pieces of information
alter table laptop
add COLUMN cpu_brand VARCHAR(255) after Cpu,
add COLUMN cpu_name VARCHAR(255) after cpu_brand,
add COLUMN cpu_speed DECIMAL(10,1) after Cpu_name;

# extracting the Cpu brand from CPU column

select Cpu,substring_index(Cpu,' ',1) from laptop;

# put all the extract cpu brand name inot cpu_brand column

update laptop t1
set cpu_brand = (
select substring_index(Cpu,' ',1) from (select * from laptop) t2 where t1.index = t2.index);

select * from laptop;

## extracting cpu_name from cpu by replace cpu_brand name to '' and put all the value to cpu_name
update laptop t1
set cpu_name = (
select replace(Cpu,cpu_brand,'') rep from 
(select * from laptop) t2 where t1.index = t2.index);

## now removing the cpu speed from cpu_name by useing substring_index and put the speed value to cpu speed
update laptop t1
set cpu_speed = (
select replace(t3.speed,'GHz','') from (SELECT cpu_name,substring_index(cpu_name,' ',-1) as 'speed' 
from (select * from laptop) t2 where t1.index = t2.index) t3);

## now removing cpu speed from cpu_name 
update laptop t1
set cpu_name = (
select substring_index(cpu_name,cpu_speed,1) new_cn from (select * from laptop)t2 where t1.index = t2.index);

# drop the Cpu column 
Alter table laptop drop column Cpu;
select * from laptop;


#### Working with screen Resolution column 
## first i am going to make 3 column height , width, touchscreen or not 

Alter table laptop
add column height integer after ScreenResolution,
add column width integer after height,
add column touchscreen integer after width;


## spearating height and width information from ScreenResolution

update laptop t1
set height=(
select substring_index(substring_index(ScreenResolution,' ',-1),'x',1) height
from (select * from laptop) t2 where t1.index = t2.index);

update laptop t1
set width=(
select substring_index(substring_index(ScreenResolution,' ',-1),'x',-1) height
from (select * from laptop) t2 where t1.index = t2.index);

## those laptop are touchscrren feature they are 1 else is 0
update laptop t1
set touchscreen = (
select 
case
	when ScreenResolution like '%Touchscreen%' then 1
    else 0
end as touch
from (select * from laptop) t2 where t1.index = t2.index);

alter table laptop drop column `ScreenResolution`;
select * from laptop;


## rename the cpu_name to make it easyer to understand

update laptop t1
set cpu_name = (case 
	when cpu_name like '%Core i5%' then 'Core i5'
    when cpu_name like '%Core i7%' then 'Core i7'
    when cpu_name like '%A9%' then 'A9'
    when cpu_name like '%Core i3%' then 'Core i3'
    when cpu_name like '%Core M%' then 'Core M'
    when cpu_name like '%E-Series%' then 'E'
    when cpu_name like '%Atom%' then 'Atom'
    when cpu_name like '%A6%' then 'A6'
    when cpu_name like '%Celeron%' then 'Celeron'
    when cpu_name like '%Ryzen%' then 'Ryzen'
    when cpu_name like '%Pentium%' then 'Pentium'
    when cpu_name like '%FX%' then 'FX'
    when cpu_name like '%A10%' then 'A10'
    when cpu_name like '%A8%' then 'A8'
    when cpu_name like '%A4%' then 'A4'
    when cpu_name like '%A12%' then 'A12'
    when cpu_name like '%Cortex%' then 'Cortex'
    else 'others'
end);

select * from laptop;
Alter table laptop 
drop column memory_space,
drop column memory_type,
drop column extend_memory,
drop column extend_memory_type;

select * from laptop;

### working on memory column crating 3 more additional column 

alter table laptop
add column secondary_storages varchar(255) after primary_storage;

# creting a temp column that will store the memory type  and  update the value into type

select Memory,
case
	when Memory like '%SSD%HDD%' then 'hybrid'
	when Memory like '%SSD%' then 'SSD'
    when memory like '%HDD%' then 'HDD'
    when memory like '%Flash%' then 'Flash drive'
end AS new
from laptop;

update laptop t1
set type = (case
	when Memory like '%SSD%HDD%' then 'hybrid'
	when Memory like '%SSD%' then 'SSD'
    when memory like '%HDD%' then 'HDD'
    when memory like '%Flash%' then 'Flash drive'
end);

# now working on primary_storage . extracting primary storage from memory and put into primary storage column

update laptop t1
set primary_storage = (substring_index(Memory,' ',1));

# now working on secondary_storage . extracting secondary storage from memory and put into secondary storage column
update laptop t1
set secondary_storages = (
select 
case 
		when t1.Memory = sec then NULL
        else sec
end as new_sec
from (select Memory,substring_index(Memory,' +',-1) sec from (select * from laptop) t2 where t1.index = t2.index) t3); 

# clening the secondary storage column 

update laptop
set secondary_storages = replace(replace(trim(replace(secondary_storage,'HDD','')),'SSD',''),'1.0TB','1TB');


select replace(trim(replace(secondary_storages,'HDD','')),'SSD','') from laptop;

## furthere cleanig the primary storage

update laptop t1
set primary_storage = (case
	when primary_storage = '1TB' then '1024GB'
    when primary_storage = '2TB' then '2048GB'
    when primary_storage = '3TB' then '3072GB'
    when primary_storage = '1.0TB' then '1024GB'
    else primary_storage
end);

update laptop t1
set primary_storage = (replace(primary_storage,'GB',''));

# converting primary_storage column into integer

alter table laptop 
modify column primary_storage integer;


## working on secondary_storage

update laptop
set secondary_storages = (case 
	when secondary_storages like '%1TB%' then '1024GB'
    when secondary_storages like '%2TB%' then '2048GB'
    else secondary_storages   
end);

update laptop
set secondary_storages = trim(secondary_storages);




# converting varchar column to integer

alter table laptop
modify column secondary_storages integer;




alter table laptop drop column gpu_name ;



select * from laptop;





 


 
 
 
 
 
 



















































