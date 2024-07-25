USE [p2_data_cleaning]
GO

SELECT [F1]
      ,[Title]
      ,[type_area]
      ,[value_area]
      ,[status]
      ,[floor]
      ,[transaction]
      ,[furnishing]
      ,[facing]
      ,[price]
      ,[price_sqft]
      ,[description]
  FROM [dbo].[ahmedabad$]

GO


-- data cleaning project --
-- create duplicate table test_01 with all data in ahmedabad$ table 

select *
into test_01
from ahmedabad$

select *
from test_01

-- 1. introduce row number for sort out duplicates 
select 
row_number() over (partition by Title , type_area,value_area,[status],[floor],[transaction],furnishing,facing,price,price_sqft  order by (select NULL) ) as row_num, -- in this case row number based on all
*
from test_01

-- use CTE for that - get duplicates
with get_duplicate as(
select 
row_number() over (partition by Title , type_area,value_area,[status],[floor],[transaction],furnishing,facing,price,price_sqft  order by (select NULL) ) as row_num, -- in this case row number based on all
*
from test_01
)
select *
from get_duplicate
where row_num > 1

-- delete duplicates 
with get_duplicate as(
select 
row_number() over (partition by Title , type_area,value_area,[status],[floor],[transaction],furnishing,facing,price,price_sqft  order by (select NULL) ) as row_num, -- in this case row number based on all
*
from test_01
)
delete
from get_duplicate
where row_num > 1


select *
from test_01

-- in area value there is two types areas included need to get all in one dimention
--  remove sqft/sqyrd in value_area 
-- add 2 columns to data table for do that 
alter table test_01	
add Area_values varchar(255),
    Area_name varchar(255)

with get_sqft_yrd_value as(
select value_area,
parsename(replace(value_area, ' ', '.'), 2) as Area_values,
parsename(replace(value_area, ' ', '.'), 1) as Area_name
from test_01
)
update test_01
set Area_values = get_sqft_yrd_value.Area_values , 
    Area_name = get_sqft_yrd_value.Area_name
from get_sqft_yrd_value
where get_sqft_yrd_value.value_area = test_01.value_area

--- find any ',' this included or not and update it as nothing ---- ',' converted as ''
select Area_values,
replace (Area_values,',','')
from test_01

update test_01
set Area_values = replace (Area_values,',','')


--- now need to conver Area_values column as a float so we need to add another column for that - data type converted

alter table test_01
add area_value float

update test_01
set area_value = try_cast(Area_values as float)


-- convert square yard to square feets 
-- 1 sqyrd = 9 sqft
update test_01
set area_value = area_value * 9
where Area_name = 'sqyrd'



-- now again all data to another duplicate file test_02 

select *
into test_02
from test_01

select *
from test_02

-- create duplicate file before drop any column
-- drop Area_name , Area_values , Value_area columns 
alter table test_02
drop column Area_name , Area_values,Value_area


-- get only price per sqft 
-- first remove 'per sqft' and "₹4,667 per sqft" this types ₹
select *,

substring
(price_sqft,
charindex('₹',price_sqft) +3 ,
charindex(' per',price_sqft) - charindex('₹',price_sqft)-2 ) as update_one
from test_02

update test_02
set price_sqft = substring(price_sqft,
charindex('₹',price_sqft) +3 ,
charindex(' per',price_sqft) - charindex('₹',price_sqft)-2 ) 


-- second remove "‚¹6,318 " this types ‚¹
select *,
substring
(price_sqft,
charindex('‚¹',price_sqft) + len('‚¹'),
len(price_sqft) ) as update_one
from test_02
where price_sqft like '‚¹%'

update test_02
set price_sqft = substring
(price_sqft,
charindex('‚¹',price_sqft) + len('‚¹'),
len(price_sqft))


select *
from test_02

-- got error thats why i re updated price_sqft join test_01 â‚¹8,166 per sqft 
update t2
set t2.price_sqft=t1.price_sqft
from test_02 t2
join test_01 t1
on t1.F1=t2.F1


-- this method work for me 
select *,
parsename(replace(price_sqft, '₹', '.'), 1),
parsename(replace(price_sqft, 'â‚¹', '.'), 1),
replace(price_sqft, ' per sqft', '')
from test_02


-- remove ₹
update test_02
set price_sqft = parsename(replace(price_sqft, '₹', '.'), 1)

-- remove â‚¹
update test_02
set price_sqft = parsename(replace(price_sqft, 'â‚¹', '.'), 1)

-- remove  per sqft
update test_02
set price_sqft = replace(price_sqft, ' per sqft', '')

-- now need to replace ',' to nothing''
update test_02
set price_sqft = replace(price_sqft, ',', '')

-- now need to convert this data type to flot so need to add another column for that
alter table test_02
add price_per_sqft float 

update test_02
set price_per_sqft = try_cast(price_sqft as float)

-- now need to create another duplicate(test_03) and drop unnessary colum price_sqft

select *
into test_03
from test_02

select *
from test_03

alter table test_03
drop column price_sqft

-- consider price column - check 
select distinct price
from test_03

-- types -- ₹2.51 Cr  , ₹91 Lac  , â‚¹1 Cr , â‚¹98.1 Lac , Call for Price
-- i get 'call for price' data into another table - 136 rows 

select *
into call_for_price_test
from test_03
where price ='Call for Price'

select *
from call_for_price_test

-- remove price = call for price - cretae duplicate file - test_04
select *
into test_04
from test_03


delete 
from test_04
where price = 'Call for Price'

select *
from test_04

select distinct price
from test_04


--get 'Cr' and 'Lac' for another column

alter table test_04
add unit varchar(255)

update test_04
set unit = SUBSTRING(price, CHARINDEX(' ', price, PATINDEX('%[0-9]%', price)) + 1, LEN(price))
-- i add unit column for future needs , need to convert Cr and Lac to numericals in this case we can use unit column 

---- another method to that in easy way ------------------------------------------------------------------------------------------------------------------------
--SELECT 
--    price,
--    SUBSTRING(price, PATINDEX('%[0-9]%', price), CHARINDEX(' ', price, PATINDEX('%[0-9]%', price)) - PATINDEX('%[0-9]%', price)) AS NumericValue,
--    SUBSTRING(price, CHARINDEX(' ', price, PATINDEX('%[0-9]%', price)) + 1, LEN(price)) AS Unit
--FROM test_04

---- select first letter in any column - need to remove first letter 
--SELECT 
--    NumericValue,
--    SUBSTRING(NumericValue, 2, LEN(NumericValue) - 1) AS ModifiedItemName
--FROM test_04
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

select *
from test_04

-- use stuff function to delete Cr , Lac and update price column 
-- The STUFF function in SQL Server is used to insert or delete a substring from within a string


--update t2
--set t2.price_sqft=t1.price_sqft
--from test_02 t2
--join test_01 t1
--on t1.F1=t2.F1

UPDATE test_04
SET price = STUFF(price, 
                  CHARINDEX(' ', price, PATINDEX('%[0-9]%', price)) + 1, 
                  LEN(price), 
                  '')


-- remove ₹ â‚¹48.1 

select *,
replace(price, '₹', '')
from test_04

select *,
replace(price, 'â‚¹', '')
from test_04

update test_04
set price = replace(price, '₹', '')

-- remove â‚¹
update test_04
set price =replace(price, 'â‚¹', '')

select *
from test_04


-- now need to get price as float - apartment_price 
alter table test_04
add apartment_price  float

update test_04
set apartment_price = try_cast(price as float)


-- convert lac to Rupees , Cr into Rupees
-- 1 Cr = 100 lakh
update test_04
set apartment_price =  apartment_price * 100000
where unit ='Lac '


update test_04
set apartment_price =  apartment_price * 10000000
where unit ='Cr '

------ again create duplicate file and remove price , unit columns -test_05

select *
into test_05
from test_04

alter table test_05
drop column price , unit

select *
from test_05


--- in status column improve only have 4 distinct -
-- Ready to move , resale ,new propeerty , under construction

select distinct [status]
from test_05

-- for this create new column - status_test - Provides the current status of the property, which may include details like "Possession by Oct '24" or "Ready to Move"
alter table test_05
add status_test varchar(255)

update t2
set t2.status_test=t1.[status]
from test_05 t2
join test_01 t1
on t1.F1=t2.F1


-- in here details like "Possession by Oct '24" - 'Under Construction'
-- type poss by , Ready to Move , Ranna Apartment ,Bapunagar One,Resale,New Property,Const. Age New Construction, like 4 out of 4

select distinct status_test
from test_05


-- i developed this as--- status: The status of the property (e.g., Ready to Move, Under Construction- basicaly)
select * 
from test_05
where status_test ='Bapunagar One'


-- there is two values and these are same - In previously there price with random different strings
select * 
from test_05
where status ='Ranna Apartment'

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- need to check duplicates again bcz we clear data 
-- use CTE for that - get duplicates
with get_duplicate as(
select 
row_number() over (partition by Title , type_area,area_value,[status],[floor],[transaction],furnishing,facing,apartment_price,price_per_sqft  order by (select NULL) ) as row_num, -- in this case row number based on all
*
from test_05
)
select *
from get_duplicate
where row_num > 1

-- yes have duplicates
-- again 120 rows duplicate after clear some columns 
-- delete duplicate 
with get_duplicate as(
select 
row_number() over (partition by Title , type_area,area_value,[status],[floor],[transaction],furnishing,facing,apartment_price,price_per_sqft  order by (select NULL) ) as row_num, -- in this case row number based on all
*
from test_05
)
delete
from get_duplicate
where row_num > 1

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- check duplicates agian
select *
from test_04


alter table test_04
add facing_test varchar(255)

update t2
set t2.facing_test=t1.facing
from test_04 t2
join ahmedabad$ t1
on t1.F1=t2.F1

alter table test_04
drop column facing_test 

-- the facing data only have in ahmedabad$ table correctly - beacuse in here facing data type is float but actuall table its data type string
-- add it in test_04 and check duplicates 
with get_duplicate as(
select 
row_number() over (partition by Title , type_area,area_value,[status],[floor],[transaction],furnishing,facing_test,apartment_price,price_per_sqft  order by (select NULL) ) as row_num, -- in this case row number based on all
*
from test_04
)
select *
from get_duplicate
where row_num > 1
-- there is duplicates same to previous one 
-- so we can add it in duplicates removed test_05 table 

-- add test_05.facing_test=ahmedabad$.facing
alter table test_05
add facing_test varchar(255)

update t2
set t2.facing_test=t1.facing
from test_05 t2
join ahmedabad$ t1
on t1.F1=t2.F1


--- this is the one without any duplicates in this moment
select *
from test_05

------------------------------------------ again move into status column ------------------------------------------------------------------------------
select * 
from test_05
where status ='Ranna Apartment'

--- check description search for -  apartment is available for sale
select *
from test_05
where description like '%apartment is available for sale%'

-- if 'apartment is available for sale' include in description i get its status as a 'Ready to Move'
-- in this case i use duplicate column status_test for it 
update test_05
set status_test = 'Ready to Move'
where description like '%apartment is available for sale%'

-- if 'immediate'and '%avalaible for sale%' include in description i get its status as a 'Ready to Move' 
select *
from test_05
where description like '%immediate%' or description like '%avalaible for sale%' or description like '%sell%'

update test_05
set status_test = 'Ready to Move'
where description like '%immediate%' or description like '%avalaible for sale%' or description like '%sell%'


-- Bapunagar One and Ranna Apartment add as 'Ready to Move'
update test_05
set status_test = 'Ready to Move'
where status like '%Bapunagar One%' or status like '%Ranna Apartment%'

--update Const. Age New Construction as Under Construction
update test_05
set status_test = 'Under Construction'
where status = 'Const. Age New Construction'

-- update Poss by% as Under Construction   3764
update test_05
set status_test = 'Under Construction'
where status like 'Poss%'


select *
from test_05
where status_test like '%[1-9]%' 


-- update description has '%Available%' and status_test is not like Under Construction
select *
from test_05
where description like '%Available%' and status_test!='Under Construction'

update test_05
set status_test = 'Ready to Move'
where description like '%Available%' and status_test!='Under Construction'
-- still some rows remain not under Ready to Move nor Under Construction 

--create another duplicate table and move into floor column
select *
into test_06
from test_05

select *
from test_06

-- create duplicate column 
alter table test_06
add floor_test varchar(255)

update t2
set t2.floor_test=t1.floor
from test_06 t2
join test_05 t1
on t1.F1=t2.F1


-- update floor_test column using status , in here some data wrongly entered so some rows floor data in status column  
select count(*)
from test_06
where floor_test like '%out of%' -- 5850 rows correct now 

update test_06
set floor_test = status
where status like '%out of%'

-- check floor_test can upload based on description so in here some rows can update details in descriptions 
select *
from test_06
where floor_test not like '%out of%'
and description like '%floor of a%'


select description,floor_test
from test_06
where floor_test not like '%out of%'
and description like '%floor of a%'






SELECT 
  description,
  floor_test,
  SUBSTRING(description, 
            CHARINDEX('floor of a', description) - 12, 
            12) 
  + 'floor of a' 
  + SUBSTRING(description, 
              CHARINDEX('floor of a', description) + LEN('floor of a'), 
              12) AS full_string_with_context
FROM 
  test_06
WHERE 
  floor_test NOT LIKE '%out of%' 
  AND description LIKE '%floor of a%'

-- its better to add this column to table and get details
alter table test_06
drop column full_string_with_context

alter table test_06
add full_string_with_context varchar(255)

update test_06
set full_string_with_context = SUBSTRING(description, 
            CHARINDEX('floor of a', description) - 12, 
            12) 
  + 'floor of a' 
  + SUBSTRING(description, 
              CHARINDEX('floor of a', description) + LEN('floor of a'), 
              12 )
WHERE 
  floor_test NOT LIKE '%out of%' 
  AND description LIKE '%floor of a%'

select floor_test,full_string_with_context
from test_06



-- check and update / at least some of columns are get better data
SELECT 
  description,
  floor_test,
  SUBSTRING(description, 
            CHARINDEX('floor of a', description) - 4, 
            4) 
  + 'floor of a' 
  + SUBSTRING(description, 
              CHARINDEX('floor of a', description) + LEN('floor of a'), 
              3) AS full_string_with_context
FROM 
  test_06
WHERE 
  floor_test NOT LIKE '%out of%' 
  AND description LIKE '%floor of a%'


update test_06
set full_string_with_context =  SUBSTRING(description, 
            CHARINDEX('floor of a', description) - 4, 
            4) 
  + 'floor of a' 
  + SUBSTRING(description, 
              CHARINDEX('floor of a', description) + LEN('floor of a'), 
              3) 
WHERE 
  floor_test NOT LIKE '%out of%' 
  AND description LIKE '%floor of a%'


select *
from test_06	


update test_06
set floor_test = full_string_with_context
where full_string_with_context like '%-%'


SELECT 
  description,
  floor_test,
  SUBSTRING(description, 
            CHARINDEX('floor of a', description) - 4, 
            4) 
  + 'floor of a' 
  + SUBSTRING(description, 
              CHARINDEX('floor of a', description) + LEN('floor of a'), 
              3) AS full_string_with_context
FROM 
  test_06
WHERE 
  floor_test NOT LIKE '%out of%' 
  AND description LIKE '%[0-9]th floor of a [0-9]%-floor%'

-- update full_string_with_context as a above query
update test_06
set full_string_with_context = SUBSTRING(description, 
            CHARINDEX('floor of a', description) - 4, 
            4) 
  + 'floor of a' 
  + SUBSTRING(description, 
              CHARINDEX('floor of a', description) + LEN('floor of a'), 
              3) 
WHERE floor_test NOT LIKE '%out of%' AND description LIKE '%[0-9]th floor of a [0-9]%'

-- replace "th floor of a" as "out of"
update test_06
set full_string_with_context = replace(full_string_with_context, 'th floor of a', 'out of')
WHERE floor_test NOT LIKE '%out of%' AND description LIKE '%[0-9]th floor of a [0-9]%'

-- need another space before the out of
update test_06
set full_string_with_context = replace(full_string_with_context, 'out of', ' out of')
WHERE floor NOT LIKE '%out of%' AND description LIKE '%[0-9]th floor of a [0-9]%'

-- some rows have '-' need to replace it - only in 7 rows 
update test_06
set full_string_with_context = replace(full_string_with_context, '-', '')
where full_string_with_context like '%[0-9] out of [0-9]-%'


select *
from test_06
where full_string_with_context like '%out of%'

-- * F1 = 4651 its in 10 th floor but our query add is as a 0 , so need to modifi it 
select *
from test_06
where F1 = '4651'

update test_06
set full_string_with_context = '10  out of 12'
where F1 = '4651'



-- go for second and third floors
update test_06
set full_string_with_context = replace(full_string_with_context, 'nd floor of a', ' out of')
WHERE floor_test NOT LIKE '%out of%' AND description LIKE '%[0-9]nd floor of a [0-9]%'


update test_06
set full_string_with_context = replace(full_string_with_context, 'rd floor of a', ' out of')
WHERE floor_test NOT LIKE '%out of%' AND description LIKE '%[0-9]rd floor of a [0-9]%'

---- the '-' mark still appears in here 
update test_06
set full_string_with_context = replace(full_string_with_context, '-', '')
where full_string_with_context like '%[0-9] out of [0-9]-%'

select *
from test_06
where full_string_with_context like '%out of%'


-- now we can add / update floor_test column with these cleared details - 38 rows 
update test_06
set floor_test = full_string_with_context
where full_string_with_context like '%out of%'


-- now check for another set description LIKE '%[0-9]th floor of a%' and floor_test NOT LIKE '%out of%'
SELECT F1,
  description,
  floor_test,
  SUBSTRING(description, 
            CHARINDEX('floor of a', description) - 5, 
            5) 
  + 'floor of a' 
  + SUBSTRING(description, 
              CHARINDEX('floor of a', description) + LEN('floor of a'), 
              4) AS full_string_with_context
FROM 
  test_06
WHERE 
  floor_test NOT LIKE '%out of%' 
  AND description LIKE '%[0-9]th floor of a%'

-- need to go through description for that 
-- this is the data format "5th floor of a....type.............."
-- there are several types in 
--01 type = [0-9]th floor of a meticulously designed [0-9] - 3 rows


SELECT F1,
  description,
  
  floor_test,
  SUBSTRING(description, 
            CHARINDEX('floor of a', description) - 5, 
            5) 
  + 'floor of a' 
  + SUBSTRING(description, 
              CHARINDEX('floor of a', description) + LEN('floor of a'), 
              25) AS full_string_with_context
FROM 
  test_06
WHERE 
  floor_test NOT LIKE '%out of%' 
  AND description LIKE '%[0-9]th floor of a meticulously designed [0-9]%'



-- update 
update test_06
set full_string_with_context = SUBSTRING(description, 
            CHARINDEX('floor of a', description) - 5, 
            5) 
  + 'floor of a' 
  + SUBSTRING(description, 
              CHARINDEX('floor of a', description) + LEN('floor of a'), 
              25)
WHERE 
  floor_test NOT LIKE '%out of%' 
  AND description LIKE '%[0-9]th floor of a meticulously designed [0-9]%'

update test_06
set full_string_with_context = replace(full_string_with_context, 'th floor of a meticulously designed', ' out of')
WHERE floor_test NOT LIKE '%out of%' AND description LIKE '%[0-9]th floor of a meticulously designed [0-9]%'

--02 type = [0-9]th floor of an impressive  [0-9] - 
--02 type = [0-9]th floor of a prestigious  [0-9] - 
--01 type = [0-9]th floor of a meticulously designed tower boasting [0-9] -
--02 type = [0-9]th floor of a contemporary  [0-9] -
--02 type = [0-9]th floor of a well-appointed  [0-9] - 
--02 type = [0-9]th floor of an  [0-9] - 
--02 type = [0-9]th floor of a modern [0-9] - 
-- 7 rows

SELECT F1,
       description,
       floor_test,
       SUBSTRING(description, 
                 CHARINDEX('floor of a', description) - 5, 
                 5) 
       + 'floor of a' 
       + SUBSTRING(description, 
                   CHARINDEX('floor of a', description) + LEN('floor of a'), 
                   25) AS full_string_with_context
FROM   test_06
WHERE  floor_test NOT LIKE '%out of%' 
  AND ( description LIKE '%[0-9]th floor of an impressive [0-9]%' 
       or description LIKE '%[0-9]th floor of a prestigious [0-9]%'  
       or description LIKE '%[0-9]th floor of a meticulously designed tower boasting [0-9]%' 
       or description LIKE '%[0-9]th floor of a contemporary [0-9]%'  
       or description LIKE '%[0-9]th floor of a well-appointed [0-9]%'
	   or description LIKE '%[0-9]th floor of an [0-9]%'
	   or description LIKE '%[0-9]th floor of a modern [0-9]%'
	   )

--deided to manually add it bcz its only 7 rows - use when - case function 
update test_06
set full_string_with_context = case F1
when 1784 then '7 out of 11'
when 2019 then '5 out of 11'
when 1656 then '11 out of 14'
when 1932 then '4 out of 14'
when 2218 then '12 out of 13' 
when 3770 then '12 out of 17'
when 464 then '4 out of 7'
else full_string_with_context
end
where F1 in (1784,2019,1656,1932,2218,3770,464)


select F1,description,  floor_test,full_string_with_context
from test_06
WHERE  full_string_with_context NOT LIKE '%out of%' 


     
-- there is 1st floor , can use prevoius methods
SELECT F1,
  description,
  full_string_with_context,
  floor_test,
  SUBSTRING(description, 
            CHARINDEX('floor of a', description) - 8, 
            8) 
  + 'floor of a' 
  + SUBSTRING(description, 
              CHARINDEX('floor of a', description) + LEN('floor of a'), 
              8) AS full_string_with_context
FROM 
  test_06
WHERE 
  floor_test NOT LIKE '%out of%' 
  AND description LIKE '%floor of a%' and full_string_with_context NOT LIKE '%out of%' 
-- update full_string_with_context again as previous

update test_06
set full_string_with_context = SUBSTRING(description, 
            CHARINDEX('floor of a', description) - 5, 
            5) 
  + 'floor of a' 
  + SUBSTRING(description, 
              CHARINDEX('floor of a', description) + LEN('floor of a'), 
              3)
WHERE 
  floor_test NOT LIKE '%out of%' 
  AND description LIKE '%floor of a%' and full_string_with_context NOT LIKE '%out of%' 

-- 1st update as
update test_06
set full_string_with_context = replace(full_string_with_context, 'st floor of a', ' out of')
WHERE floor_test NOT LIKE '%out of%' AND full_string_with_context LIKE '%[0-9]st floor of a [0-9]%'




----- check for 
SELECT F1,
       description,
       floor_test,
       SUBSTRING(description, 
                 CHARINDEX('floor of a', description) - 5, 
                 5) 
       + 'floor of a' 
       + SUBSTRING(description, 
                   CHARINDEX('floor of a', description) + LEN('floor of a'), 
                   25) AS full_string_with_context
FROM   test_06
WHERE  full_string_with_context NOT LIKE '%out of%' 
  AND ( description LIKE '%[0-9]th floor of an impressive [0-9]%' 
       or description LIKE '%[0-9]th floor of a prestigious [0-9]%'  
       or description LIKE '%[0-9]th floor of a meticulously designed tower boasting [0-9]%' 
       or description LIKE '%[0-9]th floor of a contemporary [0-9]%'  
       or description LIKE '%[0-9]th floor of a well-appointed [0-9]%'
	   or description LIKE '%[0-9]th floor of an [0-9]%'
	   or description LIKE '%[0-9]th floor of a modern [0-9]%'
	   or description LIKE '%[0-9]th floor of a well-maintained [0-9]%'
	   or description LIKE '%[0-9]rd floor of a well-maintained [0-9]%'
	   or description LIKE '%top floor of a [0-9]%'
	   )

--- update '%[0-9]rd floor of a well-maintained [0-9]%'
update test_06
set full_string_with_context = SUBSTRING(description, 
                 CHARINDEX('floor of a', description) - 5, 
                 5) 
       + 'floor of a' 
       + SUBSTRING(description, 
                   CHARINDEX('floor of a', description) + LEN('floor of a'), 
                   18) 
WHERE  full_string_with_context NOT LIKE '%out of%' and description LIKE '%[0-9]rd floor of a well-maintained [0-9]%'

update test_06
set full_string_with_context = replace(full_string_with_context, 'rd floor of a well-maintained', ' out of')
WHERE floor_test NOT LIKE '%out of%' AND full_string_with_context LIKE '%[0-9]rd floor of a well-maintained [0-9]%'

--- update description LIKE '%[0-9]th floor of a well-maintained [0-9]%'

update test_06
set full_string_with_context = SUBSTRING(description, 
                 CHARINDEX('floor of a', description) - 5, 
                 5) 
       + 'floor of a' 
       + SUBSTRING(description, 
                   CHARINDEX('floor of a', description) + LEN('floor of a'), 
                   19) 
WHERE  full_string_with_context NOT LIKE '%out of%' and description LIKE '%[0-9]th floor of a well-maintained [0-9]%'

update test_06
set full_string_with_context = replace(full_string_with_context, 'th floor of a well-maintained', ' out of')
WHERE floor_test NOT LIKE '%out of%' AND full_string_with_context LIKE '%[0-9]th floor of a well-maintained [0-9]%'


---- the '-' mark still appears in here 
update test_06
set full_string_with_context = replace(full_string_with_context, '-', '')
where full_string_with_context like '%[0-9] out of [0-9]-%'


-- again there is some error columns update it manulay
update test_06
set full_string_with_context = case F1
when 1783  then '7 out of 7'
when 1832  then '3 out of 5'
when 1939  then '3 out of 5'
when 2221  then '2 out of 7'

when 1386  then '5 out of 5'
when 1776  then '4 out of 5'
when 2480  then '5 out of 13'
when 2830  then '1 out of 11'
when 2897  then '1 out of 5'
when 1884  then 'Ground out of 1'
when 2217  then '3 out of 11' 
when 2236  then '3 out of 6'
when 3284  then '2 out of 13'
when 3426   then '5 out of 12'

when 3633   then '12 out of 24'
when 3954   then '2 out of 4'
when 3285 then '7 out of 7'
when 3630    then '2 out of 5'
when 6109    then '16 out of 17'
when 459    then '4 out of 4'
when 471     then '5 out of 5'
when 1721 then '2 out of 7'
when 1745 then '5 out of 5'
when 203 then '1 out of 7'
when 466 then '6 out of 7'
when 1421 then '3 out of 5'
when 1655 then '2 out of 5'
else full_string_with_context
end
where F1 in (1783,1832,1939,2221,1386,1776,2480,2830,2897,1884,2217,2236,3284,3426,3633,3954,3285,3630,6109,459,471,1721,1745,203,466,1421,1655)




select F1,full_string_with_context,description
from test_06
WHERE full_string_with_context not like '%out of%'


select *
from test_06

-- now all rows floors update as a full_string_with_context now we need to add this to floor_test - 
update test_06
set floor_test = full_string_with_context
where floor_test not like'%out of%'


--- check for update values nulls - is there any way to add floors
select *
from test_06
where floor_test not like '%out of%' and description LIKE '%floor of a%'

--update previous values to floor_test when its null values 
update test_06
set floor_test = floor 
where floor_test is null 


SELECT F1,
       description,
       floor_test,
       SUBSTRING(description, 
                 CHARINDEX('floor of a', description) - 5, 
                 5) 
       + 'floor of a' 
       + SUBSTRING(description, 
                   CHARINDEX('floor of a', description) + LEN('floor of a'), 
                   3) AS full_string_with_context
FROM   test_06
WHERE  full_string_with_context is null
  AND  description LIKE '%floor of a%'

-- update
update test_06
set full_string_with_context = SUBSTRING(description, 
                 CHARINDEX('floor of a', description) - 5, 
                 5) 
       + 'floor of a' 
       + SUBSTRING(description, 
                   CHARINDEX('floor of a', description) + LEN('floor of a'), 
                   3)
WHERE  full_string_with_context is null
  AND  description LIKE '%floor of a%'   





-- all 170 rows - cannot search for any details bcz description is null
select *
from test_06
where floor_test not like '%out of%' and description is null

-- now going to check where floor_test  like '%Resale%' and description LIKE '%floor%'
select *
from test_06
where floor_test  like '%Resale%' and description LIKE '%floor%'



SELECT F1,
       description,
       floor_test,
       SUBSTRING(description, 
                 CHARINDEX('floor ', description) - 5, 
                 5) 
    
       + SUBSTRING(description, 
                   CHARINDEX('floor of a', description) + LEN('floor'), 
                   25) AS full_string_with_context
FROM   test_06
where floor_test  like '%Resale%' and description LIKE '%floor%'


-- Skydeck Serene,Pearl Apartment, NULL
select distinct floor_test 
from test_06

-- 43 rows
select *
from test_06
where floor_test not like '%out of%' and description is not null and description LIKE '%floor%'

select *
from test_06
where floor_test is null

---------------------------------------------------------------------------- cleaned_floor new table---------------------------------------------------------------------------------------
-- in here all 478 rows without mention about floor , 170 rows description is null and 308 rows with description but cannot get idea about floor 
-- i duplicate floor_test 
-- create table only have cleaned data 
select *
into cleaned_floor
from test_06

alter table cleaned_floor
add floor_test_01 varchar(255)


update cleaned_floor
set floor_test_01 = floor_test
where floor_test like '%out of%' 

select *
from cleaned_floor

--- need to remove floor_test not like '%out of%' data in cleaned_floor table 
-- use Transaction for this 
-- Consider using a transaction to ensure that your delete operation can be rolled back in case something goes wrong.

---- BEGIN TRANSACTION;

--DELETE FROM Employees
--WHERE Department = 'Sales';

---- If everything is okay
--COMMIT;

---- If something goes wrong
--ROLLBACK;

begin transaction
delete from cleaned_floor
where floor_test not like '%out of%'
commit;

begin transaction
delete from cleaned_floor
where floor_test_01 is null
commit;

alter table cleaned_floor
drop column [floor] , floor_test, full_string_with_context

select *
from cleaned_floor



-- now using cleaned_floor table 
-- create column for add apartment floor based on floor .
-- in floor there is apartment floor and all floors count included 
-- in here i divided them apartment floor -- which floor apartment at , building floors - how many floors in apartment building  Lower Basement out of 13
-- there is Lower Basement , upper Basement invole in some rows 



alter table cleaned_floor
add apartment_floor varchar(255)

alter table cleaned_floor
add building_floors varchar(255)

select *
from cleaned_floor



SELECT floor_test_01,F1,
    SUBSTRING(floor_test_01, 1, CHARINDEX(' out of ', floor_test_01) - 1) AS apartment_floor,
    SUBSTRING(floor_test_01, CHARINDEX(' out of ', floor_test_01) + 8, LEN(floor_test_01)) AS building_floors
FROM cleaned_floor

SELECT floor_test_01,F1,
    SUBSTRING(floor_test_01, 1, CHARINDEX(' out of ', floor_test_01) - 1) AS apartment_floor,
    SUBSTRING(floor_test_01, CHARINDEX(' out of ', floor_test_01) + 8, LEN(floor_test_01)) AS building_floors
FROM cleaned_floor
where floor_test_01 like '%Basement%'

-- now update apartment_floor , building_floors 
update cleaned_floor
set 
    apartment_floor = SUBSTRING(floor_test_01, 1, CHARINDEX(' out of ', floor_test_01) - 1),
    building_floors = SUBSTRING(floor_test_01, CHARINDEX(' out of ', floor_test_01) + 8, LEN(floor_test_01) - CHARINDEX(' out of ', floor_test_01) - 7)

select *
from cleaned_floor
where floor_test_01 like '%Basement%'

-- in here all area_value, price_per_sqft , apartment_price and apartment_floor , building_floors are cleared 
-- now move into another file SQLQuery12.sql 