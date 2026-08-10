.headers off
.mode list

select '
# Housing with No Tax

';

.headers on
.mode markdown

CREATE TEMP TABLE p3 AS 
  SELECT 
    CNTY_TAXABLE_VALUE,
    CNTY_TAXABLE_VALUE_2027,
    CNTY_TAXABLE_VALUE_2028,
    city
  FROM PROP_3 AS p3 INNER JOIN Residences AS r ON r.property = p3.property
  WHERE homestead = 'Yes';

CREATE TEMP TABLE costs AS 
SELECT
  city,
  count(*) as units,
  SUM(CASE WHEN CNTY_TAXABLE_VALUE = 0 THEN 1 ELSE 0 END) AS VAL_0_2026,
  SUM(CASE WHEN CNTY_TAXABLE_VALUE_2027 = 0 THEN 1 ELSE 0 END) AS VAL_0_2027,
  SUM(CASE WHEN CNTY_TAXABLE_VALUE_2028 = 0 THEN 1 ELSE 0 END) AS VAL_0_2028
FROM p3 GROUP BY 1;

SELECT
  'Pinellas County' as city,
  sum(units) as units,
  sum(VAL_0_2026) as '2026',
  sum(VAL_0_2027) as '2027',
  sum(VAL_0_2028) as '2028'
  FROM costs
UNION ALL
SELECT 
  CASE WHEN city = '' THEN 'n/a' ELSE city END as city,
  units,
  Format('%,3d', VAL_0_2026) as '2026',
  Format('%,3d', VAL_0_2027) as '2027',
  Format('%,3d', VAL_0_2028) as '2028'
FROM costs GROUP BY 1;

.headers off
.mode list

select '
# Percent of Housing with No Tax

';

.headers on
.mode markdown

WITH total AS (
  SELECT city, Count(*) as cnt FROM p3 GROUP BY 1
)
SELECT 
  'Pinellas County' as city,
  sum(units) as units,
  Format('%.2f%', 100.0 * Sum(VAL_0_2026) / Sum(units)) as '2026',
  Format('%.2f%', 100.0 * Sum(VAL_0_2027) / Sum(units)) as '2027',
  Format('%.2f%', 100.0 * Sum(VAL_0_2028) / Sum(units)) as '2028'
FROM costs
UNION ALL
SELECT 
  CASE WHEN costs.city = '' THEN 'n/a' ELSE costs.city END as city,
  units,
  Format('%.2f%', 100.0 * VAL_0_2026 / cnt) as '2026',
  Format('%.2f%', 100.0 * VAL_0_2027 / cnt) as '2027',
  Format('%.2f%', 100.0 * VAL_0_2028 / cnt) as '2027'
FROM costs INNER JOIN total ON costs.city = total.city
WHERE VAL_0_2026 <> 0 OR VAL_0_2027 <> 0 OR VAL_0_2028 <> 0
GROUP BY 1;