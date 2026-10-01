drop table if exists petey;
create table petey AS
with props as (
	select 
    strap as s, 
    1.0 * CNTY_JST_VALUE as j, 
    1.0 * CNTY_TAXABLE_VALUE as t
	from RP_PROPERTY_INFO
	where property_use = '0110 Single Family Home'
  AND STR_CITY LIKE '%PETERSBURG'
  -- LIMIT 1000
), crosses as (
	select 
		l.s as ls, 
		r.s as rs,
		l.t / r.t as tr,
		l.j / r.j as jr
	from props as l
		cross join props as r
	where l.j <= r.j
), diffs as (
  select *,
  CASE
    -- tax value is > 2 while just value is equal or less
    WHEN tr > 2 AND jr < 1.1 then 'gt'
    -- just value is < 0.5 while tax value is equal or greater
    WHEN jr < 0.5 AND tr > 0.9 then 'lt'
    -- both values are equal, within 10%
    WHEN abs(1-jr) < 0.1 AND abs(1-tr) < 0.1 then 'eq'
    else null
  end as v
  from crosses
)
select *
from diffs
where v NOT NULL
;

select 
	ls, rs, v,
	printf('%,d', pl.CNTY_TAXABLE_VALUE) as lt,
	printf('%,d', pr.CNTY_TAXABLE_VALUE) as rt,
	printf('%.2f', tr) as tr,
	printf('%,d', pl.CNTY_JST_VALUE) as lj,
	printf('%,d', pr.CNTY_JST_VALUE) as rj, 
	printf('%.2f', jr) as jr,
	pl.SITE_ADDRESS || ', ' || pl.STR_CITY || ' ' || pl.STR_ZIP as la,
	pr.SITE_ADDRESS || ', ' || pr.STR_CITY || ' ' || pr.STR_ZIP as ra
	
from petey
inner join RP_PROPERTY_INFO as pl ON petey.ls = pl.STRAP
inner join RP_PROPERTY_INFO as pr ON petey.rs = pr.STRAP
order by random()
limit 10;

select v, count(*) from petey group by 1;