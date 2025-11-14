import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class EnvConfig {
  static String get apiBaseUrl {
    final url = dotenv.env['API_BASE_URL'] ?? 'https://chootes-edgar4545777-aqiisd24.leapcell.dev';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get wsBaseUrl {
    final wsUrl = dotenv.env['WS_BASE_URL']?.trim();
    if (wsUrl?.isNotEmpty ?? false) return wsUrl!;

    final baseUrl = apiBaseUrl.trim();
    if (baseUrl.startsWith('https://')) return baseUrl.replaceFirst('https://', 'wss://');
    if (baseUrl.startsWith('http://')) return baseUrl.replaceFirst('http://', 'ws://');

    print('⚠️ Falling back to default ws URL.');
    return 'wss://chootes-edgar4545777-aqiisd24.leapcell.dev/';
  }


  static void validate() {
    if (kReleaseMode && dotenv.env['API_BASE_URL'] == null) {
      throw Exception(
          '❌ Missing API_BASE_URL in production environment configuration.');
    }
  }
}
