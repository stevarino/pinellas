.headers on
.mode markdown


SELECT DISTINCT m.name as 'table', ti.name as 'column', ti.type
FROM sqlite_schema AS m,
  pragma_table_info(m.name) AS ti
WHERE m.type='table'
ORDER BY 1, 2;