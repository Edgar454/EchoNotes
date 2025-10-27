import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../config/env_config.dart';
import 'api_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  String? _clientId;
  final List<Uint8List> _audioQueue = [];
  bool _isConnecting = false;

  /// Optional debug flag
  final bool debug;

  WebSocketService({this.debug = true});

  /// Stream of incoming messages
  Stream<Map<String, dynamic>> get messages {
    if (_messageController == null) {
      throw Exception('WebSocket not connected yet. Call connect() first.');
    }
    return _messageController!.stream;
  }

  bool get isConnected => _channel != null;

  /// Connect to WebSocket with authentication
  Future<void> connect({
    String sourceLanguage = 'fr',
    String targetLanguage = 'en',
  }) async {
    if (_isConnecting || _channel != null) return;
    _isConnecting = true;

    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('Not authenticated');

      _clientId = DateTime.now().millisecondsSinceEpoch.toString();
      final wsUrl =
          '${EnvConfig.wsBaseUrl}/ws/$_clientId?source=$sourceLanguage&target=$targetLanguage';

      if (debug) print('[WS] Connecting to $wsUrl');

      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {'Authorization': 'Bearer $token'},
        pingInterval: const Duration(seconds: 30),
      );

      _messageController ??= StreamController<Map<String, dynamic>>.broadcast();

      // Listen to incoming messages
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _messageController!.add(data);
          } catch (e) {
            if (debug) print('[WS] Error parsing message: $e');
            _messageController!.addError(e);
          }
        },
        onError: (error) {
          if (debug) print('[WS] Connection error: $error');
          _messageController!.addError(error);
        },
        onDone: () async {
          if (debug) print('[WS] Connection closed');
          await disconnect();
        },
      );

      // Send any queued audio
      if (_audioQueue.isNotEmpty) {
        for (var chunk in _audioQueue) {
          _channel!.sink.add(chunk);
        }
        _audioQueue.clear();
      }

      if (debug) print('[WS] Connected successfully');
    } catch (e) {
      if (debug) print('[WS] Failed to connect: $e');
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  /// Send audio bytes (FLAC)
  void sendAudio(Uint8List audioData) {
    if (_channel != null && isConnected) {
      try {
        _channel!.sink.add(audioData);
      } catch (e) {
        if (debug) print('[WS] Error sending audio: $e');
      }
    } else {
      if (debug) print('[WS] WebSocket not connected, queueing audio');
      _audioQueue.add(audioData);
    }
  }

  /// Disconnect safely
  Future<void> disconnect() async {
    try {
      await _channel?.sink.close();
      await _messageController?.close();
      _channel = null;
      _messageController = null;
      _clientId = null;
      _audioQueue.clear();
      if (debug) print('[WS] Disconnected');
    } catch (e) {
      if (debug) print('[WS] Error during disconnect: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await disconnect();
  }
}
