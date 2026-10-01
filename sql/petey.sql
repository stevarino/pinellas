select 
	ls, rs, v,
	printf('%.2f', tr) as tr,
	printf('%.2f', jr) as jr,
	printf("%,d", pl.CNTY_JST_VALUE) as lj,
	printf("%,d", pl.CNTY_TAXABLE_VALUE) as lt,
	printf("%,d", pr.CNTY_JST_VALUE) as rj,
	printf("%,d", pr.CNTY_TAXABLE_VALUE) as rt, 
	pl.SITE_ADDRESS || ", " || pl.STR_CITY || " " || pl.STR_ZIP as la,
	pr.SITE_ADDRESS || ", " || pr.STR_CITY || " " || pr.STR_ZIP as ra
	
from petey
inner join RP_PROPERTY_INFO as pl ON petey.ls = pl.STRAP
inner join RP_PROPERTY_INFO as pr ON petey.rs = pr.STRAP
order by random();