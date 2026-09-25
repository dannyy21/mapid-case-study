import 'package:maplibre_gl/maplibre_gl.dart';

abstract final class MapConstants {
  static const styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  static const initialCamera = CameraPosition(
    target: LatLng(-7.7956, 110.3695),
    zoom: 12,
  );
}
