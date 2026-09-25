import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';

import '../../data/models/map_layer.dart';

class MapLayerRenderer {
  MapLayerRenderer(this._controller);

  static const pointLayerId = 'mapid-points';
  static const labelLayerId = 'mapid-labels';
  static const _sourceId = 'mapid-source';
  static const _cameraPadding = 64.0;
  static const _singlePointZoom = 15.0;

  final MapLibreMapController _controller;

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
    );
    await _controller.addSymbolLayer(
      _sourceId,
      labelLayerId,
      const SymbolLayerProperties(
        textField: [Expressions.get, 'NAMA'],
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
      minzoom: 13,
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
