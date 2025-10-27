import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _chunkTimer;
  bool _isRecording = false;
  String? _currentFilePath;
  int _chunkCount = 0;

  bool get isRecording => _isRecording;

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start recording with chunked audio
  Future<void> startRecording({
    required Function(Uint8List) onChunk,
    int chunkDurationSeconds = 5,
    VoidCallback? onStart,
  }) async {
    if (_isRecording) return;

    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) throw Exception('Microphone permission denied');
      if (!await _recorder.hasPermission()) throw Exception('Recording permission not granted');

      _isRecording = true;
      _chunkCount = 0;

      // optional callback
      onStart?.call();

      await _startChunkRecording(onChunk, chunkDurationSeconds);
      print('Recording started with $chunkDurationSeconds seconds chunks');
    } catch (e) {
      _isRecording = false;
      print('Error starting recording: $e');
      rethrow;
    }
  }

  /// Chunk-based recording
  Future<void> _startChunkRecording(
    Function(Uint8List) onChunk,
    int chunkDurationSeconds,
  ) async {
    _chunkTimer = Timer.periodic(
      Duration(seconds: chunkDurationSeconds),
      (timer) async {
        if (!_isRecording) {
          timer.cancel();
          return;
        }

        try {
          final path = await _recorder.stop();
          if (path != null) {
            final file = File(path);
            final bytes = await file.readAsBytes();
            onChunk(Uint8List.fromList(bytes));
            await file.delete();
            _chunkCount++;
            print('Sent audio chunk $_chunkCount (${bytes.length} bytes)');
          }

          if (_isRecording) await _startNextChunk();
        } catch (e) {
          print('Error processing audio chunk: $e');
        }
      },
    );

    // Start first chunk immediately
    await _startNextChunk();
  }

  /// Start next chunk recording
  Future<void> _startNextChunk() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentFilePath = '${tempDir.path}/audio_chunk_$timestamp.flac';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.flac,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _currentFilePath!,
      );
    } catch (e) {
      print('Error starting next chunk: $e');
      rethrow;
    }
  }

  /// Stop recording
  Future<void> stopRecording({VoidCallback? onStop}) async {
    if (!_isRecording) return;

    try {
      _isRecording = false;
      _chunkTimer?.cancel();
      _chunkTimer = null;

      final path = await _recorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }

      _chunkCount = 0;
      onStop?.call();
      print('Recording stopped');
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopRecording();
    await _recorder.dispose();
  }
}
