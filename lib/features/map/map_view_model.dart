import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/layer_feature.dart';
import '../../data/models/map_layer.dart';
import '../../data/services/mapid_layer_service.dart';

enum LayerStatus { loading, loaded, failed }

class MapViewModel extends ChangeNotifier {
  MapViewModel({required this._layerService});

  final MapidLayerService _layerService;

  LayerStatus _layerStatus = LayerStatus.loading;
  MapLayer? _layer;
  String? _layerError;
  LayerFeature? _selectedFeature;
  bool _disposed = false;

  LayerStatus get layerStatus => _layerStatus;
  MapLayer? get layer => _layer;
  String? get layerError => _layerError;
  LayerFeature? get selectedFeature => _selectedFeature;

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

  LayerFeature? selectFeature(String id) {
    final feature = _layer?.featureById(id);
    if (feature == null || feature == _selectedFeature) return feature;
    _selectedFeature = feature;
    _notify();
    return feature;
  }

  void clearSelection() {
    if (_selectedFeature == null) return;
    _selectedFeature = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
