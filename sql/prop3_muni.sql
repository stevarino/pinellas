.headers off
.mode list

select '
# Municipal Tax Breakdown

';
.headers on
.mode markdown

WITH TEMP AS (
  SELECT 
    city,
    count(*) as properties,
    sum(units) as units,
    SUM(MUNI_TAX_2026) as TAX_2026,
    SUM(MUNI_TAX_2027) as TAX_2027,
    SUM(MUNI_TAX_2028) as TAX_2028
  FROM PROP_3
  GROUP BY city
)
SELECT
  city,
  format('%,d', properties) as properties,
  format('%,d', units) as units,
  format('%,.2f', TAX_2026) as TAX_2026,
  format('%,.2f', TAX_2027) as TAX_2027,
  format('%,.2f', TAX_2028) as TAX_2028,
  format('%,.2f', TAX_2026 - TAX_2027) as DIFF_2027,
  format('%,.2f%', 100 * (TAX_2026 - TAX_2027) / TAX_2026) as DIFF_2027_P,
  format('%,.2f', TAX_2026 - TAX_2028) as DIFF_2028,
  format('%,.2f%', 100 * (TAX_2026 - TAX_2028) / TAX_2026) as DIFF_2028_P
FROM TEMP
