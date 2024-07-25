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

select *
from test_06

-- create another duplicate table - test_07
select *
into test_07
from test_06

-- delete unnessary columns floor, full_string_with_context

alter table test_07
drop column full_string_with_context

select *
from test_07

------------------ move into transaction column ---------------------------
select distinct [transaction] 
from test_07

--create and update another column - transaction_test
alter table test_07
add transaction_test varchar(255)


update test_07
set transaction_test =  [transaction]
where [transaction]='New Property'
or [transaction]='Resale'
or [transaction]='Other'

-- some data wrongly entered so transaction types in floor column in some data rows - 633 rows
update test_07
set transaction_test =  [floor]
where [floor]='New Property'
or [floor]='Resale'
or [floor]='Other'


-- some data wrongly entered so transaction types in status column in some data rows - 19 rows
update test_07
set transaction_test =  [status]
where [status]='New Property'
or [status]='Resale'
or [status]='Other'


-- in there 13 rows , only one F1=2494 have description and its floor = Rent/Lease 
-- add it as Rent/Lease
select *
from test_07
where transaction_test is null

update test_07
set transaction_test =  [floor]
where [floor]='Rent/Lease'

-- all others add as 'Other' - 12 rows 
update test_07
set transaction_test = 'Other'
where transaction_test is null



------------------ move into furnishing column ---------------------------
-- in here mainly 3 types  Unfurnished, Semi-Furnished, Fully-Furnished
select distinct furnishing
from test_07

-- create another column - furnishing_test

alter table test_07
add furnishing_test varchar(255)

select *
from test_07

update test_07
set furnishing_test = furnishing
where furnishing='Furnished' 
or furnishing='Unfurnished' 
or furnishing='Semi-Furnished' 


-- some data wrongly entered so furnishing in transaction , floor columns in some data rows -618 rows,13 rows

update test_07
set furnishing_test = [transaction]
where [transaction]='Furnished' 
or [transaction]='Unfurnished' 
or [transaction]='Semi-Furnished' 


update test_07
set furnishing_test = [floor]
where [floor]='Furnished' 
or [floor]='Unfurnished' 
or [floor]='Semi-Furnished' 


select *
from test_07
where furnishing_test is null 


-- check for description in null values  - 17 r0ws
select *
from test_07
where furnishing_test is null 
and description is not null


select *
from test_07
where furnishing_test is null 
and description not like '%furnished%' 



select *
from test_07
where furnishing_test is null 
and description like '%unfurnished%'

-- updated 248 rows -- in there description all are Fully furnished so some of them furnishing column doesnot match with description
update test_07
set furnishing_test = 'Furnished' 
where description like '%Fully furnished%'

-- 103 rows
update test_07
set furnishing_test = 'Unfurnished' 
where description like '%unfurnished%' 

select *
from test_07
where description like '%Semi furnished%' 

--63 rows 
update test_07
set furnishing_test = 'Semi-Furnished' 
where description like '%Semi furnished%' 

-- in there 50 rows furnishing_test is null 

-- 9 rows 
select *
from test_07
where furnishing_test is null 
and description like '%contact for more details%' 
-- we can add this as contact for more details 



------------------ move into facing column ---------------------------
-- The direction the property faces (e.g., East, North-East).
-- The North, 3 Covered , 2 Covered , 1 Covered., 1 Covered , 1 Open , 4 Covered, 6 Covered,  East,South - East,South -West,South , North - West, West , North Enclave -- 470 distinct values 
select distinct facing_test
from test_07


select *
from test_07

-- create another column 
alter table test_07
add facing_direction varchar(255)

-- update facing_direction - 3970 rows - 
update test_07
set facing_direction = facing_test
where facing_test ='North'
or facing_test ='North - East'
or facing_test ='East'
or facing_test ='South - East'
or facing_test ='South'
or facing_test ='North - West'
or facing_test ='West'
or facing_test ='South - West'



update test_07
set facing_direction = 'North'
where facing_test ='The North'
or facing_test ='North Enclave'


-- in there data enterd in other columns
-- in furnishing - North,East,South - East,North - East,South -West,South,North - West,West
select distinct furnishing
from test_07

-- 219 rows
update test_07
set facing_direction = furnishing
where furnishing ='North'
or furnishing ='East'
or furnishing ='South - East'
or furnishing ='South'
or furnishing ='North - West'
or furnishing ='West'
or furnishing ='North - East'
or furnishing ='South - West'


select *
from test_07
where facing_direction is null 

-- now check with description 
select *
from test_07
where facing_direction is null 
and description like '%NorthEast%'


SELECT F1,
       description,
       floor_test,
       SUBSTRING(description, 
                 CHARINDEX('North', description) - 5, 
                 5) 
       + 'North'
       + SUBSTRING(description, 
                   CHARINDEX('North', description) + LEN('North'), 
                   25) AS full_string_with_context
FROM   test_07
where facing_direction is null 
and description like '%North%'


-- update North - East with description - 2
select *
from test_07
where facing_direction is null 
and description like '%NorthEast%'

update test_07
set facing_direction = 'North - East'
where facing_direction is null 
and description like '%NorthEast%'

-- update South - West with description - 2
select *
from test_07
where facing_direction is null 
and description like '%South-West%'

update test_07
set facing_direction = 'South - West'
where facing_direction is null 
and (description like '%South-West%'
or description like '%SouthWest%' 
or description like '%south west%'
or description like '%west south%'
or description like '%West-South%'
or description like '%WestSouth%')


-- all west facing are - West - East update as West
select *
from test_07
where facing_direction is null 
and description like '%West facing%'

update test_07
set facing_direction ='West'
where facing_direction is null 
and description like '%West facing%'



-- east facing -2


select *
from test_07
where facing_direction is null 
and description like '%East facing%'

update test_07
set facing_direction ='East'
where facing_direction is null 
and description like '%East facing%'

----- looking for west direction - add it as west - 2
select *
from test_07
where facing_direction is null 
and description like '%west direction%'

update test_07
set facing_direction ='West'
where facing_direction is null 
and ( description like '%west direction%'
or  description like '%west-facing%'
or description like '%facing west%'
or description like '%Oriented to the west%'
or description like '% faces west%'
or description like '% faces the west%'
or description like '%facing the west%' )

-- check for before word in direction
SELECT F1,
       description,
       floor_test,
       SUBSTRING(description, 
                 CHARINDEX('direction', description) - 5, 
                 5) 
       + 'direction'
       
FROM   test_07
where facing_direction is null 
and description like '%direction%'




----- looking for east direction - add it as east - 1
select *
from test_07
where facing_direction is null 
and description like '%east direction%'

update test_07
set facing_direction ='East'
where facing_direction is null 
and description like '%east direction%'


----- looking for east direction - add it as east - 2
select *
from test_07
where facing_direction is null 
and description like '%south direction%'

update test_07
set facing_direction ='South'
where facing_direction is null 
and description like '%south direction%'




-- east and west add as West - 3
select *
from test_07
where facing_direction is null 
and description like '%east and west%'

update test_07
set facing_direction ='West'
where facing_direction is null 
and ( description like '%east and west%'
or description like '%east west%' )


-- add east-facing as East - 14
select *
from test_07
where facing_direction is null 
and description like '%east-facing%'

update test_07
set facing_direction ='East'
where facing_direction is null 
and ( description like '%east-facing%'
or description like '%facing east%'
or description like '%Oriented to the east%'
or description like '% faces east%'
or description like '% faces the east%'
or description like '%facing the east%')


-- updated north 
update test_07
set facing_direction = 'North'
where facing_direction is null 
and ( description like '%north-facing%'
or description like '%facing north%'
or description like '%Oriented to the north%'
or description like '% faces north%'
or description like '% faces the north%'
or description like '%facing the north%')

-- updated south 
update test_07
set facing_direction ='South'
where facing_direction is null 
and ( description like '%south-facing%'
or description like '%facing south%'
or description like '%Oriented to the south%'
or description like '% faces south%'
or description like '% faces the south%'
or description like '%facing the south%')


select *
from test_07
where facing_direction is null 
and ( description like '%west-facing%'
or description like '%facing west%'
or description like '%Oriented to the west%'
or description like '% faces west%'
or description like '% faces the west%'
or description like '%facing the west%')


-- South -West updated as South - West - 32 rows
update test_07
set facing_direction ='South - West'
where facing_direction is null
and facing_test like '%South -West%'

--facing_direction and description are null - 1281 rows
select *
from test_07
where facing_direction is null 
and description is null




------------------ move into type_area column ---------------------------
select distinct type_area  
from test_07

-- Posh Locality in Carpet Area or Super Area so i add status as Super Area
select *
from test_07
where type_area ='Status'

alter table test_07
add type_area_test varchar(255)

update test_07
set type_area_test = type_area
where type_area ='Built Area'
or type_area = 'Under Construction'
or type_area = 'Carpet Area'
or type_area = 'Super Area'
or type_area = 'Transaction'


update test_07
set type_area_test = 'Super Area'
where type_area ='Status'

select *
from test_07
where type_area_test is null



select *
from test_07

--------- get this detail in another table 
select *
into test_08
from test_07

select *
from test_08


-- drop unnessary columns 
alter table test_08
drop column facing , facing_test,floor,type_area,status,furnishing,[transaction]

alter table test_08
drop column [transaction]

--- we need to develop status_test column further 
-- in here still in floors data 
-- add ' Call for Details ' to them
select distinct status_test
from test_08

update test_08
set status_test ='Call for Details'
where status_test like '%Out Of%'

-- now have 5 type - Ready to Move,New Property,Under Construction,Call for Details,Resale


------------------------------------------------------ Move into Title column-------------------------------------------------


-- introduce new column to data set - type_of_property
-- Apartment - Apartments are a particular kind of residential property located on various network floors , Common areas are commonly shared, and there may be several entrances
-- Builder Floor - each level is owned by a distinct person or family,
-- Studio - The studio apartment is an apartment with a single room. They are also known as single-room dwelling places or studio flats. 
-- Penthouse - an apartment or dwelling on the roof of a building, usually set back from the outer walls
alter table test_08
add type_of_property varchar(255)

-- 20 rows
update test_08
set type_of_property ='Studio'
where Title like '%Studio Apartment%'

--5883 rows
update test_08
set type_of_property ='Apartment'
where Title like '%BHK Apartment%'

-- 241 rows
update test_08
set type_of_property ='Builder Floor'
where Title like '%Builder Floor%'

-- 267 rows
update test_08
set type_of_property ='Penthouse'
where Title like '%Penthouse%'


--7 rows
update test_08
set type_of_property ='Apartment'
where Title like '%Apartment%'
and type_of_property is null



select *
from test_08
where type_of_property is null

--- BHK - Bedroom, Hall and Kitchen
--- 2 BHK - 2 Bedrooms, Hall and Kitchen
--- in here we can introduce new column No_of_bedrooms 
alter table test_08
add No_of_bedrooms  varchar(255)

select *
from test_08
where Title like '%BHK%'

-- only one error in F1= 318
select *,
parsename(replace(Title,'BHK','.'),2)
from test_08
where Title like '%BHK%'

-- this will give all correct
select *, 
 SUBSTRING(Title, 
            CHARINDEX('BHK', Title) - 5, 
            5) 
from test_08
where Title like '%BHK%'

-- update No_of_bedrooms
update test_08
set No_of_bedrooms = SUBSTRING(Title, CHARINDEX('BHK', Title) - 5, 5) 


-- Studio type apartment always had 1 bedrooms 
select *
from test_08
where Title like '%studio%'

update test_08
set No_of_bedrooms = 1
where Title like '%studio%'

-- convert No_of_bedrooms data type creating new column No_Bedrooms

alter table test_08
add No_Bedrooms int 

update test_08
set No_Bedrooms = try_cast(No_of_bedrooms as int)


select sum(No_Bedrooms)
from test_08



--------------try to get location about apartments -----------------------------------------------------------------------
--- 2 BHK Apartment for Sale in Mahadev Harsh Platinum 3, Bopal Ahmedabad
--- 2 BHK Apartment for Sale in Vinzol Ahmedabad
--- 2 BHK Apartment for Sale in Shilp Ananta, Shela Ahmedabad
--- 2 BHK Apartment for Sale in VandeMatram Prime, 2bhk vandanam gota Ahmedabad
--- 2 BHK Apartment for Sale in Mahadev Lavish, Aaryan Gloria Ahmedabad
-- 3 BHK Apartment for Sale in Chandkheda Ahmedabad
--- 2 BHK Builder Floor for Sale in Shrirampur Ahmedabad
---  Apartment for Sale in Bapunagar One, Bapunagar Ahmedabad


--distinct titles = 2837
select distinct Title
from test_08


-- get before part of Ahmedabad
SELECT 
    Title,
    CASE 
        WHEN CHARINDEX('Ahmedabad', Title) > 0 
        THEN RTRIM(SUBSTRING(Title, 1, CHARINDEX('Ahmedabad', Title) - 1))
        ELSE Title
    END AS ExtractedPart
FROM 
    test_08;


-- get after part of 'sale in',
SELECT 
    Title,
    CASE 
        WHEN CHARINDEX('sale in', Title) > 0 
        THEN LTRIM(SUBSTRING(Title, CHARINDEX('sale in', Title) + LEN('sale in'), LEN(Title)))
        ELSE NULL
    END AS ExtractedPart
FROM 
    test_08;


-- combined these two 
SELECT 
    Title,
    CASE 
        WHEN CHARINDEX('sale in', Title) > 0 AND CHARINDEX('Ahmedabad', Title) > CHARINDEX('sale in', Title)
        THEN LTRIM(RTRIM(SUBSTRING(
            Title, 
            CHARINDEX('sale in', Title) + LEN('sale in'), 
            CHARINDEX('Ahmedabad', Title) - CHARINDEX('sale in', Title) - LEN('sale in')
        )))
        ELSE NULL
    END AS ExtractedPart
FROM 
    test_08;

-- create column and upload this data 
alter table test_08
add location_test_01 varchar(255)

update test_08
set location_test_01 = CASE 
        WHEN CHARINDEX('sale in', Title) > 0 AND CHARINDEX('Ahmedabad', Title) > CHARINDEX('sale in', Title)
        THEN LTRIM(RTRIM(SUBSTRING(
            Title, 
            CHARINDEX('sale in', Title) + LEN('sale in'), 
            CHARINDEX('Ahmedabad', Title) - CHARINDEX('sale in', Title) - LEN('sale in')
        )))
        ELSE NULL
    END 


select * 
from test_08


-- 2091 rows
select distinct location_test_01
from test_08


select location_test_01,
parsename(replace(location_test_01 , ',' , '.'),1)
from test_08

alter table test_08
add location_test_02 varchar(255)

update test_08
set location_test_02 = parsename(replace(location_test_01 , ',' , '.'),1)




select Title,location_test_01,location_test_02,description
from test_08
where location_test_02 is null

update test_08
set location_test_02= location_test_01
where location_test_02 is null and  location_test_01 is not null

-- there is no NULL values but have empty values 
select * 
from test_08
where location_test_02 is null

--UPDATE YourTable
--SET YourColumn = NULL
--WHERE YourColumn = '';

update test_08
set location_test_02 = NULL
where location_test_02 = ''

update test_08
set location_test_01 = NULL
where location_test_01 = ''


---------------------add locations ----------------
-- Major Localities of Ahmedabad City
--Bapunagar
--Khanpur
--Dariyapur
--Shahpur
--Jamalpur
--Kalupur
--Shah-e-Alam
--Behrampura
--Mirzapur
--Bodakdev
--Shahibaug
--Vastrapur
--Maninagar
--Ambawadi
--Nava Vadaj
--Ellis Bridge
--Naranpura
--Navrangpura
--Paldi
--Naroda
--Ranip
--Bopal
--Gota
--Nikol

select * 
from test_08
where location_test_02 is null and description is not null
-- there is only two location indentified
-- Nikol
-- Gota
update test_08
set location_test_02 = 'Gota'
where location_test_02 is null and description is not null and description like '%Gota%'

update test_08
set location_test_02 = 'Nikol'
where location_test_02 is null and description is not null and description like '%Nikol%'


-- all others add as call for Details 
update test_08
set location_test_02 = 'Call for Details' 
where location_test_02 is null


----
select Title,location_test_01,location_test_02
from test_08
where location_test_02 like '%Nikol%'

--- update this as Nikol 
update test_08
set location_test_02 = 'Nikol'
where location_test_02 like '%Nikol%'




--- update this as Gota 
select Title,location_test_01,location_test_02
from test_08
where location_test_02 like '%Gota%'

update test_08
set location_test_02 = 'Gota'
where location_test_02 like '%Gota%'



--- update this as Bopal 
select Title,location_test_01,location_test_02
from test_08
where location_test_02 like '%Bopal%'

update test_08
set location_test_02 = 'Bopal'
where location_test_02 like '%Bopal%'



--- update this as Bapunagar 
select Title,location_test_01,location_test_02
from test_08
where Title like '%Bapunagar%'

update test_08
set location_test_02 = 'Bapunagar'
where location_test_02 like '%Bapunagar%'



--- update this as Khanpur 
select Title,location_test_01,location_test_02
from test_08
where Title like '%Khanpur%'

update test_08
set location_test_02 = 'Khanpur'
where location_test_02 like '%Khanpur%'




--- update this as Dariyapur 
select Title,location_test_01,location_test_02
from test_08
where Title like '%Dariyapur%'

update test_08
set location_test_02 = 'Dariyapur'
where location_test_02 like '%Dariyapur%'




--- update this as Shahpur 
select Title,location_test_01,location_test_02
from test_08
where Title like '%Shahpur%'

update test_08
set location_test_02 = 'Shahpur'
where location_test_02 like '%Shahpur%'


--- update this as Jamalpur 
select Title,location_test_01,location_test_02
from test_08
where Title like '%Jamalpur%'

update test_08
set location_test_02 = 'Jamalpur'
where location_test_02 like '%Jamalpur%'


-- update all in one 


select Title,location_test_01,location_test_02
from test_08
where Title like '%Kalupur%'
or Title like '%Shah-e-Alam%'
or Title like '%Behrampura%'
or Title like '%Mirzapur%'
or Title like '%Bodakdev%'
or Title like '%Shahibaug%'
or Title like '%Vastrapur%'
or Title like '%Maninagar%'
or Title like '%Ambawadi%'
or Title like '%Nava Vadaj%'
or Title like '%Ellis Bridge%'
or Title like '%Naranpura%'
or Title like '%Navrangpura%'
or Title like '%Paldi%'
or Title like '%Naroda%'
or Title like '%Ranip%'


update test_08
set location_test_02 = case
   when Title like '%Kalupur%' then 'Kalupur'
   when Title like '%Shah-e-Alam%' then 'Shah-e-Alam'
   when Title like '%Behrampura%' then 'Behrampura'
   when Title like '%Mirzapur%' then 'Mirzapur'
   when Title like '%Bodakdev%' then 'Bodakdev'
   when Title like '%Shahibaug%' then 'Shahibaug'
   when Title like '%Vastrapur%' then 'Vastrapur'
   when Title like '%Maninagar%' then 'Maninagar'
   when Title like '%Ambawadi%' then 'Ambawadi'
   when Title like '%Nava Vadaj%' then 'Nava Vadaj'
   when Title like '%Ellis Bridge%' then 'Ellis Bridge'
   when Title like '%Naranpura%' then 'Naranpura'
   when Title like '%Navrangpura%' then 'Navrangpura'
   when Title like '%Paldi%' then 'Paldi'
   when Title like '%Naroda%' then 'Naroda'
   when Title like '%Ranip%' then 'Ranip'
   else location_test_02
end
where Title like '%Kalupur%'
or Title like '%Shah-e-Alam%'
or Title like '%Behrampura%'
or Title like '%Mirzapur%'
or Title like '%Bodakdev%'
or Title like '%Shahibaug%'
or Title like '%Vastrapur%'
or Title like '%Maninagar%'
or Title like '%Ambawadi%'
or Title like '%Nava Vadaj%'
or Title like '%Ellis Bridge%'
or Title like '%Naranpura%'
or Title like '%Navrangpura%'
or Title like '%Paldi%'
or Title like '%Naroda%'
or Title like '%Ranip%'




select Title,location_test_01,location_test_02
from test_08



---- location updated via location_test_02 and web search
update test_08
set location_test_02 = 'Zundal'
where location_test_02 like '%Zundal%'


update test_08
set location_test_02 = 'Shela'
where location_test_02 like '%Shela%'


update test_08
set location_test_02 = 'Ghuma'
where location_test_02 like '%Ghuma%'


update test_08
set location_test_02 = case
   when location_test_02 like '%Sanand%' then 'Sanand'
   when location_test_02 like '%Jagatpur%' then 'Jagatpur'
   when location_test_02 like '%Ognaj%' then 'Ognaj'
   when location_test_02 like '%Vastral%' then 'Vastral'
   when location_test_02 like '%Chandlodiya%' then 'Chandlodiya'
   when location_test_02 like '%Kasindra%' then 'Kasindra'
   when location_test_02 like '%Satellite%' then 'Satellite'
   
   else location_test_02
end
where location_test_02 like '%Sanand%'
or location_test_02 like '%Jagatpur%'
or location_test_02 like '%Ognaj%'
or location_test_02 like '%Vastral%'
or location_test_02 like '%Chandlodiya%'
or location_test_02 like '%Kasindra%'
or location_test_02 like '%Satellite %'


update test_08
set location_test_02 = case
   when location_test_02 like '%Tragad%' then 'Tragad'
   when location_test_02 like '% Makarba%' then 'Makarba'
   when location_test_02 like '% Chandkheda%' then 'Chandkheda'
   when location_test_02 like '% Sughad%' then 'Sughad'
   when location_test_02 like '% Vatva%' then 'Vatva'
   when location_test_02 like '% Narolgam%' then 'Narolgam'
   when location_test_02 like '% Satellite%' then 'Satellite'
   
   else location_test_02
end
where location_test_02 like '%Tragad%'
or location_test_02 like '%Makarba%'
or location_test_02 like '%Chandkheda%'
or location_test_02 like '%Sughad%'
or location_test_02 like '%Vatva%'
or location_test_02 like '%Narolgam%'
or location_test_02 like '%Satellite%'


update test_08
set location_test_02 = case
   when location_test_02 like '% Amraiwadi%' then 'Amraiwadi'
   when location_test_02 like '%  Gurukul%' then 'Gurukul'
   when location_test_02 like '%  Khokhra%' then 'Khokhra'
   when location_test_02 like '%   Chiloda%' then 'Chiloda'
   when location_test_02 like '%  Changodar%' then 'Changodar'
   when location_test_02 like '%  Isanpur%' then 'Isanpur'
   when location_test_02 like '%  Lambha%' then 'Lambha'
   when location_test_02 like '%Sardar Colony%' then 'Sardar Colony'
   when location_test_02 like '% Ghodasar%' then 'Ghodasar'
   when location_test_02 like '%Khamasa%' then 'Khamasa'
   when location_test_02 like '% Muthia%' then 'Muthia'
   
   else location_test_02
end
where location_test_02 like '%Amraiwadi%'
or location_test_02 like '%Gurukul%'
or location_test_02 like '%Khokhra%'
or location_test_02 like '%Chiloda%'
or location_test_02 like '%Changodar%'
or location_test_02 like '%Isanpur%'
or location_test_02 like '%Lambha%'
or location_test_02 like '%Sardar Colony%'
or location_test_02 like '% Khamasa%'
or location_test_02 like '%Ghodasar%'
or location_test_02 like '%Muthia%'


update test_08
set location_test_02 = case
   when location_test_02 like '%Khokhra%' then 'Khokhra'
   when location_test_02 like '%Nana Chiloda%' then 'Chiloda'
   when location_test_02 like '%Ghatlodiya%' then 'Ghatlodiya'
   when location_test_02 like '%Nicol%' then 'Nikol'
   when location_test_02 like '%Changodar%' then 'Changodar'
   when location_test_02 like '%Isanpur%' then 'Isanpur'
   when location_test_02 like '%Hathijan%' then 'Hathijan'
   when location_test_02 like '%Govindwadi%' then 'Govindwadi'
   when location_test_02 like '%Odhavr%' then 'Odhavr'
   when location_test_02 like '%Sarkhej Okaf%' then 'Sarkhej Okaf'
   when location_test_02 like '%Gurukul%' then 'Gurukul'
   
   else location_test_02
end
where location_test_02 like '%Khokhra%'
or location_test_02 like '% Nana Chiloda%'
or location_test_02 like '%Ghatlodiya%'
or location_test_02 like '%Nicol%'
or location_test_02 like '%Changodar%'
or location_test_02 like '%Isanpur%'
or location_test_02 like '%Hathijan%'
or location_test_02 like '%Govindwadi%'
or location_test_02 like '%Odhavr%'
or location_test_02 like '%Sarkhej Okaf%'
or location_test_02 like '%Gurukul%'


update test_08
set location_test_02 = case
   when location_test_02 like '%Khokhra%' then 'Khokhra'
   when location_test_02 like '%Nana Chiloda%' then 'Chiloda'
   when location_test_02 like '%Ghatlodiya%' then 'Ghatlodiya'
   when location_test_02 like '%Nicol%' then 'Nikol'
   when location_test_02 like '%Changodar%' then 'Changodar'
   when location_test_02 like '%Isanpur%' then 'Isanpur'
   when location_test_02 like '%Hathijan%' then 'Hathijan'
   when location_test_02 like '%Govindwadi%' then 'Govindwadi'
   when location_test_02 like '%Odhavr%' then 'Odhavr'
   when location_test_02 like '%Sarkhej Okaf%' then 'Sarkhej Okaf'
   when location_test_02 like '%Gurukul%' then 'Gurukul'
   
   else location_test_02
end
where location_test_02 like '%Khokhra%'
or location_test_02 like '% Nana Chiloda%'
or location_test_02 like '%Ghatlodiya%'
or location_test_02 like '%Nicol%'
or location_test_02 like '%Changodar%'
or location_test_02 like '%Isanpur%'
or location_test_02 like '%Hathijan%'
or location_test_02 like '%Govindwadi%'
or location_test_02 like '%Odhavr%'
or location_test_02 like '%Sarkhej Okaf%'
or location_test_02 like '%Gurukul%'



------- LTRIM(ParagraphColumn): Removes any leading (left-side) spaces from ParagraphColumn.
update test_08
set location_test_02 = ltrim(location_test_02)

select Title,location_test_01,location_test_02
from test_08

select count(location_test_02), location_test_02
from test_08
group by location_test_02 
order by 1 asc

--- location_test_02 -- No, Redevelopment society    investment opportunity,
select Title,location_test_01,location_test_02
from test_08
where location_test_02 ='Shrinandnagar part 4 L Block 202'

update test_08
set location_test_02 = 'Call for Details'
where location_test_02 = '15 The address'

update test_08
set location_test_02 = 'Redevelopment society'
where location_test_02 = 'Redevelopment society    investment opportunity'

update test_08
set location_test_02 = 'Ring Road'
where location_test_02 = '132 Feet Ring Road'

update test_08
set location_test_02 = case
   when location_test_02 like '%Shrinandnagar %' then 'Shrinandnagar'
   when location_test_02 like '%bhulabhai park 1%' then 'bhulabhai'
   when location_test_02 like '%Someshwar Park 3%' then 'Someshwar'
   when location_test_02 like '%Shapur %' then 'Shapur '
   when location_test_02 like '%Taxshila Colonials%' then 'Taxshila Colonials'
   when location_test_02 like '%Vejalpur%' then 'Vejalpur'
   when location_test_02 like '%Shreejibapa%' then 'Shreejibapa'
   when location_test_02 like '%Avani Square%' then 'Avani Square'
   when location_test_02 like '%Shrinand %' then 'Shrinand '
   when location_test_02 like '%Vandematram %' then 'Vandematram'
   when location_test_02 like '%Anand Nagar%' then 'Anand Nagar'
   
   else location_test_02
end
where location_test_02 like '%Shrinandnagar %'
or location_test_02 like '%bhulabhai park 1%'
or location_test_02 like '%Someshwar Park 3%'
or location_test_02 like '%Shapur %'
or location_test_02 like '%Taxshila Colonials%'
or location_test_02 like '%Vejalpur%'
or location_test_02 like '%Shreejibapa%'
or location_test_02 like '%Avani Square%'
or location_test_02 like '%Shrinand %'
or location_test_02 like '%Vandematram %'
or location_test_02 like '%Anand Nagar%'


select Title,location_test_01,location_test_02
from test_08
where location_test_02 ='rajlaxmi appartment'

update test_08
set location_test_02 = 'Krishna Nagar'
where location_test_02 = 'Krishna Nagar Saijpur Bogha'

update test_08
set location_test_02 = 'Vastrapur'
where location_test_02 = 'IIM'

update test_08
set location_test_02 = 'Call for Details'
where location_test_02 = 'tata'

update test_08
set location_test_02 = 'Naranpura'
where location_test_02 = 'GHB'

update test_08
set location_test_02 = 'Satellite'
where location_test_02 = 'Block B Suryapooja'

update test_08
set location_test_02 = 'Bapunagar'
where location_test_02 = 'rajlaxmi appartment'

update test_08
set location_test_02 = 'Sanand'
where location_test_02 = 'Dambha'


----- 
select *
from test_08

------------add this data into duplicate one-------------------------------------------------------------------------------
select *
into test_09
from test_08


select *
from test_09

--- remove unnessary columns
alter table test_09
drop column No_of_bedrooms , location_test_01


----- 290 rows
select *
from test_09
where price_per_sqft is null

--2155 rows
select *
from test_09
where facing_direction is null

-- 50 rows
select *
from test_09
where furnishing_test is null

-- 8 rows
select *
from test_09
where area_value is null

-- 1616 rows
select *
from test_09
where description is null



-- 6417 rows - without duplicate but have nulls and floor is still unclear beacuse resale , New Property 
-- cleaned floor - 5933 rows 
select *
from test_09

select *
from cleaned_floor

-----
select *
from cleaned_floor t2
join test_09 t1
on t1.F1=t2.F1


-- inner join test_09 and cleaned_floor as test_10
select *
into test_10
from test_09

--update t2
--set t2.price_sqft=t1.price_sqft
--from test_02 t2
--join test_01 t1
--on t1.F1=t2.F1

---- create apartment_floor and building_floors column 
alter table test_10	
add apartment_floor varchar(255)

alter table test_10	
add building_floors varchar(255)

select *
from test_10

---- join ----
update t10 
set t10.apartment_floor = t1.apartment_floor
from test_10 t10
join cleaned_floor t1
on t10.F1=t1.F1

update t10 
set t10.building_floors = t1.building_floors
from test_10 t10
join cleaned_floor t1
on t10.F1=t1.F1




-----------remove apartment_floor , building_floors nulls 
-- (484 rows affected)
begin transaction
delete from test_10
where apartment_floor is null 
commit;

-- drop floor_test column 
alter table test_10
drop column floor_test

alter table test_10
add location_test_02 varchar(255)

update test_10
set location_test_02 = location_area

--- rename columns 
-- EXEC sp_rename 'TableName.OldColumnName', 'NewColumnName', 'COLUMN';

EXEC sp_rename 'test_10.location_test_02', 'location_area' , 'COLUMN'


select *
into test_11
from test_10

alter table test_11
drop column location_test_02




---------- final two tables -----------------
select *
from test_11

select *
from test_09



---- again check for duplicates 
with get_duplicate as(
select 
row_number() over (partition by Title , type_area_test,area_value,status_test,floor_test,transaction_test,furnishing_test,facing_direction,apartment_price,price_per_sqft ,No_Bedrooms,location_test_02,description order by (select NULL) ) as row_num, -- in this case row number based on all
*
from test_09
)
select *
from get_duplicate
where row_num > 1

-- omg there is one duplicate - F1=4824
-- remove duplicate from test_09 and test_11
--use 
begin transaction
delete from test_09
where F1 = 4824
commit;

begin transaction
delete from test_11
where F1 = 4824
commit;




---------- final two tables -----------------
--cleared Floors - 5932 rows
select *
from test_11

--6416 columns - not have apartment floor and buildings floors columns 
select *
from test_09

















