import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

class ApiService {
  static final String baseUrl = EnvConfig.apiBaseUrl;
  static final http.Client httpClient = http.Client();

  // ------------------ Auth ------------------

  static Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signin'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,  // FastAPI expects username field
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['access_token']);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Sign in failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> signUp(
      String email, String password, String fullName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Only save token if backend returns one
        if (data['access_token'] != null) {
          await _saveToken(data['access_token']);
        }
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['detail'] ?? 'Sign up failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ------------------ Token Management ------------------

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ------------------ Generic GET ------------------

  static Future<dynamic> httpGet(String url, {required String token}) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final detail = jsonDecode(response.body)['detail'] ?? 'Request failed';
      throw Exception(detail);
    }
  }

  // ------------------ Generic POST (JSON) ------------------

  static Future<dynamic> httpPost(String url,
      {Map<String, dynamic>? body, String? token}) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body ?? {}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final detail = jsonDecode(response.body)['detail'] ?? 'Request failed';
      throw Exception(detail);
    }
  }

  // Build request for streaming
  static http.Request buildGetRequest(Uri uri, {required String token}) {
    final req = http.Request('GET', uri);
    req.headers['Authorization'] = 'Bearer $token';
    return req;
  }
}
