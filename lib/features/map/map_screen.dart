import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/constants/map_constants.dart';
import '../../data/models/layer_feature.dart';
import '../../data/services/mapid_layer_service.dart';
import 'map_layer_renderer.dart';
import 'map_view_model.dart';
import 'widgets/feature_popup.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.layerService});

  final MapidLayerService layerService;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapViewModel _viewModel;
  MapLibreMapController? _mapController;
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
    _mapController?.onFeatureTapped.remove(_onFeatureTapped);
    _viewModel
      ..removeListener(_renderLayerIfReady)
      ..dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller..onFeatureTapped.add(_onFeatureTapped);
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

  void _onFeatureTapped(
    Point<double> point,
    LatLng coordinates,
    String id,
    String layerId,
    Annotation? annotation,
  ) {
    final feature = _viewModel.selectFeature(id);
    if (feature == null) return;
    _renderer?.highlight(feature);
    _renderer?.focusOn(feature);
  }

  void _onMapClick(Point<double> point, LatLng coordinates) =>
      _clearSelection();

  void _clearSelection() {
    _viewModel.clearSelection();
    _renderer?.highlight(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MAPID Map')),
      body: Stack(
        children: [
          MapLibreMap(
            styleString: MapConstants.styleUrl,
            initialCameraPosition: MapConstants.initialCamera,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: _onMapClick,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) =>
                    _buildPopup(_viewModel.selectedFeature),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopup(LayerFeature? feature) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: feature == null
          ? const SizedBox.shrink()
          : FeaturePopup(
              key: ValueKey(feature.id),
              feature: feature,
              onClose: _clearSelection,
            ),
    );
  }
}
