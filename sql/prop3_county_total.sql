/**
Calculates the total tax impact of Prop 3

sqlite3 -markdown -readonly pinellas_indexed.sqlite < sql/prop3_county_total.sql

|     TAX_2026      |     TAX_2027      |     TAX_2028      |  TAX_2027_DIFF  |   TAX_2028_DIFF   |
|-------------------|-------------------|-------------------|-----------------|-------------------|
| $7,975,666,332.00 | $7,281,377,384.45 | $6,849,782,958.20 | $694,288,947.55 | $1,125,883,373.80 |
*/

with totals as (
	select 
		sum(tax_2026) as TAX_2026,
		sum(tax_2027) as TAX_2027,
		sum(tax_2028) as TAX_2028
	from PROP_3
)
SELECT 
	format("$%,.2f", TAX_2026) AS TAX_2026,
	format("$%,.2f", TAX_2027) AS TAX_2027,
	format("$%,.2f", TAX_2028) AS TAX_2028,
	format("$%,.2f", TAX_2026 - TAX_2027) AS TAX_2027_DIFF,
	format("$%,.2f", TAX_2026 - TAX_2028) AS TAX_2028_DIFF
FROM totals;