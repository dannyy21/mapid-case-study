import 'dart:math' show Point;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/constants/map_constants.dart';
import '../../data/models/device_location.dart';
import '../../data/models/layer_feature.dart';
import '../../data/services/location_service.dart';
import '../../data/services/mapid_layer_service.dart';
import 'map_layer_renderer.dart';
import 'map_view_model.dart';
import 'widgets/feature_popup.dart';
import 'widgets/layer_error_banner.dart';
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
  static const _popupOffset = 14.0;

  late final MapViewModel _viewModel;
  final _popupAnchor = ValueNotifier<Offset?>(null);
  bool _anchorUpdateRunning = false;
  bool _anchorUpdatePending = false;
  MapLibreMapController? _mapController;
  MapLayerRenderer? _renderer;
  bool _mapReady = false;
  bool _layerRendered = false;
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
    _mapController
      ?..onFeatureTapped.remove(_onFeatureTapped)
      ..removeListener(_updatePopupAnchor);
    _popupAnchor.dispose();
    _viewModel
      ..removeListener(_syncMap)
      ..dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller
      ..onFeatureTapped.add(_onFeatureTapped)
      ..addListener(_updatePopupAnchor);
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

    final location = _viewModel.userLocation;
    if (location != null && location != _renderedLocation) {
      _renderedLocation = location;
      await renderer.showUserLocation(location);
    }
  }

  Future<void> _locateUser({bool focus = true}) async {
    try {
      final location = await _viewModel.locateUser();
      if (focus) await _renderer?.focusOnUser(location);
    } on LocationException catch (e) {
      _showLocationError(e);
    }
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

  void _onFeatureTapped(
    Point<double> point,
    LatLng coordinates,
    String id,
    String layerId,
    Annotation? annotation,
  ) {
    final feature = _viewModel.selectFeature(id);
    if (feature == null) return;
    _popupAnchor.value = null;
    _renderer?.highlight(feature);
    _renderer?.focusOn(feature);
    _updatePopupAnchor();
  }

  void _onMapClick(Point<double> point, LatLng coordinates) =>
      _clearSelection();

  void _clearSelection() {
    _viewModel.clearSelection();
    _popupAnchor.value = null;
    _renderer?.highlight(null);
  }

  Future<void> _updatePopupAnchor() async {
    if (_anchorUpdateRunning) {
      _anchorUpdatePending = true;
      return;
    }
    _anchorUpdateRunning = true;
    do {
      _anchorUpdatePending = false;
      await _projectSelectedFeature();
    } while (_anchorUpdatePending && mounted);
    _anchorUpdateRunning = false;
  }

  Future<void> _projectSelectedFeature() async {
    final feature = _viewModel.selectedFeature;
    final renderer = _renderer;
    if (feature == null || renderer == null) return;

    final position = await renderer.screenPositionOf(
      feature,
      pixelRatio: _mapPixelRatio,
    );
    if (mounted && _viewModel.selectedFeature == feature) {
      _popupAnchor.value = position;
    }
  }

  double get _mapPixelRatio => defaultTargetPlatform == TargetPlatform.android
      ? MediaQuery.devicePixelRatioOf(context)
      : 1;

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
      ),
      builder: (context, map) {
        final layer = _viewModel.layer;
        final feature = _viewModel.selectedFeature;
        final layerError = _viewModel.layerError;

        return Scaffold(
          appBar: AppBar(
            title: Text(layer?.name ?? 'MAPID Map'),
            bottom: _viewModel.layerStatus == LayerStatus.loading
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(4),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),
          body: Stack(
            children: [
              map!,
              if (feature != null) _buildPopup(feature),
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

  Widget _buildPopup(LayerFeature feature) {
    return Positioned.fill(
      child: ValueListenableBuilder<Offset?>(
        valueListenable: _popupAnchor,
        builder: (context, anchor, _) {
          if (anchor == null) return const SizedBox.shrink();
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: anchor.dx,
                top: anchor.dy - _popupOffset,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -1),
                  child: FeaturePopup(
                    key: ValueKey(feature.id),
                    feature: feature,
                    onClose: _clearSelection,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
