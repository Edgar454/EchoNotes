import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class EnvConfig {
  static String get apiBaseUrl {
    final url = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get wsBaseUrl {
    final wsUrl = dotenv.env['WS_BASE_URL'];
    if (wsUrl != null && wsUrl.isNotEmpty) return wsUrl;

    final baseUrl = apiBaseUrl;
    if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://');
    } else if (baseUrl.startsWith('http://')) {
      return baseUrl.replaceFirst('http://', 'ws://');
    }
    return 'ws://localhost:8000';
  }

  static void validate() {
    if (kReleaseMode && dotenv.env['API_BASE_URL'] == null) {
      throw Exception(
          '❌ Missing API_BASE_URL in production environment configuration.');
    }
  }
}
