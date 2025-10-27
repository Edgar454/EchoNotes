import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/sessions_provider.dart';
import '../widgets/bottom_nav_widget.dart';

class SessionPlaybackScreen extends StatefulWidget {
  final String sessionId;

  const SessionPlaybackScreen({super.key, required this.sessionId});

  @override
  _SessionPlaybackScreenState createState() => _SessionPlaybackScreenState();
}

class _SessionPlaybackScreenState extends State<SessionPlaybackScreen> {
  bool isOriginalText = true;
  AudioPlayer? audioPlayer;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  Uint8List? audioBytes;
  Map<String, dynamic>? sessionData;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final provider = Provider.of<SessionProvider>(context, listen: false);


    // Find session in provider cache
    try {
      sessionData = provider.sessions.firstWhere(
        (s) => s['id'] == widget.sessionId,
      );
    } catch (e) {
      sessionData = null;
    }
    
    // If not found, fetch sessions and try again
    if (sessionData == null) {
      await provider.fetchLastSessions();
      try {
        sessionData = provider.sessions.firstWhere(
          (s) => s['id'] == widget.sessionId,
        );
      } catch (e) {
        sessionData = null;
      }
    }


    // Load audio bytes
    if (sessionData != null) {
      audioBytes = await provider.streamSessionAudio(widget.sessionId);
    }

    // Setup audio player
    if (audioBytes != null) {
      await audioPlayer!.setSourceBytes(audioBytes!);
      audioPlayer!.onDurationChanged.listen((d) {
        setState(() {
          duration = d;
        });
      });
      audioPlayer!.onPositionChanged.listen((p) {
        setState(() {
          position = p;
        });
      });
      audioPlayer!.onPlayerComplete.listen((_) {
        setState(() {
          isPlaying = false;
          position = Duration.zero;
        });
      });
    }

    setState(() {});
  }

  void toggleText() {
    setState(() {
      isOriginalText = !isOriginalText;
    });
  }

  void playPause() async {
    if (isPlaying) {
      await audioPlayer!.pause();
    } else {
      await audioPlayer!.resume();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  void dispose() {
    audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (sessionData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Session Playback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Session Info
            _buildSessionInfo(),

            const SizedBox(height: 16),

            // Transcript with horizontal swipe toggle
            GestureDetector(
              onHorizontalDragEnd: (_) => toggleText(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isOriginalText ? Colors.blueGrey[50] : Colors.blueGrey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 150,
                width: double.infinity,
                child: SingleChildScrollView(
                  child: Text(
                    isOriginalText
                        ? (sessionData?['original_text'] ?? '')
                        : (sessionData?['translated_text'] ?? ''),
                    style: TextStyle(
                      color: isOriginalText ? Colors.black : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Audio Controls
            if (audioBytes != null) _buildAudioControls(),

            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(),

            const Spacer(),

            // Bottom Navigation
            const BottomNavWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sessionData?['name'] ?? 'Unknown Session',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Source: ${sessionData?['source_language'] ?? '?'} → Target: ${sessionData?['target_language'] ?? '?'}',
        ),
        const SizedBox(height: 4),
        Text(
          'Duration: ${sessionData?['duration'] ?? '?'} seconds',
        ),
        const SizedBox(height: 4),
        Text(
          'Date: ${sessionData?['created_at'] ?? '?'}',
        ),
      ],
    );
  }

  Widget _buildAudioControls() {
    return Column(
      children: [
        Slider(
          min: 0,
          max: duration.inMilliseconds.toDouble(),
          value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
          onChanged: (value) async {
            final pos = Duration(milliseconds: value.toInt());
            await audioPlayer!.seek(pos);
            setState(() {
              position = pos;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: playPause,
            ),
            Text('${_formatDuration(position)} / ${_formatDuration(duration)}'),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton(onPressed: () {}, child: const Text('Highlight')),
        ElevatedButton(onPressed: () {}, child: const Text('Edit')),
        ElevatedButton(onPressed: () {}, child: const Text('Translate')),
        ElevatedButton(onPressed: () {}, child: const Text('Share')),
        IconButton(icon: const Icon(Icons.star), onPressed: () {}),
        IconButton(icon: const Icon(Icons.move_to_inbox), onPressed: () {}),
      ],
    );
  }
}
