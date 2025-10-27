import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sessions_provider.dart';
import '../widgets/bottom_nav_widget.dart';

class SessionsListScreen extends StatefulWidget {
  const SessionsListScreen({super.key});

  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch sessions after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionProvider>(context, listen: false)
          .fetchLastSessions(numberSessions: 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sessions List')),
      body: Builder(
        builder: (_) {
          if (sessionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (sessionProvider.errorMessage != null) {
            return Center(
              child: Text(
                'Error: ${sessionProvider.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (sessionProvider.sessions.isEmpty) {
            return const Center(child: Text('No sessions found'));
          } else {
            return ListView.builder(
              itemCount: sessionProvider.sessions.length,
              itemBuilder: (context, index) {
                final session = sessionProvider.sessions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.mic),
                    title: Text(session['name'] ?? 'Unnamed Session'),
                    subtitle: Text(session['original_text'] ?? ''),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/session-playback',
                        arguments: session['id'],
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: const BottomNavWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          sessionProvider.fetchLastSessions(numberSessions: 10);
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
