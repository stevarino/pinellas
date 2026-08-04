import os
import yaml
import json

import urllib.parse
import urllib.request

import zipfile
import io
import sqlite3
import csv

from shapely import Point, Polygon

from manifest import Manifest, Region
from geojson import GeoJSON
from db_wrapper import DBWrapper

paths = ['csvs', 'shapes']

csv_url = 'https://www.pcpao.gov/dal/databasefile/downloadDatabaseFile'
headers = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0)'}

    

def make_directory(path: str):
  try:
    os.mkdir(path)
  except OSError as e:
    if e.errno != 17:
      raise e

def initialize_csv(dbw: DBWrapper, manifest: Manifest, name: str):
  filename = f'csvs/{name}.csv'
  if not os.path.exists(filename):
    download_csv(name)
  if name not in dbw.tables:
    with open(filename, encoding='ISO-8859-1') as fp:
      dbw.ingest_csv(manifest.property_field, name, csv.DictReader(fp))

def download_csv(name: str):
  print(f'Downloading {name}.csv')
  data = urllib.parse.urlencode({'hdn_tbl_name': name, 'hdn_ftype': 'csv'}).encode('utf-8')
  req = urllib.request.Request(csv_url, data, headers=headers)
  with urllib.request.urlopen(req) as res:
    stream = io.BytesIO(res.read())
  with zipfile.ZipFile(stream, 'r') as archive:
    archive.extractall(path='csvs')

def download_shape(collection: str, name: str, url: str):
  filename = f'shapes/{collection}/{name}.json'
  if (os.path.exists(filename)):
    return filename
  print(f'Downloading {filename}')
  req = urllib.request.Request(url, headers=headers)
  with urllib.request.urlopen(req) as res:
    with open(filename, 'w') as fp:
      fp.write(res.read().decode('utf-8'))
  return filename

def setup_regions(dbw: DBWrapper, manifest: Manifest):
  for coll in manifest.district_collections:
    make_directory(f'shapes/{coll.name}')
    for district in coll.districts:
      filename = download_shape(coll.name, district.name, district.geojson)
      with open(filename, 'r') as fp:
        geojson = GeoJSON(**json.load(fp))
      for feature in geojson.features:
        label = district.format % feature.properties[district.property_key]
        params = [coll.name, district.name, label]
        dbw.execute('''
          INSERT INTO Regions (collection, district, region) VALUES (?, ?, ?)
          ON CONFLICT DO NOTHING
        ''', params)
        rowid = dbw.execute('''
          SELECT id FROM Regions WHERE collection = ? AND district = ? AND region = ?;
        ''', params).fetchone()[0]
        region = Region(rowid, label)
        for poly in feature.geometry.get_polygons():
          region.polygons.append(Polygon(poly))
        district.regions.append(region)

def scan_regions(dbw: DBWrapper, manifest: Manifest):
  sql = 'INSERT INTO RegionedProperty (region, property) VALUES (?, ?)'
  for coll in manifest.district_collections:
    for district in coll.districts:
      cnt = dbw.execute('''
        SELECT Count(*) 
        FROM RegionedProperty AS rp
          INNER JOIN Regions AS r ON rp.region = r.id
        WHERE r.collection = ? AND r.district = ? LIMIT 1
      ''', [coll.name, district.name]).fetchone()[0]
      if cnt == 1:
        print(f'Found properties for {coll.name} / {district.name}, skipping...')
        continue
      minLat, minLon, maxLat, maxLon = district.get_bounds()
      results = dbw.execute(f'''
        SELECT
          {manifest.property_field},
          CAST({manifest.property_location.lat} AS REAL),
          CAST({manifest.property_location.lon} AS REAL)
        FROM {manifest.property_location.table}
        WHERE 1=1
          AND CAST({manifest.property_location.lat} AS REAL) >= ?
          AND CAST({manifest.property_location.lat} AS REAL) <= ?
          AND CAST({manifest.property_location.lon} AS REAL) >= ?
          AND CAST({manifest.property_location.lon} AS REAL) <= ?
      ''', [minLat, maxLat, minLon, maxLon]).fetchall()
      print(f'Checking {len(results)} properties for {coll.name} / {district.name}...')

      for (prop, lat, long) in results:
        regions = list(district.find_regions((lat, long)))
        if regions:
          dbw.executemany(sql, zip(regions, [int(prop)] * len(regions)))

def main():
  for path in paths:
    make_directory(path)
  with open('manifest.yaml', 'r') as fp:
    manifest = Manifest(**yaml.safe_load(fp))

  with sqlite3.connect(manifest.database) as db:
    dbw = DBWrapper(db)
    for table in manifest.tables:
      initialize_csv(dbw, manifest, table)
    setup_regions(dbw, manifest)
    scan_regions(dbw, manifest)
  
if __name__ == '__main__':
  main()