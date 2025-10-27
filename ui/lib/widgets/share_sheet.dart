import 'package:flutter/material.dart';

class ShareSheet extends StatefulWidget {
  final Map<String, dynamic> session;

  const ShareSheet({super.key, required this.session});

  @override
  _ShareSheetState createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  String selectedContent = 'Original';
  String selectedFormat = 'Text';
  bool includeHighlights = false;
  bool includeTimestamps = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Session Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Session: ${widget.session['name']}'),
                    Text('Language Pair: ${widget.session['languagePair']}'),
                    Text('Duration: ${widget.session['duration']}'),
                    Text('Date: ${widget.session['date']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content Selection
            const Text('Select Content', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ToggleButtons(
              isSelected: [
                selectedContent == 'Original',
                selectedContent == 'Translated',
                selectedContent == 'Both',
              ],
              onPressed: (index) {
                setState(() {
                  selectedContent = ['Original', 'Translated', 'Both'][index];
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Original'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Translated'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Both'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Format Selection
            const Text('Select Format', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ToggleButtons(
              isSelected: [
                selectedFormat == 'Text',
                selectedFormat == 'Audio',
                selectedFormat == 'PDF',
              ],
              onPressed: (index) {
                setState(() {
                  selectedFormat = ['Text', 'Audio', 'PDF'][index];
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Text'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Audio'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('PDF'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Plain text', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),

            // Include Options
            const Text('Include Options', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Highlights'),
                  selected: includeHighlights,
                  onSelected: (selected) {
                    setState(() {
                      includeHighlights = selected;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Timestamps'),
                  selected: includeTimestamps,
                  onSelected: (selected) {
                    setState(() {
                      includeTimestamps = selected;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Send To Section
            const Text('Send to', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
              children: const [
                Card(child: Center(child: Text('System Sheet'))),
                Card(child: Center(child: Text('Copy Link'))),
                Card(child: Center(child: Text('Email'))),
                Card(child: Center(child: Text('Export File'))),
                Card(child: Center(child: Text('Workspace'))),
                Card(child: Center(child: Text('Quick Send'))),
              ],
            ),
            const SizedBox(height: 16),

            // Bottom Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: implement share functionality
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
