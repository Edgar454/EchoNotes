import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transcription_provider.dart';

class LiveTranslateIdleScreen extends StatefulWidget {
  const LiveTranslateIdleScreen({super.key});

  @override
  State<LiveTranslateIdleScreen> createState() =>
      _LiveTranslateIdleScreenState();
}

class _LiveTranslateIdleScreenState extends State<LiveTranslateIdleScreen> {
  String? _sourceLanguage = 'French';
  String? _targetLanguage = 'English';

  final List<String> languages = ['French', 'English', 'Portuguese'];

  final Map<String, String> languageCode = {
    'French': 'fr',
    'English': 'en',
    'Portuguese': 'pt',
  };

  @override
  Widget build(BuildContext context) {
    final transcriptionProvider =
        Provider.of<TranscriptionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Translate'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.mic, size: 100),
              const SizedBox(height: 24),

              // Source Language Dropdown
              DropdownButton<String>(
                value: _sourceLanguage,
                items: languages
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _sourceLanguage = newValue ?? 'French';
                  });
                  transcriptionProvider.setLanguages(
                    source: languageCode[_sourceLanguage]!,
                    target: languageCode[_targetLanguage]!,
                  );
                },
                hint: const Text('Select Source Language'),
              ),

              const SizedBox(height: 12),

              // Target Language Dropdown
              DropdownButton<String>(
                value: _targetLanguage,
                items: languages
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _targetLanguage = newValue ?? 'English';
                  });
                  transcriptionProvider.setLanguages(
                    source: languageCode[_sourceLanguage]!,
                    target: languageCode[_targetLanguage]!,
                  );
                },
                hint: const Text('Select Target Language'),
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
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  if (transcriptionProvider.isRecording) {
                    await transcriptionProvider.stopRecording();
                  } else {
                    if (_sourceLanguage == null || _targetLanguage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please select both source and target languages'),
                        ),
                      );
                      return;
                    }
                    await transcriptionProvider.startRecording();
                  }
                },
              ),

              const SizedBox(height: 24),

              // Display current transcription & translation
              if (transcriptionProvider.transcription.isNotEmpty ||
                  transcriptionProvider.translation.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (transcriptionProvider.transcription.isNotEmpty) ...[
                        const Text('Transcription:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(transcriptionProvider.transcription),
                        const SizedBox(height: 12),
                      ],
                      if (transcriptionProvider.translation.isNotEmpty) ...[
                        const Text('Translation:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(transcriptionProvider.translation),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
