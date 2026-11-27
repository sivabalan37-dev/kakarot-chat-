import 'package:flutter/material.dart';

class MigrationHomeScreen extends StatelessWidget {
  const MigrationHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kakarot Chat'),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.forum_rounded, size: 64),
                const SizedBox(height: 20),
                Text(
                  'Flutter migration workspace',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'This is the isolated Flutter foundation. Existing Google '
                  'sign-in and production chat data have not been changed. '
                  'Authentication and legacy-data compatibility must be '
                  'implemented and tested before this app is used as a replacement.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Migration status: foundation only\n'
                      'Production login: not connected\n'
                      'Legacy chat migration: not yet verified',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
