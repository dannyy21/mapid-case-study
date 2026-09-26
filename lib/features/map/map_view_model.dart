import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/layer_feature.dart';
import '../../data/models/map_layer.dart';
import '../../data/models/device_location.dart';
import '../../data/services/location_service.dart';
import '../../data/services/mapid_layer_service.dart';

enum LayerStatus { loading, loaded, failed }

class MapViewModel extends ChangeNotifier {
  MapViewModel({required this._layerService, required this._locationService});

  final MapidLayerService _layerService;
  final LocationService _locationService;

  LayerStatus _layerStatus = LayerStatus.loading;
  MapLayer? _layer;
  String? _layerError;
  LayerFeature? _selectedFeature;
  DeviceLocation? _userLocation;
  bool _isLocating = false;
  StreamSubscription<DeviceLocation>? _locationSubscription;
  bool _disposed = false;

  LayerStatus get layerStatus => _layerStatus;
  MapLayer? get layer => _layer;
  String? get layerError => _layerError;
  LayerFeature? get selectedFeature => _selectedFeature;
  DeviceLocation? get userLocation => _userLocation;
  bool get isLocating => _isLocating;

  Future<void> loadLayer() async {
    _layerStatus = LayerStatus.loading;
    _layerError = null;
    _notify();

    try {
      _layer = await _layerService.fetchLayer();
      _layerStatus = LayerStatus.loaded;
    } on AppException catch (e) {
      _layerError = e.message;
      _layerStatus = LayerStatus.failed;
    }
    _notify();
  }

  void selectFeature(String id) {
    final feature = _layer?.featureById(id);
    if (feature == null || feature == _selectedFeature) return;
    _selectedFeature = feature;
    _notify();
  }

  void clearSelection() {
    if (_selectedFeature == null) return;
    _selectedFeature = null;
    _notify();
  }

  Future<DeviceLocation> locateUser() async {
    _isLocating = true;
    _notify();

    try {
      final location = await _locationService.getCurrentLocation();
      _updateUserLocation(location);
      _locationSubscription ??= _locationService.watchLocation().listen(
        _updateUserLocation,
        onError: (Object _) {},
      );
      return location;
    } finally {
      _isLocating = false;
      _notify();
    }
  }

  void _updateUserLocation(DeviceLocation location) {
    _userLocation = location;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _locationSubscription?.cancel();
    super.dispose();
  }
}
