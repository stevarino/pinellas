/**
Calculates the total tax impact of Prop 3

sqlite3 -readonly pinellas_indexed.sqlite < sql/prop3_city_districts.sql > sql/prop3_city_districts.md

*/

.headers off
.mode column
select '
# County Totals

';
.headers on
.mode markdown

with totals as (
	select 
		sum(tax_2026) as TAX_2026,
		sum(tax_2027) as TAX_2027,
		sum(tax_2028) as TAX_2028
	from PROP_3
)
SELECT 
	format('$%,.2f', TAX_2026) AS TAX_2026,
	format('$%,.2f', TAX_2027) AS TAX_2027,
	format('$%,.2f', TAX_2028) AS TAX_2028,
	format('$%,.2f', TAX_2026 - TAX_2027) AS TAX_2027_DIFF,
	format('$%,.2f', TAX_2026 - TAX_2028) AS TAX_2028_DIFF
FROM totals;

CREATE TEMP TABLE totals AS SELECT 
  rg.district AS district,
  rg.region AS region,
  sum(units) as units,
  sum(tax_2026) AS TAX_2026,
  sum(tax_2027) AS TAX_2027,
  sum(tax_2028) AS TAX_2028
FROM PROP_3 AS p3
CROSS JOIN RegionedProperty AS rp ON p3.property = rp.property
INNER JOIN Regions AS rg ON rg.id = rp.region
GROUP BY 1,2;

CREATE TEMP TABLE district_tax_loss_by_household AS SELECT
  district, sum(units) as total_units,
  sum(tax_2026 - tax_2027) as total_loss_2027,
  sum(tax_2026 - tax_2028) as total_loss_2028,
  sum(tax_2026 - tax_2027) / sum(units) as loss_2027,
  sum(tax_2026 - tax_2028) / sum(units) as loss_2028
from totals
GROUP BY 1;

.headers off
.mode column
select '
# District Tax Loss

';
.headers on
.mode markdown

SELECT district,
  format('%d', total_units) as units,
  format('%,.2f', total_loss_2027) as total_loss_2027,
  format('%,.2f', total_loss_2028) as total_loss_2028,
  format('%,.2f', loss_2027) as loss_2027,
  format('%,.2f', loss_2028) as loss_2028
FROM district_tax_loss_by_household;

CREATE TEMP TABLE district_totals AS SELECT
  t.district, t.region, t.units,
  tax_2026 - tax_2027 as savings_2027,
  tax_2026 - tax_2028 as savings_2028,
  cl.loss_2027 * t.units as makeup_2027,
  cl.loss_2028 * t.units as makeup_2028
FROM totals AS t
INNER JOIN district_tax_loss_by_household AS cl
  ON t.district = cl.district;

.headers off
.mode column
select '
# District Tax Impact

';
.headers on
.mode markdown

SELECT
  region as District,
  format('%d', units) as Households,
	format('%,.2f', savings_2027) AS 'Tax Reduction 2027',
	format('%,.2f', savings_2028) AS 'Tax Reduction 2028',
  format('%,.2f', makeup_2027) AS 'Tax Makeup 2027',
  format('%,.2f', makeup_2028) AS 'Tax Makeup 2028',
  format('%,.2f', makeup_2027 - savings_2027) AS 'Impact 2027',
  format('%,.2f', makeup_2028 - savings_2028) AS 'Impact 2028'
FROM district_totals;


.headers off
.mode column
select '
# District Total Impact

';
.headers on
.mode markdown

SELECT
  region as District,
  format('%,.2f', (makeup_2027 - savings_2027) ) AS 'Impact 2027',
  format('%,.2f', (makeup_2028 - savings_2028) ) AS 'Impact 2028'
FROM district_totals;


.headers off
.mode column
select '
# District Household Impact

';
.headers on
.mode markdown
SELECT
  region as District,
  format('%,.2f', (makeup_2027 - savings_2027) / units ) AS 'Impact 2027',
  format('%,.2f', (makeup_2028 - savings_2028) / units ) AS 'Impact 2028'
FROM district_totals;