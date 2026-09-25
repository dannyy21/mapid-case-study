import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';

import '../../data/models/feature_attribute.dart';
import '../../data/models/layer_feature.dart';
import '../../data/models/map_layer.dart';
import '../../data/models/device_location.dart';

class MapLayerRenderer {
  MapLayerRenderer(this._controller);

  static const pointLayerId = 'mapid-points';
  static const labelLayerId = 'mapid-labels';
  static const _selectedLayerId = 'mapid-selected';
  static const _sourceId = 'mapid-source';
  static const _userSourceId = 'user-location-source';
  static const _userHaloLayerId = 'user-location-halo';
  static const _userDotLayerId = 'user-location-dot';
  static const _userLocationZoom = 15.0;
  static const _emptyCollection = {
    'type': 'FeatureCollection',
    'features': <Map<String, dynamic>>[],
  };
  static const _cameraPadding = 64.0;
  static const _singlePointZoom = 15.0;
  static const _noSelectionFilter = [
    '==',
    ['id'],
    '',
  ];

  final MapLibreMapController _controller;

  Future<void> prepare() async {
    await _controller.addGeoJsonSource(_userSourceId, _emptyCollection);
    await _controller.addCircleLayer(
      _userSourceId,
      _userHaloLayerId,
      const CircleLayerProperties(
        circleRadius: 18,
        circleColor: '#1E88E5',
        circleOpacity: 0.2,
      ),
      enableInteraction: false,
    );
    await _controller.addCircleLayer(
      _userSourceId,
      _userDotLayerId,
      const CircleLayerProperties(
        circleRadius: 7,
        circleColor: '#1E88E5',
        circleStrokeWidth: 3,
        circleStrokeColor: '#FFFFFF',
      ),
      enableInteraction: false,
    );
  }

  Future<void> showLayer(MapLayer layer) async {
    await _controller.addGeoJsonSource(_sourceId, layer.toGeoJson());
    await _controller.addCircleLayer(
      _sourceId,
      pointLayerId,
      const CircleLayerProperties(
        circleRadius: 7,
        circleColor: '#E53935',
        circleStrokeWidth: 2,
        circleStrokeColor: '#FFFFFF',
      ),
      belowLayerId: _userHaloLayerId,
    );
    await _controller.addSymbolLayer(
      _sourceId,
      labelLayerId,
      const SymbolLayerProperties(
        textField: [Expressions.get, FeatureAttribute.name],
        textFont: ['Noto Sans Regular'],
        textSize: 11,
        textAnchor: 'top',
        textOffset: [0, 1.2],
        textMaxWidth: 10,
        textOptional: true,
        textColor: '#263238',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 1.5,
      ),
      belowLayerId: _userHaloLayerId,
      minzoom: 13,
    );
    await _controller.addCircleLayer(
      _sourceId,
      _selectedLayerId,
      const CircleLayerProperties(
        circleRadius: 11,
        circleColor: '#E53935',
        circleStrokeWidth: 4,
        circleStrokeColor: '#FFFFFF',
      ),
      belowLayerId: labelLayerId,
      filter: _noSelectionFilter,
    );
  }

  Future<void> highlight(LayerFeature? feature) {
    return _controller.setFilter(
      _selectedLayerId,
      feature == null
          ? _noSelectionFilter
          : [
              '==',
              ['id'],
              feature.id,
            ],
    );
  }

  Future<void> focusOn(LayerFeature feature) async {
    await _controller.animateCamera(
      CameraUpdate.newLatLng(LatLng(feature.latitude, feature.longitude)),
    );
  }

  Future<void> showDeviceLocation(DeviceLocation location) {
    return _controller.setGeoJsonSource(_userSourceId, {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [location.longitude, location.latitude],
          },
          'properties': <String, dynamic>{},
        },
      ],
    });
  }

  Future<void> focusOnUser(DeviceLocation location) async {
    await _controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        _userLocationZoom,
      ),
    );
  }

  Future<void> fitToLayer(MapLayer layer) async {
    final points = [
      for (final feature in layer.features)
        LatLng(feature.latitude, feature.longitude),
    ];
    if (points.isEmpty) return;

    if (points.length == 1) {
      await _controller.animateCamera(
        CameraUpdate.newLatLngZoom(points.single, _singlePointZoom),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        points.map((p) => p.latitude).reduce(math.min),
        points.map((p) => p.longitude).reduce(math.min),
      ),
      northeast: LatLng(
        points.map((p) => p.latitude).reduce(math.max),
        points.map((p) => p.longitude).reduce(math.max),
      ),
    );
    await _controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        left: _cameraPadding,
        top: _cameraPadding,
        right: _cameraPadding,
        bottom: _cameraPadding,
      ),
    );
  }
}
