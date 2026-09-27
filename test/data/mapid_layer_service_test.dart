import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mapid_case_study/core/errors/app_exception.dart';
import 'package:mapid_case_study/data/services/mapid_layer_service.dart';

void main() {
  final fixture = File('test/fixtures/mapid_layer.json').readAsBytesSync();

  MapidLayerService buildService(MockClientHandler handler) {
    return MapidLayerService(
      baseUrl: 'https://geoserver.example.com',
      apiKey: 'test-key',
      layerId: 'layer-1',
      projectId: 'project-1',
      client: MockClient(handler),
      timeout: const Duration(milliseconds: 50),
    );
  }

  Matcher throwsAppException(String message) => throwsA(
    isA<AppException>().having((e) => e.message, 'message', contains(message)),
  );

  test(
    'requests the layer endpoint with credentials as query params',
    () async {
      late Uri requested;
      final service = buildService((request) async {
        requested = request.url;
        return http.Response.bytes(fixture, 200);
      });

      await service.fetchLayer();

      expect(requested.path, '/layers_new/get_layer');
      expect(requested.queryParameters, {
        'api_key': 'test-key',
        'layer_id': 'layer-1',
        'project_id': 'project-1',
      });
    },
  );

  test('parses point features and skips other geometries', () async {
    final service = buildService(
      (_) async => http.Response.bytes(fixture, 200),
    );

    final layer = await service.fetchLayer();

    expect(layer.name, 'Pariwisata Jogja');
    expect(layer.features.map((f) => f.id), ['f-1', 'f-2']);

    final first = layer.features.first;
    expect(first.latitude, -7.799231);
    expect(first.longitude, 110.368369);
    expect(first['NAMA'], 'TAMAN TIMUR PASAR BERINGHARJO');
  });

  test('sanitizes corrupted text and treats empty values as missing', () async {
    final service = buildService(
      (_) async => http.Response.bytes(fixture, 200),
    );

    final feature = (await service.fetchLayer()).featureById('f-2')!;

    expect(feature['NAMA'], 'TAMAN WARUNGBOTO');
    expect(feature['ALAMAT'], isNull);
    expect(feature['WAKTU'], isNull);
  });

  test('builds a GeoJSON FeatureCollection for the map source', () async {
    final service = buildService(
      (_) async => http.Response.bytes(fixture, 200),
    );

    final geoJson = (await service.fetchLayer()).toGeoJson();

    expect(geoJson['type'], 'FeatureCollection');
    expect(geoJson['features'], hasLength(2));
  });

  test('throws AppException on non-200 responses', () {
    final service = buildService((_) async => http.Response('Forbidden', 403));

    expect(service.fetchLayer(), throwsAppException('HTTP 403'));
  });

  test('throws AppException on invalid JSON', () {
    final service = buildService((_) async => http.Response('<html>', 200));

    expect(service.fetchLayer(), throwsAppException('invalid layer data'));
  });

  test('throws AppException on network errors', () {
    final service = buildService(
      (_) async => throw http.ClientException('offline'),
    );

    expect(service.fetchLayer(), throwsAppException('No internet connection'));
  });

  test('throws AppException on timeout', () {
    final service = buildService((_) => Completer<http.Response>().future);

    expect(service.fetchLayer(), throwsAppException('timed out'));
  });

  test('tells whether a location is near the layer', () async {
    final service = buildService(
      (_) async => http.Response.bytes(fixture, 200),
    );

    final layer = await service.fetchLayer();

    expect(layer.isNear(-7.80, 110.37), isTrue);
    expect(layer.isNear(-6.88, 107.54), isFalse);
  });
}
