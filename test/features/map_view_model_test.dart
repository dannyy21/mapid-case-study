import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapid_case_study/data/models/device_location.dart';
import 'package:mapid_case_study/data/services/location_service.dart';
import 'package:mapid_case_study/data/services/mapid_layer_service.dart';
import 'package:mapid_case_study/features/map/map_view_model.dart';

class FakeLocationService implements LocationService {
  FakeLocationService({this.location, this.error});

  final DeviceLocation? location;
  final LocationException? error;

  @override
  Future<DeviceLocation> getCurrentLocation() async {
    if (error case final error?) throw error;
    return location!;
  }

  @override
  Stream<DeviceLocation> watchLocation() => const Stream.empty();

  @override
  Future<bool> openSettings(LocationFailure failure) async => true;
}

void main() {
  final fixture = File('test/fixtures/mapid_layer.json').readAsBytesSync();
  const location = DeviceLocation(
    latitude: -7.8,
    longitude: 110.37,
    accuracy: 5,
  );

  MapidLayerService layerService(List<http.Response> responses) {
    final queue = [...responses];
    return MapidLayerService(
      baseUrl: 'https://geoserver.example.com',
      apiKey: 'key',
      layerId: 'layer',
      projectId: 'project',
      client: MockClient((_) async => queue.removeAt(0)),
    );
  }

  MapViewModel buildViewModel({
    List<http.Response>? responses,
    LocationService? locationService,
  }) {
    return MapViewModel(
      layerService: layerService(
        responses ?? [http.Response.bytes(fixture, 200)],
      ),
      locationService:
          locationService ?? FakeLocationService(location: location),
    );
  }

  group('loadLayer', () {
    test('exposes the layer once loaded', () async {
      final viewModel = buildViewModel();

      expect(viewModel.layerStatus, LayerStatus.loading);
      await viewModel.loadLayer();

      expect(viewModel.layerStatus, LayerStatus.loaded);
      expect(viewModel.layer?.name, 'Pariwisata Jogja');
      expect(viewModel.layerError, isNull);
    });

    test('exposes an error and recovers on retry', () async {
      final viewModel = buildViewModel(
        responses: [
          http.Response('error', 500),
          http.Response.bytes(fixture, 200),
        ],
      );

      await viewModel.loadLayer();
      expect(viewModel.layerStatus, LayerStatus.failed);
      expect(viewModel.layerError, contains('HTTP 500'));

      await viewModel.loadLayer();
      expect(viewModel.layerStatus, LayerStatus.loaded);
      expect(viewModel.layerError, isNull);
    });
  });

  group('feature selection', () {
    test('selects a feature by id and clears it', () async {
      final viewModel = buildViewModel();
      await viewModel.loadLayer();

      viewModel.selectFeature('f-1');
      expect(viewModel.selectedFeature?.id, 'f-1');

      viewModel.clearSelection();
      expect(viewModel.selectedFeature, isNull);
    });

    test('ignores unknown ids', () async {
      final viewModel = buildViewModel();
      await viewModel.loadLayer();

      viewModel.selectFeature('missing');
      expect(viewModel.selectedFeature, isNull);
    });
  });

  group('locateUser', () {
    test('stores the current location', () async {
      final viewModel = buildViewModel();

      final result = await viewModel.locateUser();

      expect(result, same(location));
      expect(viewModel.userLocation, same(location));
      expect(viewModel.isLocating, isFalse);
    });

    test('rethrows location errors and resets the locating flag', () async {
      final viewModel = buildViewModel(
        locationService: FakeLocationService(
          error: const LocationException(
            LocationFailure.permissionDenied,
            'denied',
          ),
        ),
      );

      await expectLater(
        viewModel.locateUser(),
        throwsA(isA<LocationException>()),
      );
      expect(viewModel.isLocating, isFalse);
      expect(viewModel.userLocation, isNull);
    });
  });
}
