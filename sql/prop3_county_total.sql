/**
Calculates the total tax impact of Prop 3

sqlite3 -readonly pinellas_indexed.sqlite < sql/prop3_county_total.sql > sql/prop3_county_total.md
*/

.headers off
.mode column
select "
# County Totals

";
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
	format("$%,.2f", TAX_2026) AS TAX_2026,
	format("$%,.2f", TAX_2027) AS TAX_2027,
	format("$%,.2f", TAX_2028) AS TAX_2028,
	format("$%,.2f", TAX_2026 - TAX_2027) AS TAX_2027_DIFF,
	format("$%,.2f", TAX_2026 - TAX_2028) AS TAX_2028_DIFF
FROM totals;