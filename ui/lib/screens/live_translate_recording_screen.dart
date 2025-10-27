import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transcription_provider.dart';

class LiveTranslateRecordingScreen extends StatefulWidget {
  const LiveTranslateRecordingScreen({super.key});

  @override
  State<LiveTranslateRecordingScreen> createState() =>
      _LiveTranslateRecordingScreenState();
}

class _LiveTranslateRecordingScreenState
    extends State<LiveTranslateRecordingScreen> {
  // 0 = original, 1 = translated
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final transcriptionProvider =
        Provider.of<TranscriptionProvider>(context);

    final List<String> pages = [
      transcriptionProvider.transcription.isEmpty
          ? 'Original text will appear here'
          : transcriptionProvider.transcription,
      transcriptionProvider.translation.isEmpty
          ? 'Translated text will appear here'
          : transcriptionProvider.translation,
    ];

    final List<Color> bgColors = [Colors.white, Colors.black];
    final List<Color> textColors = [Colors.black, Colors.white];

    return Scaffold(
      appBar: AppBar(title: const Text('Live Translate')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Recording Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  transcriptionProvider.isRecording
                      ? Icons.mic
                      : Icons.mic_none,
                  size: 32,
                  color: transcriptionProvider.isRecording
                      ? Colors.red
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  transcriptionProvider.isRecording
                      ? 'Recording...'
                      : 'Idle',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: transcriptionProvider.isRecording
                          ? Colors.red
                          : Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Swipeable text box
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < 0) {
                    // swipe left → show translation
                    setState(() {
                      _currentPage = 1;
                    });
                  } else if (details.primaryVelocity! > 0) {
                    // swipe right → show original
                    setState(() {
                      _currentPage = 0;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColors[_currentPage],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      pages[_currentPage],
                      style: TextStyle(
                          fontSize: 16, color: textColors[_currentPage]),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageDot(0),
                const SizedBox(width: 8),
                _pageDot(1),
              ],
            ),
            const SizedBox(height: 24),

            // Start / Stop Recording Button
            ElevatedButton.icon(
              icon: Icon(transcriptionProvider.isRecording
                  ? Icons.stop
                  : Icons.mic),
              label: Text(transcriptionProvider.isRecording
                  ? 'Stop Recording'
                  : 'Start Recording'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                if (transcriptionProvider.isRecording) {
                  await transcriptionProvider.stopRecording();
                } else {
                  await transcriptionProvider.startRecording();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _currentPage == index ? 16 : 12,
      height: _currentPage == index ? 16 : 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? Colors.black : Colors.grey,
      ),
    );
  }
}
