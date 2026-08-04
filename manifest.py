from dataclasses import dataclass, field
from shapely import Point, Polygon
from typing import cast
import math

"""
A Manifest is a config file with GeoJson data...
which contains DistrictCollections which are a set of orthoganal districts... 
which contains Districts which are a set of areas definend by a geojson file...
which contain Regions which are a set of Polygons from a GeoJson file...
which contain Polygons, which can be checked for points...
"""

@dataclass
class Region:
  """
  A Polygon or MultiPolygon from a geojson file representing a region.
  """
  index: int
  label: str
  polygons: list[Polygon] = field(default_factory=list)
  tests: int = 0

  def add_polygon(self, polygon: list[tuple[float, float]]):
    self.polygons.append(Polygon(polygon))

  def contains_point(self, latlong: tuple[float, float]):
    for polygon in self.polygons:
      self.tests += 1
      if polygon.contains(Point(latlong[1], latlong[0])):
        return True
    return False

@dataclass
class District:
  """
  A set of regions defined from a singular geojson file.
  """
  name: str
  property_key: str
  geojson: str
  format: str = '%s'
  regions: list[Region] = field(default_factory=list)

  def get_bounds(self):
    bounds = [math.inf, math.inf, -math.inf, -math.inf]
    for region in self.regions:
      for polygon in region.polygons:
        new_bounds = polygon.bounds
        bounds[0] = min(bounds[0], new_bounds[0])
        bounds[1] = min(bounds[1], new_bounds[1])
        bounds[2] = max(bounds[2], new_bounds[2])
        bounds[3] = max(bounds[3], new_bounds[3])
    assert not any(math.isinf(n) for n in bounds)
    # switch from lon/lat to lat/lon
    return bounds[1], bounds[0], bounds[3], bounds[2]

  def find_regions(self, latlong: tuple[float, float]):
      for region in self.regions or []:
        if region.contains_point(latlong):
          yield region.index


@dataclass
class DistrictCollection:
  """
  An orthogonal geographic set of regions, ie neighborhoods, city council
  districts, or US Congress districts.
  """
  name: str
  districts: list[District]

  def find_regions(self, latlong: tuple[float, float]):
    for district in self.districts:
      for polygon_set in district.regions or []:
        if polygon_set.contains_point(latlong):
          yield polygon_set.index


  def __post_init__(self):
    if type(self.districts[0]) == dict:
      self.districts = [District(**d) for d in cast(list[dict], self.districts)]

@dataclass
class PropertyLocation:
  table: str
  lat: str
  lon: str

@dataclass
class Manifest:
  database: str
  property_field: str
  property_location: PropertyLocation
  tables: list[str]
  district_collections: list[DistrictCollection]

  def __post_init__(self):
    if type(self.property_location) == dict:
      self.property_location = PropertyLocation(**self.property_location)
    if type(self.district_collections[0] == dict):
      self.district_collections = [DistrictCollection(**dc) for dc in cast(list[dict], self.district_collections)]
