import 'package:flutter/material.dart';

class ParametersScreen extends StatefulWidget {
  @override
  _ParametersScreenState createState() => _ParametersScreenState();
}

class _ParametersScreenState extends State<ParametersScreen> {
  String _theme = 'System';
  String _transcriptionModel = 'Balanced';
  String _defaultLanguage = 'EN→ES';
  bool _autoGainControl = false;
  bool _noiseReduction = false;
  String _activeView = 'Original';
  String _highlightStyle = 'On';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parameters'),
        actions: [
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {
              // Implement help action
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configure your experience', style: TextStyle(fontSize: 20)),
            SizedBox(height: 24),
            _buildAppearanceSection(),
            SizedBox(height: 16),
            _buildModelLanguageSection(),
            SizedBox(height: 16),
            _buildRecordingSection(),
            SizedBox(height: 16),
            _buildTextDisplaySection(),
            SizedBox(height: 16),
            _buildAccountSection(),
            SizedBox(height: 16),
            _buildAboutUsSection(),
            Spacer(),
            _buildActionButtons(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appearance', style: TextStyle(fontSize: 18)),
        DropdownButton<String>(
          value: _theme,
          onChanged: (String? newValue) {
            setState(() {
              _theme = newValue!;
            });
          },
          items: <String>['System', 'Light', 'Dark']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModelLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Model & Language', style: TextStyle(fontSize: 18)),
        DropdownButton<String>(
          value: _transcriptionModel,
          onChanged: (String? newValue) {
            setState(() {
              _transcriptionModel = newValue!;
            });
          },
          items: <String>['Balanced', 'Quality', 'Speed']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        DropdownButton<String>(
          value: _defaultLanguage,
          onChanged: (String? newValue) {
            setState(() {
              _defaultLanguage = newValue!;
            });
          },
          items: <String>['EN→ES', 'EN→FR', 'EN→DE']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecordingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recording', style: TextStyle(fontSize: 18)),
        SwitchListTile(
          title: Text('Auto Gain Control'),
          value: _autoGainControl,
          onChanged: (bool value) {
            setState(() {
              _autoGainControl = value;
            });
          },
        ),
        SwitchListTile(
          title: Text('Noise Reduction'),
          value: _noiseReduction,
          onChanged: (bool value) {
            setState(() {
              _noiseReduction = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTextDisplaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Text Display', style: TextStyle(fontSize: 18)),
        DropdownButton<String>(
          value: _activeView,
          onChanged: (String? newValue) {
            setState(() {
              _activeView = newValue!;
            });
          },
          items: <String>['Original', 'Translation']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        DropdownButton<String>(
          value: _highlightStyle,
          onChanged: (String? newValue) {
            setState(() {
              _highlightStyle = newValue!;
            });
          },
          items: <String>['On', 'Off']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account', style: TextStyle(fontSize: 18)),
        TextButton(
          onPressed: () {
            // Implement sign up
          },
          child: Text('Sign Up'),
        ),
        TextButton(
          onPressed: () {
            // Implement sign in
          },
          child: Text('Sign In'),
        ),
      ],
    );
  }

  Widget _buildAboutUsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About Us', style: TextStyle(fontSize: 18)),
        TextButton(
          onPressed: () {
            // Implement GitHub link
          },
          child: Text('GitHub'),
        ),
        TextButton(
          onPressed: () {
            // Implement LinkedIn link
          },
          child: Text('LinkedIn'),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () {
            // Implement cancel action
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Implement save action
          },
          child: Text('Save Changes'),
        ),
      ],
    );
  }
}