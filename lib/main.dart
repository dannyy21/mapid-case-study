import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'data/services/mapid_layer_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();

  final layerService = MapidLayerService(
    baseUrl: Env.mapidBaseUrl,
    apiKey: Env.mapidApiKey,
    layerId: Env.mapidLayerId,
    projectId: Env.mapidProjectId,
  );

  runApp(MapidApp(layerService: layerService));
}
