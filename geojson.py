from dataclasses import dataclass
from typing import cast, Any

@dataclass
class GeoJSONMultipolygon:
  type: str
  coordinates: list[list[list[tuple[float, float]]]]

  def get_polygons(self):
    for coord in self.coordinates:
      assert len(coord) == 1, f'coord len == ${len(coord)}'
      yield coord[0]

  def __post_init__(self):
    assert self.type == 'MultiPolygon', self.type

@dataclass
class GeoJSONPolygon:
  type: str
  coordinates: list[list[tuple[float, float]]]

  def get_polygons(self):
    assert len(self.coordinates) == 1, f'coord len == ${len(self.coordinates)}'
    yield self.coordinates[0]

  def __post_init__(self):
    assert self.type == 'Polygon', self.type


@dataclass
class GeoJSONFeature:
  type: str
  id: int
  properties: dict[str, str|int|float]
  geometry: GeoJSONMultipolygon | GeoJSONPolygon

  def __post_init__(self):
    assert self.type == 'Feature'
    if type(self.geometry) == dict:
      if self.geometry['type'] == 'MultiPolygon':
        self.geometry = GeoJSONMultipolygon(**cast(dict[str, Any], self.geometry))
      elif self.geometry['type'] == 'Polygon':
        self.geometry = GeoJSONPolygon(**cast(dict[str, Any], self.geometry))
      else:
        raise ValueError(self.geometry['type'])


@dataclass
class GeoJSON:
  type: str
  features: list[GeoJSONFeature]

  def __post_init__(self):
    if type(self.features[0]) == dict:
      self.features = [GeoJSONFeature(**cast(dict, f)) for f in self.features]
    assert self.type == 'FeatureCollection', self.type
