use SQL_Project
select * from artist
select * from canvas_size
select * from image_link
select * from museum
select * from museum_hours
select * from product_size
select * from subject
select * from artist
select * from work
select * from museum

----1).Fetch all the paintings which are not displayed on any museums?


select * from museum where museum_id IS NULL


-------2).Are there museums without any paintings?

select museum_id,name from museum 
where
not exists(select work.name,work.museum_id
          from work
          join museum
          on museum.museum_id=work.museum_id)

-------3).How many paintings have an asking price of more than their regular price?Have to use cast before doing arithmatic comparison as the datatype is varchar 
-------and need to convert into numeric

select work_id,sale_price,regular_price from product_size
where cast(sale_price as numeric(18,2)) > cast(regular_price as numeric(18,2))

-----4) Identify the paintings whose asking price is less than 50% of its regular price
select work_id,sale_price,regular_price from product_size
where sale_price<(cast(regular_price as numeric(18,2))*0.5)



------5)Which canva size costs the most?

----when you use the DENSE_RANK() function without specifying the data type of the column you're ordering by, 
----it will perform a string-based comparison if the column is of a varchar data type. This can lead to unexpected sorting results.
-----Hence we need to convert the datatype from varchar() to decimal() or numeric()
----changing the datatype of the column to numeric()
ALTER TABLE product_size
ALTER COLUMN sale_price NUMERIC(18,0);

UPDATE product_size
SET sale_price = CAST(sale_price AS NUMERIC(18,0));

	
select c.label,ps.sale_price
from (select *,dense_rank() over( order by sale_price desc) as rnk
from product_size p) as ps
join canvas_size c
on c.size_id=ps.size_id
where ps.rnk=1


--------6)Delete duplicate records from work, product_size, subject and image_link tables

----Delete From Table work

with cte as
(
select *,
row_number() over(partition by work_id,name,artist_id,style,museum_id order by (select NULL))as rn
from work
)
delete from cte
where
rn>1

---checking that no duplicate records are present

-----when I re-run the same code, I get a message 0 rows affected

----Delete from Table Subject

with cte as
(
select *,
row_number() over(partition by work_id,subject order by (select NULL))as rn
from subject
)
delete from cte
where
rn>1



--------7)Identify the museums with invalid city information in the given dataset


SELECT distinct city
FROM museum
WHERE City LIKE '%[^A-Za-z ]%' COLLATE Latin1_General_BIN;

------The COLLATE Latin1_General_BIN clause specifies that the search should be case-insensitive and accent-sensitive.



------8)Museum_Hours table has 1 invalid entry. Identify it and remove it.
	

ALTER TABLE museum_hours
ALTER COLUMN  [open] TIME;

ALTER TABLE YourTableName
ALTER COLUMN [close] TIME;

-----in this case this does not allow conversion as the format with the AM and PM  is not proper 

	
select *
from(
     SELECT 
      *,
       CASE 
         WHEN [open] LIKE '[0-9][0-9]:[0-5][0-9]:[AP]M' AND [close] LIKE '[0-9][0-9]:[0-5][0-9]:[AP]M' THEN 'Proper Format'
       ELSE 'Improper Format'
    END AS FormatCheck
FROM museum_hours
) as s
where s.FormatCheck='Improper Format'


----------the entry with museum_id = 73 has open value 01:00:PM and close value 08:00:PM hence thats invalid and needs to be removed

delete from museum_hours where open='01:00:PM' and close='08:00:PM'----as thats an invalid entry


---------9) Fetch the top 10 most famous painting subject
select TOP(10) w.work_id,w.name,s.subject,s.rn,s.Item_count
from (select 
          subject,work_id,
		  row_number() over (partition by Subject order by Subject) as rn,
		  count(*) over(partition by Subject) as Item_count
from subject) as s
join
work w
on s.work_id=w.work_id
order by Item_count desc


--------10) Identify the museums which are open on both Sunday and Monday. Display museum name, city.




select distinct m.museum_id,m.name,m.city,m.state,m.country,mh.day
from
museum m
join
museum_hours mh
on m.museum_id=mh.museum_id
where mh.day='Sunday' 
and exists( select (1) from museum_hours mh2
                    where mh2.museum_id=mh.museum_id
					and mh2.day='Monday')
order by mh.day


----11) How many museums are open every single day?
select *
from
(
select museum_id,count(day) as cnt
from museum_hours
group by museum_id
) x
where x.cnt=7


-------12) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)



select m.name as museum, m.city,m.country,x.no_of_paintintgs
	from (	select m.museum_id, count(*) as no_of_paintintgs
			, dense_rank() over(order by count(*) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			group by m.museum_id) x
	join museum m on m.museum_id=x.museum_id
	where x.rnk<=5;


---------13) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
	select a.full_name as artist, a.nationality,x.no_of_painintgs
	from (	select a.artist_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join artist a on a.artist_id=w.artist_id
			group by a.artist_id) x
	join artist a on a.artist_id=x.artist_id
	where x.rnk<=5;

----------14)Which country has the 5th highest no of paintings?

select country,country_count
from
(
select country,
row_number() over(order by count(Country) desc) as rn,
count(Country) as country_count
from museum
group by Country

) x
where x.rn=5




