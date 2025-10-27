import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/api_service.dart';

class SessionProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _sessions = [];
  Map<String, Uint8List> _sessionAudioCache = {}; // session_id → audio bytes

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get sessions => _sessions;

  /// Fetch last N sessions
  Future<void> fetchLastSessions({int numberSessions = 10}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiService.baseUrl}/session/get_last_transcripts?number_sessions=$numberSessions';
      final token = await ApiService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final res = await ApiService.httpGet(url, token: token);
      if (res != null && res is List) {
        _sessions = List<Map<String, dynamic>>.from(res);
      } else {
        _sessions = [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch audio URLs (if you want just URLs)
  Future<List<String>> fetchAudioUrls(String sessionId) async {
    try {
      final url = '${ApiService.baseUrl}/session/get_audios?session_id=$sessionId';
      final token = await ApiService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final res = await ApiService.httpGet(url, token: token);
      if (res != null && res['audio_urls'] != null) {
        return List<String>.from(res['audio_urls']);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return [];
  }

  /// Stream the audio for a session (load bytes for playback)
  Future<Uint8List?> streamSessionAudio(String sessionId) async {
    // Return from cache if already loaded
    if (_sessionAudioCache.containsKey(sessionId)) {
      return _sessionAudioCache[sessionId];
    }

    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = '${ApiService.baseUrl}/session/stream_audio/$sessionId';
      final uri = Uri.parse(url);

      final request = await ApiService.httpClient.send(
        ApiService.buildGetRequest(uri, token: token),
      );

      final bytes = await request.stream.toBytes();
      _sessionAudioCache[sessionId] = bytes;
      return bytes;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return null;
  }

  void clearSessions() {
    _sessions = [];
    _sessionAudioCache.clear();
    notifyListeners();
  }
}
