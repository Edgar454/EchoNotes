import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/websocket_service.dart';
import '../services/audio_service.dart';

class TranscriptionProvider extends ChangeNotifier {
  final WebSocketService _wsService = WebSocketService();
  final AudioService _audioService = AudioService();
  
  bool _isRecording = false;
  bool _isConnected = false;
  
  String _sourceLanguage = 'fr';
  String _targetLanguage = 'en';
  int _chunkDurationSeconds = 5; // default value, configurable
  
  String _transcription = '';
  String _translation = '';
  String? _errorMessage;
  
  List<Map<String, String>> _transcriptionHistory = [];
  
  // --- Getters ---
  bool get isRecording => _isRecording;
  bool get isConnected => _isConnected;
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;
  int get chunkDurationSeconds => _chunkDurationSeconds;
  String get transcription => _transcription;
  String get translation => _translation;
  String? get errorMessage => _errorMessage;
  List<Map<String, String>> get transcriptionHistory => _transcriptionHistory;
  
  // --- Setters for dynamic configuration ---
  void setLanguages({required String source, required String target}) {
    _sourceLanguage = source;
    _targetLanguage = target;
    notifyListeners();
  }

  void setChunkDuration(int seconds) {
    _chunkDurationSeconds = seconds;
    notifyListeners();
  }
  
  // --- Start recording and transcription ---
  Future<void> startRecording() async {
    try {
      await _wsService.connect(
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );
      
      _isConnected = true;
      notifyListeners();
      
      // Listen to WebSocket messages
      _wsService.messages.listen((message) {
        _handleWebSocketMessage(message);
      });
      
      // Start audio recording with configurable chunk duration
      await _audioService.startRecording(
        onChunk: (Uint8List audioData) {
          _wsService.sendAudio(audioData);
        },
        chunkDurationSeconds: _chunkDurationSeconds,
      );
      
      _isRecording = true;
      notifyListeners();
      
      print('Recording and transcription started');
    } catch (e) {
      _isRecording = false;
      _isConnected = false;
      _errorMessage = 'Error starting recording: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  // --- Handle WebSocket messages ---
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    try {
      if (message['type'] == 'transcription') {
        _transcription = message['text'] ?? '';
        notifyListeners();
      } else if (message['type'] == 'translation') {
        _translation = message['text'] ?? '';
        
        if (_transcription.isNotEmpty && _translation.isNotEmpty) {
          _transcriptionHistory.add({
            'transcription': _transcription,
            'translation': _translation,
          });
          _transcription = '';
          _translation = '';
        }
        notifyListeners();
      } else if (message['type'] == 'error') {
        _errorMessage = message['message'] ?? 'Unknown WebSocket error';
        print('WebSocket error: $_errorMessage');
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error handling WebSocket message: $e';
      notifyListeners();
      print(_errorMessage);
    }
  }
  
  // --- Stop recording and transcription ---
  Future<void> stopRecording() async {
    try {
      await _audioService.stopRecording();
      await _wsService.disconnect();
      
      _isRecording = false;
      _isConnected = false;
      notifyListeners();
      
      print('Recording and transcription stopped');
    } catch (e) {
      _errorMessage = 'Error stopping recording: $e';
      notifyListeners();
      print(_errorMessage);
    }
  }
  
  // --- Clear state ---
  void clearCurrent() {
    _transcription = '';
    _translation = '';
    _errorMessage = null;
    notifyListeners();
  }
  
  void clearHistory() {
    _transcriptionHistory.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _audioService.dispose();
    _wsService.dispose();
    super.dispose();
  }
}
