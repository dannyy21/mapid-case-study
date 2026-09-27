import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/constants/map_constants.dart';
import '../../data/models/device_location.dart';
import '../../data/models/layer_feature.dart';
import '../../data/services/location_service.dart';
import '../../data/services/mapid_layer_service.dart';
import 'map_layer_renderer.dart';
import 'map_view_model.dart';
import 'widgets/feature_popup_layer.dart';
import 'widgets/layer_error_banner.dart';
import 'widgets/loading_chip.dart';
import 'widgets/map_action_buttons.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.layerService,
    required this.locationService,
  });

  final MapidLayerService layerService;
  final LocationService locationService;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapViewModel _viewModel;
  MapLibreMapController? _mapController;
  MapLayerRenderer? _renderer;
  bool _mapReady = false;
  bool _layerRendered = false;
  LayerFeature? _renderedSelection;
  DeviceLocation? _renderedLocation;

  @override
  void initState() {
    super.initState();
    _viewModel = MapViewModel(
      layerService: widget.layerService,
      locationService: widget.locationService,
    )..addListener(_syncMap);
    _viewModel.loadLayer();
  }

  @override
  void dispose() {
    _mapController?.onFeatureTapped.remove(_onFeatureTapped);
    _viewModel
      ..removeListener(_syncMap)
      ..dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller..onFeatureTapped.add(_onFeatureTapped);
    _renderer = MapLayerRenderer(controller);
  }

  Future<void> _onStyleLoaded() async {
    await _renderer?.prepare();
    _mapReady = true;
    await _syncMap();
    await _locateUser(focus: false);
  }

  Future<void> _syncMap() async {
    final renderer = _renderer;
    if (!_mapReady || renderer == null) return;

    final layer = _viewModel.layer;
    if (layer != null && !_layerRendered) {
      _layerRendered = true;
      await renderer.showLayer(layer);
      await renderer.fitToLayer(layer);
    }

    final selection = _viewModel.selectedFeature;
    if (selection != _renderedSelection) {
      _renderedSelection = selection;
      await renderer.highlight(selection);
    }

    final location = _viewModel.userLocation;
    if (location != null && location != _renderedLocation) {
      _renderedLocation = location;
      await renderer.showUserLocation(location);
    }
  }

  void _onFeatureTapped(
    Point<double> point,
    LatLng coordinates,
    String id,
    String layerId,
    Annotation? annotation,
  ) => _viewModel.selectFeature(id);

  void _onMapClick(Point<double> point, LatLng coordinates) =>
      _viewModel.clearSelection();

  Future<void> _locateUser({bool focus = true}) async {
    try {
      final location = await _viewModel.locateUser();
      if (!focus) return;
      await _renderer?.focusOnUser(location);
      _hintIfOutsideLayer(location);
    } on LocationException catch (e) {
      _showLocationError(e);
    }
  }

  void _hintIfOutsideLayer(DeviceLocation location) {
    final layer = _viewModel.layer;
    if (!mounted ||
        layer == null ||
        layer.isNear(location.latitude, location.longitude)) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('No ${layer.name} places near your location.'),
          action: SnackBarAction(
            label: 'Show places',
            onPressed: _showAllPlaces,
          ),
        ),
      );
  }

  void _showLocationError(LocationException error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: error.canOpenSettings
              ? SnackBarAction(
                  label: 'Settings',
                  onPressed: () =>
                      widget.locationService.openSettings(error.failure),
                )
              : SnackBarAction(label: 'Retry', onPressed: _locateUser),
        ),
      );
  }

  void _showAllPlaces() {
    final layer = _viewModel.layer;
    if (layer != null) _renderer?.fitToLayer(layer);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      child: MapLibreMap(
        styleString: MapConstants.styleUrl,
        initialCameraPosition: MapConstants.initialCamera,
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: _onStyleLoaded,
        onMapClick: _onMapClick,
        trackCameraPosition: true,
        rotateGesturesEnabled: false,
        compassEnabled: false,
      ),
      builder: (context, map) {
        final layer = _viewModel.layer;
        final feature = _viewModel.selectedFeature;
        final layerError = _viewModel.layerError;
        final renderer = _renderer;

        return Scaffold(
          appBar: AppBar(title: Text(layer?.name ?? 'MAPID Map')),
          body: Stack(
            children: [
              map!,
              if (feature != null && renderer != null)
                Positioned.fill(
                  child: FeaturePopupLayer(
                    renderer: renderer,
                    feature: feature,
                    onClose: _viewModel.clearSelection,
                  ),
                ),
              if (_viewModel.layerStatus == LayerStatus.loading)
                const Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(child: LoadingChip(label: 'Loading places…')),
                ),
              if (layerError != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: LayerErrorBanner(
                    message: layerError,
                    onRetry: _viewModel.loadLayer,
                  ),
                ),
            ],
          ),
          floatingActionButton: MapActionButtons(
            isLocating: _viewModel.isLocating,
            onLocate: _locateUser,
            onShowAll: layer == null ? null : _showAllPlaces,
          ),
        );
      },
    );
  }
}
