import 'dart:math' as math;

import 'layer_feature.dart';

class MapLayer {
  const MapLayer({
    required this.id,
    required this.name,
    required this.features,
  });

  final String id;
  final String name;
  final List<LayerFeature> features;

  factory MapLayer.fromJson(Map<String, dynamic> json) {
    if (json case {
      'layer_id': final String id,
      'features': final List<dynamic> features,
    }) {
      final name = json['layer_name'];
      return MapLayer(
        id: id,
        name: name is String && name.isNotEmpty ? name : 'Layer',
        features: features
            .map(LayerFeature.tryParse)
            .nonNulls
            .toList(growable: false),
      );
    }
    throw const FormatException('Missing layer_id or features.');
  }

  LayerFeature? featureById(String id) {
    for (final feature in features) {
      if (feature.id == id) return feature;
    }
    return null;
  }

  bool isNear(double latitude, double longitude, {double marginDegrees = 0.1}) {
    if (features.isEmpty) return false;
    final latitudes = features.map((f) => f.latitude);
    final longitudes = features.map((f) => f.longitude);
    return latitude >= latitudes.reduce(math.min) - marginDegrees &&
        latitude <= latitudes.reduce(math.max) + marginDegrees &&
        longitude >= longitudes.reduce(math.min) - marginDegrees &&
        longitude <= longitudes.reduce(math.max) + marginDegrees;
  }

  Map<String, dynamic> toGeoJson() => {
    'type': 'FeatureCollection',
    'features': [for (final feature in features) feature.toGeoJson()],
  };
}
