import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class Env {
  static Future<void> load() => dotenv.load();

  static String get mapidBaseUrl => _require('MAPID_BASE_URL');
  static String get mapidApiKey => _require('MAPID_API_KEY');
  static String get mapidLayerId => _require('MAPID_LAYER_ID');
  static String get mapidProjectId => _require('MAPID_PROJECT_ID');

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError('Missing "$key" in .env. See .env.example.');
    }
    return value;
  }
}
