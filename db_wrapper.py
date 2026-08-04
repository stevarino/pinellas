from itertools import batched
import sqlite3

from typing import Any, Iterable, Mapping, cast, Sequence

type db_field = str | float | int | bool
type db_params = Sequence[db_field] | tuple[db_field]

class DBWrapper:
  create_tables = {
    'Properties': '(id INTEGER PRIMARY KEY, property VARCHAR)',
    'Regions': '(id INTEGER PRIMARY KEY, collection VARCHAR, district VARCHAR, region VARCHAR, UNIQUE (collection, district, region))',
    'RegionedProperty': '(region INTEGER, property INTEGER, UNIQUE (region, property))',
  }
  def __init__(self, database_path: str):
    self.db = sqlite3.connect(database_path)

    self.curr = self.db.cursor()
    for name, cols in self.create_tables.items():
      self.execute(f'CREATE TABLE IF NOT EXISTS {name} {cols}')
    self.properties = self.read_properties()
    self.tables = set([row[0] for row in self.execute(
      'SELECT name FROM sqlite_master WHERE type="table";'
    ).fetchall()])

  def __enter__(self):
    return self

  def __exit__(self, *args):
    self.db.close()

  def execute(self, sql: str, params: db_params = []):
    return self.curr.execute(sql, params)

  def executemany(self, sql: str, rows: Iterable[db_params]):
    return self.curr.executemany(sql, rows)

  def read_properties(self, ids: None|list[str] = None):
    sql = 'SELECT id, property FROM Properties'
    if ids:
      sql += f' WHERE property IN ("{'", "'.join(ids)}")'
    return {
      row[1]: row[0] for row in 
      self.curr.execute(sql).fetchall()
    }

  def insert_properties(self, properties: list[str]):
    missing = [s for s in properties if s not in self.properties]
    if not missing:
      return
    self.executemany('INSERT INTO Properties (property) VALUES (?)', [[s] for s in missing])
    self.properties.update(self.read_properties(missing))


  def ingest_csv(self, property_field: str, table: str, data: Iterable[Mapping[str, db_field]]):
    if table in self.tables:
      print('Already read table: ', table)
      return
    self.tables.add(table)

    fields = []

    cnt = 0
    for i, rows in enumerate(batched(data, 100)):
      
      if i == 0:
        for f in rows[0].keys():
          if f not in fields:
            fields.append(f)

        field_defs = []
        for field in fields:
          if field == property_field:
            field_defs.append(f'{field} INTEGER')
          else:
            field_defs.append(f'{field} VARCHAR')
        self.execute(f'''
          CREATE TABLE {table} ({','.join(field_defs)});
        ''')

      insert_sql = f'INSERT INTO {table} ({','.join(fields)}) VALUES ({','.join(['?'] * len(fields))});'

      if property_field in fields:
        props = cast(list[str], [r[property_field] for r in rows])
        self.insert_properties(props)

      cnt += len(rows)
      inserts = []
      for row in rows:
        inserts.append([row[f] if f != property_field else self.properties[row[f]]
                        for f in fields])
      self.executemany(insert_sql, inserts)

    print(f'Inserted {cnt} rows')
    if property_field in fields:
      self.execute(f'CREATE INDEX IF NOT EXISTS {table}__PROPERTY ON {table} ({property_field})')
