import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/errors/app_exception.dart';
import '../models/map_layer.dart';

class MapidLayerService {
  MapidLayerService({
    required String baseUrl,
    required String apiKey,
    required String layerId,
    required String projectId,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _uri = Uri.parse(baseUrl)
           .resolve('layers_new/get_layer')
           .replace(
             queryParameters: {
               'api_key': apiKey,
               'layer_id': layerId,
               'project_id': projectId,
             },
           );

  final http.Client _client;
  final Uri _uri;
  final Duration timeout;

  Future<MapLayer> fetchLayer() async {
    final http.Response response;
    try {
      response = await _client.get(_uri).timeout(timeout);
    } on TimeoutException {
      throw const AppException('Request timed out. Please try again.');
    } on http.ClientException {
      throw const AppException('No internet connection. Please try again.');
    }

    if (response.statusCode != 200) {
      throw AppException('Failed to load layer (HTTP ${response.statusCode}).');
    }

    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Response is not a JSON object.');
      }
      return MapLayer.fromJson(body);
    } on FormatException {
      throw const AppException('Received invalid layer data.');
    }
  }

  void dispose() => _client.close();
}
