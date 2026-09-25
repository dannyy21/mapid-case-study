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

  Map<String, dynamic> toGeoJson() => {
    'type': 'FeatureCollection',
    'features': [for (final feature in features) feature.toGeoJson()],
  };
}
