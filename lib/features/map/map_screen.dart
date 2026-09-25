import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/constants/map_constants.dart';
import '../../data/services/mapid_layer_service.dart';
import 'map_layer_renderer.dart';
import 'map_view_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.layerService});

  final MapidLayerService layerService;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapViewModel _viewModel;
  MapLayerRenderer? _renderer;
  bool _styleLoaded = false;
  bool _layerRendered = false;

  @override
  void initState() {
    super.initState();
    _viewModel = MapViewModel(layerService: widget.layerService)
      ..addListener(_renderLayerIfReady);
    _viewModel.loadLayer();
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_renderLayerIfReady)
      ..dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _renderer = MapLayerRenderer(controller);
  }

  void _onStyleLoaded() {
    _styleLoaded = true;
    _renderLayerIfReady();
  }

  Future<void> _renderLayerIfReady() async {
    final renderer = _renderer;
    final layer = _viewModel.layer;
    if (!_styleLoaded || renderer == null || layer == null || _layerRendered) {
      return;
    }
    _layerRendered = true;
    await renderer.showLayer(layer);
    await renderer.fitToLayer(layer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MAPID Map')),
      body: MapLibreMap(
        styleString: MapConstants.styleUrl,
        initialCameraPosition: MapConstants.initialCamera,
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: _onStyleLoaded,
      ),
    );
  }
}
