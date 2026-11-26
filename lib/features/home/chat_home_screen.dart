import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/google_auth_service.dart';
import '../../widgets/kakarot_brand.dart';

class ChatHomeScreen extends StatelessWidget {
  const ChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kakarot Chat'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: GoogleAuthService.instance.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const KakarotBrand(size: 84),
              const SizedBox(height: 20),
              Text("Welcome, ${user?.displayName ?? 'Kakarot user'}"),
              const SizedBox(height: 8),
              const Text(
                'Profile setup is connected. Existing conversations are not yet wired into this Flutter screen.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
