import '../../core/utils/text_sanitizer.dart';

class LayerFeature {
  const LayerFeature({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.properties,
  });

  final String id;
  final double latitude;
  final double longitude;
  final Map<String, String> properties;

  static LayerFeature? tryParse(Object? json) {
    if (json case {
      'id': final String id,
      'geometry': {
        'type': 'Point',
        'coordinates': [final num longitude, final num latitude, ...],
      },
    }) {
      return LayerFeature(
        id: id,
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
        properties: _parseProperties(json['properties']),
      );
    }
    return null;
  }

  String? operator [](String key) {
    final value = properties[key];
    return value == null || value.isEmpty ? null : value;
  }

  Map<String, dynamic> toGeoJson() => {
    'type': 'Feature',
    'id': id,
    'geometry': {
      'type': 'Point',
      'coordinates': [longitude, latitude],
    },
    'properties': properties,
  };

  static Map<String, String> _parseProperties(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final MapEntry(:key, :value) in raw.entries)
        if (value != null) '$key': TextSanitizer.clean('$value'),
    };
  }
}
