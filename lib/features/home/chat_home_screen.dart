import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/google_auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/kakarot_brand.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final _search = TextEditingController();
  final _profiles = ProfileService();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _loading = false;
        _error = null;
        _results = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _searchUsers(value));
  }

  Future<void> _searchUsers(String value) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _profiles.searchUsers(value);
      if (!mounted || value.trim() != _search.text.trim()) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Search is temporarily unavailable. Please try again.';
      });
    }
  }

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Center(child: KakarotBrand(size: 88)),
            const SizedBox(height: 22),
            Text('Welcome, ${user?.displayName ?? 'Kakarot user'}'),
            const SizedBox(height: 18),
            TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Search by username or full email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _search.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading) const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )),
            if (_error != null) Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            if (!_loading && _error == null && _search.text.trim().length >= 2 && _results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No one found. Ask your friend to sign in once to appear in search.',
                    textAlign: TextAlign.center),
              ),
            ..._results.map((profile) => ListTile(
              leading: CircleAvatar(
                backgroundImage: (profile['profile_photo'] as String?)?.isNotEmpty == true
                    ? NetworkImage(profile['profile_photo'] as String)
                    : null,
                child: (profile['profile_photo'] as String?)?.isNotEmpty == true
                    ? null
                    : const Icon(Icons.person),
              ),
              title: Text(profile['username'] as String? ?? 'Kakarot user'),
              subtitle: Text(profile['status'] == 'online' ? 'Online' : 'Offline'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Found @${profile['username']}. Chat migration is the next step.')),
                );
              },
            )),
            const SizedBox(height: 22),
            if (_search.text.trim().isEmpty)
              const Text(
                'No chats yet. Search for a friend by username or full email to find them.',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
