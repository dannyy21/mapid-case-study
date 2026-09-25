import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/constants/map_constants.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MAPID Map')),
      body: MapLibreMap(
        styleString: MapConstants.styleUrl,
        initialCameraPosition: MapConstants.initialCamera,
      ),
    );
  }
}
