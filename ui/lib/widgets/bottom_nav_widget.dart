import 'package:flutter/material.dart';

class BottomNavWidget extends StatefulWidget {
  const BottomNavWidget({super.key});

  @override
  State<BottomNavWidget> createState() => _BottomNavWidgetState();
}

class _BottomNavWidgetState extends State<BottomNavWidget> {
  int _selectedIndex = 0;

  // Pages for each tab
  static const List<Widget> _pages = [
    HomeScreen(),
    LiveScreen(),
    SessionsScreen(),
    ParametersScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            tooltip: 'Go to Home Screen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Live',
            tooltip: 'Live Translation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Sessions',
            tooltip: 'View Past Sessions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
            tooltip: 'App Settings',
          ),
        ],
      ),
    );
  }
}

// Placeholder screens
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Home Screen', style: TextStyle(color: Colors.white)));
}

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Live Screen', style: TextStyle(color: Colors.white)));
}

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Sessions Screen', style: TextStyle(color: Colors.white)));
}

class ParametersScreen extends StatelessWidget {
  const ParametersScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Parameters Screen', style: TextStyle(color: Colors.white)));
}
