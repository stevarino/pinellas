/**
Calculates the total tax impact of Prop 3

sqlite3 -markdown -readonly pinellas_indexed.sqlite < sql/prop3_city_districts.sql

| district |  units  | total_loss_2027 | total_loss_2028 | loss_2027 | loss_2028 |
|----------|---------|-----------------|-----------------|-----------|-----------|
| sp       | 4388496 | 179,810,320.89  | 300,639,034.51  | 40.97     | 68.51     |

|         District         | Households | Tax Reduction 2027 | Tax Reduction 2028 | Tax Makeup 2027 | Tax Makeup 2028 |  Impact 2027   |  Impact 2028   |
|--------------------------|------------|--------------------|--------------------|-----------------|-----------------|----------------|----------------|
| ST PETERSBURG DISTRICT 1 | 487680     | 30,694,874.54      | 49,047,652.83      | 19,981,765.35   | 33,409,086.93   | -10,713,109.19 | -15,638,565.90 |
| ST PETERSBURG DISTRICT 2 | 606546     | 10,023,939.12      | 16,180,879.08      | 24,852,074.81   | 41,552,140.83   | 14,828,135.69  | 25,371,261.75  |
| ST PETERSBURG DISTRICT 3 | 471480     | 29,124,905.54      | 52,300,943.90      | 19,318,000.99   | 32,299,287.04   | -9,806,904.55  | -20,001,656.86 |
| ST PETERSBURG DISTRICT 4 | 528060     | 27,879,419.89      | 48,639,465.77      | 21,636,259.45   | 36,175,365.90   | -6,243,160.44  | -12,464,099.87 |
| ST PETERSBURG DISTRICT 5 | 544650     | 24,509,463.51      | 41,046,377.29      | 22,316,003.31   | 37,311,883.19   | -2,193,460.19  | -3,734,494.09  |
| ST PETERSBURG DISTRICT 6 | 777840     | 16,675,805.12      | 30,249,629.82      | 31,870,522.38   | 53,286,835.99   | 15,194,717.27  | 23,037,206.18  |
| ST PETERSBURG DISTRICT 7 | 479970     | 14,936,274.42      | 23,520,165.05      | 19,665,862.68   | 32,880,904.39   | 4,729,588.26   | 9,360,739.34   |
| ST PETERSBURG DISTRICT 8 | 492270     | 25,965,638.75      | 39,653,920.78      | 20,169,831.91   | 33,723,530.23   | -5,795,806.84  | -5,930,390.55  |

|         District         |  Impact 2027   |  Impact 2028   |
|--------------------------|----------------|----------------|
| ST PETERSBURG DISTRICT 1 | -10,713,109.19 | -15,638,565.90 |
| ST PETERSBURG DISTRICT 2 | 14,828,135.69  | 25,371,261.75  |
| ST PETERSBURG DISTRICT 3 | -9,806,904.55  | -20,001,656.86 |
| ST PETERSBURG DISTRICT 4 | -6,243,160.44  | -12,464,099.87 |
| ST PETERSBURG DISTRICT 5 | -2,193,460.19  | -3,734,494.09  |
| ST PETERSBURG DISTRICT 6 | 15,194,717.27  | 23,037,206.18  |
| ST PETERSBURG DISTRICT 7 | 4,729,588.26   | 9,360,739.34   |
| ST PETERSBURG DISTRICT 8 | -5,795,806.84  | -5,930,390.55  |

|         District         | Impact 2027 | Impact 2028 |
|--------------------------|-------------|-------------|
| ST PETERSBURG DISTRICT 1 | -21.97      | -32.07      |
| ST PETERSBURG DISTRICT 2 | 24.45       | 41.83       |
| ST PETERSBURG DISTRICT 3 | -20.80      | -42.42      |
| ST PETERSBURG DISTRICT 4 | -11.82      | -23.60      |
| ST PETERSBURG DISTRICT 5 | -4.03       | -6.86       |
| ST PETERSBURG DISTRICT 6 | 19.53       | 29.62       |
| ST PETERSBURG DISTRICT 7 | 9.85        | 19.50       |
| ST PETERSBURG DISTRICT 8 | -11.77      | -12.05      |

*/

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

SELECT district,
  format("%d", total_units) as units,
  format("%,.2f", total_loss_2027) as total_loss_2027,
  format("%,.2f", total_loss_2028) as total_loss_2028,
  format("%,.2f", loss_2027) as loss_2027,
  format("%,.2f", loss_2028) as loss_2028
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

SELECT
  region as District,
  format('%d', units) as Households,
	format("%,.2f", savings_2027) AS "Tax Reduction 2027",
	format("%,.2f", savings_2028) AS "Tax Reduction 2028",
  format("%,.2f", makeup_2027) AS "Tax Makeup 2027",
  format("%,.2f", makeup_2028) AS "Tax Makeup 2028",
  format("%,.2f", makeup_2027 - savings_2027) AS "Impact 2027",
  format("%,.2f", makeup_2028 - savings_2028) AS "Impact 2028"
FROM district_totals;

SELECT
  region as District,
  format("%,.2f", (makeup_2027 - savings_2027) ) AS "Impact 2027",
  format("%,.2f", (makeup_2028 - savings_2028) ) AS "Impact 2028"
FROM district_totals;

SELECT
  region as District,
  format("%,.2f", (makeup_2027 - savings_2027) / units ) AS "Impact 2027",
  format("%,.2f", (makeup_2028 - savings_2028) / units ) AS "Impact 2028"
FROM district_totals;