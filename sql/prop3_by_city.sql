/**
Calculates the total tax impact of Prop 3

sqlite3 -readonly pinellas_indexed.sqlite < sql/prop3_city_districts.sql > sql/prop3_city_districts.md

*/

CREATE TEMP TABLE cities AS
WITH _cities AS (
  select
    CASE 
      WHEN city = "" THEN "n/a" 
      WHEN city = "ST. PETERSBURG" THEN "ST PETERSBURG"
      ELSE city 
    END AS city,
    count(*) as properties,
    sum(units) as households,
    sum(CASE WHEN units = 1 THEN 1 ELSE 0 END) as sfh,
    sum(tax_2026) as TAX_2026,
    sum(tax_2027) as TAX_2027,
    sum(tax_2028) as TAX_2028
  from PROP_3
  GROUP BY 1
) SELECT
  row_number() OVER (ORDER BY city) as row_no,
  *, 
  100.0 * sfh / households as pct_sfh FROM _cities;

CREATE TEMP TABLE totals AS
SELECT
  -1 as row_no,
  "Pinellas County" as city,
  count(*) as properties,
  sum(units) as households,
  sum(CASE WHEN units = 1 THEN 1 ELSE 0 END) as sfh,
  sum(tax_2026) as TAX_2026,
  sum(tax_2027) as TAX_2027,
  sum(tax_2028) as TAX_2028,
  100.0 * sum(CASE WHEN units = 1 THEN 1 ELSE 0 END) / sum(units) as pct_sfh
FROM PROP_3
UNION ALL select * from cities
ORDER BY row_no;


.headers off
.mode list
select '
# City Totals

 - properties: total properties registered with the county that have at least 1 living unit and are not temporary (hotels, hospitals, etc).
 - households: sum of the living units across the properties, such as single-family homes, condos, apartment units, etc.
 - SFH: sum of single-family homes, how many properties have only a single unit (condos will count towards this).
 - Pct SFH: Number of SFH divided by the number of total households.
 - Tax_202X: Total property tax gathered for the given year, across County, School, and Municipal taxes.
 - Tax_202X_Diff: Tax change for the given year from the previous year.

';
.headers on
.mode markdown

SELECT 
  city,
  format('%,d', properties) as properties,
  format('%,d', households) as households,
  format('%,d', sfh) as SFH,
  format('%.2f%', pct_sfh) as "Pct SFH",
	format('$%,.2f', TAX_2026) AS TAX_2026,
	format('$%,.2f', TAX_2027) AS TAX_2027,
	format('$%,.2f', TAX_2026 - TAX_2027) AS TAX_2027_DIFF,
	format('%,.2f%', 100.0 * (TAX_2026 - TAX_2027) / TAX_2026) AS PCT_TAX_2027_DIFF,
	format('$%,.2f', TAX_2028) AS TAX_2028,
	format('$%,.2f', TAX_2026 - TAX_2028) AS TAX_2028_DIFF,
	format('%,.2f%', 100.0 * (TAX_2026 - TAX_2028) / TAX_2026) AS PCT_TAX_2028_DIFF
FROM totals order by row_no;

CREATE TEMP TABLE city_loss_by_household AS SELECT
  row_no, city, properties, households, sfh, pct_sfh,
  -- taxes changed
  tax_2026 - tax_2027 as tax_diff_2027,
  tax_2026 - tax_2028 as tax_diff_2028,
  -- taxes lost per sfh
  (tax_2026 - tax_2027) / sfh as sfh_savings_2027,
  (tax_2026 - tax_2028) / sfh as sfh_savings_2028,
  -- taxes made up across all households
  (tax_2026 - tax_2027) / sfh * households as makeup_2027,
  (tax_2026 - tax_2028) / sfh * households as makeup_2028
from totals;

.headers off
.mode list

select '
# Average HH Impact

 - properties: total properties registered with the county that have at least 1 living unit and are not temporary (hotels, hospitals, etc).
 - households: sum of the living units across the properties, such as single-family homes, condos, apartment units, etc.
 - SFH: sum of single-family homes, how many properties have only a single unit (condos will count towards this).
 - Pct SFH: Number of SFH divided by the number of total households.
 - SFH Savings: How much the average SFH will save.

';
.headers on
.mode markdown

SELECT city,
  format('%,d', properties) as properties,
  format('%,d', households) as households,
  format('%,d', sfh) as sfh,
  format('%.2f%', pct_sfh) as 'Pct SFH',
  format('%,.2f', sfh_savings_2027) as 'SFH Savings 2027',
  format('%,.2f', sfh_savings_2028) as 'SFH Savings 2028'
FROM city_loss_by_household ORDER BY row_no;

.headers off
.mode list

select '
# City Tax Loss and Makeup

';
.headers on
.mode markdown

SELECT
  city,
  format('%,d', properties) as Properties,
  format('%,d', households) as Households,
	format('%,.2f', tax_diff_2027) AS 'Tax Loss 2027',
  format('%,.2f', makeup_2027) AS 'Tax Makeup 2027',
  format('%,.2f', makeup_2027 - tax_diff_2027) AS 'Net 2027',
	format('%,.2f', tax_diff_2028) AS 'Tax Loss 2028',
  format('%,.2f', makeup_2028) AS 'Tax Makeup 2028',
  format('%,.2f', makeup_2028 - tax_diff_2028) AS 'Net 2028'
FROM city_loss_by_household ORDER BY row_no;

.headers off
.mode list

select '
# City Household Impact

';
.headers on
.mode markdown
SELECT
  city, 
  format('%,.2f', (makeup_2027 - tax_diff_2027) / households ) AS 'HH Impact 2027',
  format('%,.2f', (makeup_2028 - tax_diff_2028) / households ) AS 'HH Impact 2028'
FROM city_loss_by_household;