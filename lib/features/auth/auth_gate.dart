import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/google_auth_service.dart';
import '../home/chat_home_screen.dart';
import '../onboarding/profile_setup_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  int _profileAttempt = 0;

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadProfile(String uid) {
    return FirebaseFirestore.instance.collection('profiles').doc(uid).get();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = authSnapshot.data;
        if (user == null) return const SignInScreen();

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          key: ValueKey<String>('\${user.uid}:\${_profileAttempt}'),
          future: _loadProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }
            if (profileSnapshot.hasError) {
              return _ProfileLoadError(
                onRetry: () => setState(() => _profileAttempt++),
                onSignOut: GoogleAuthService.instance.signOut,
              );
            }

            final data = profileSnapshot.data?.data();
            final username = data?['username'];
            final usernameLower = data?['username_lower'];
            final profileReady = profileSnapshot.data?.exists == true &&
                username is String &&
                username.trim().isNotEmpty &&
                usernameLower is String &&
                usernameLower.trim().isNotEmpty;

            if (profileReady) return const ChatHomeScreen();
            return ProfileSetupScreen(user: user);
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({
    required this.onRetry,
    required this.onSignOut,
  });

  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load your profile. Check your connection.'),
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
                TextButton(onPressed: onSignOut, child: const Text('Sign out')),
              ],
            ),
          ),
        ),
      );
}
