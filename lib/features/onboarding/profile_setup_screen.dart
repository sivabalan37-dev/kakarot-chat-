import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/validators/password_validator.dart';
import '../../core/validators/username_validator.dart';
import '../../services/profile_service.dart';
import '../home/chat_home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({required this.user, super.key});
  final User user;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _service = ProfileService();

  Timer? _debounce;
  bool _checking = false;
  bool _available = false;
  bool _saving = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _availabilityMessage;

  @override
  void initState() {
    super.initState();
    _displayName.text = widget.user.displayName ?? '';
    _username.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _username.removeListener(_onUsernameChanged);
    _username.dispose();
    _displayName.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    _debounce?.cancel();
    final value = _username.text.trim();
    final validation = UsernameValidator.validate(value);
    setState(() {
      _available = false;
      _availabilityMessage = validation;
      _checking = validation == null && value.isNotEmpty;
    });
    if (validation != null || value.isEmpty) return;

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final available = await _service.isUsernameAvailable(value);
        if (!mounted || value != _username.text.trim()) return;
        setState(() {
          _checking = false;
          _available = available;
          _availabilityMessage = available ? 'Username available' : 'Username already taken.';
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _checking = false;
          _available = false;
          _availabilityMessage = 'Could not check username. Try again.';
        });
      }
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (!PasswordValidator.isStrong(_password.text)) return;
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != widget.user.uid) {
        throw StateError('Your sign-in session expired. Sign in again.');
      }

      final hasPasswordProvider = user.providerData.any(
        (item) => item.providerId == EmailAuthProvider.PROVIDER_ID,
      );

      // Retry-safe: a previous link may have succeeded even if profile
      // completion failed. Never create a second Firebase account.
      if (!hasPasswordProvider) {
        final email = user.email;
        if (email == null || email.isEmpty) {
          throw StateError('Your Google account does not provide an email address.');
        }
        final credential = EmailAuthProvider.credential(
          email: email,
          password: _password.text,
        );
        await user.linkWithCredential(credential);
        await user.reload();
        user = FirebaseAuth.instance.currentUser;
      }

      await _service.completeProfile(
        username: _username.text.trim(),
        displayName: _displayName.text.trim(),
        photoUrl: user?.photoURL,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ChatHomeScreen()),
        (_) => false,
      );
    } on UsernameTakenException {
      setState(() {
        _available = false;
        _availabilityMessage = 'Username already taken.';
      });
    } on FirebaseAuthException catch (error) {
      final message = switch (error.code) {
        'email-already-in-use' => 'This email is already associated with an account. Sign in using its existing method.',
        'credential-already-in-use' => 'This credential is already linked to another account. Contact support.',
        'provider-already-linked' => 'A password is already linked. Retry profile creation.',
        'requires-recent-login' => 'Please sign in with Google again to continue.',
        'weak-password' => 'Your password does not meet the security requirements.',
        'network-request-failed' => 'Connection problem. Please try again.',
        _ => 'Account setup could not be completed. Please try again.',
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your profile. Please try again.')),
        );
      }
    } finally {
      _password.clear();
      _confirmPassword.clear();
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.user.photoURL;
    final strength = PasswordValidator.checks(_password.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Create your Kakarot profile')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: photo == null || photo.isEmpty ? null : NetworkImage(photo),
                        child: photo == null || photo.isEmpty ? const Icon(Icons.person, size: 40) : null,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _displayName,
                      decoration: const InputDecoration(labelText: 'Display name', border: OutlineInputBorder()),
                      maxLength: 40,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter a display name.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(labelText: 'Username', hintText: 'example_01', border: OutlineInputBorder()),
                      autocorrect: false,
                      validator: UsernameValidator.validate,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_checking)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          Icon(_available ? Icons.check_circle : Icons.info_outline,
                              color: _available ? Colors.green : Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _availabilityMessage ?? '3–20 characters; letters, numbers, . and _.',
                            style: TextStyle(color: _available ? Colors.green : null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: !_showPassword,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (value) => value != null && PasswordValidator.isStrong(value)
                          ? null
                          : 'Use 8+ characters with uppercase, lowercase, number and symbol.',
                    ),
                    const SizedBox(height: 8),
                    ...strength.entries.map((entry) => Row(
                          children: [
                            Icon(entry.value ? Icons.check_circle : Icons.circle_outlined,
                                size: 16, color: entry.value ? Colors.green : Colors.grey),
                            const SizedBox(width: 8),
                            Text(entry.key),
                          ],
                        )),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPassword,
                      obscureText: !_showConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _showConfirm = !_showConfirm),
                          icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (value) => value == _password.text ? null : 'Passwords do not match.',
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Create account'),
                    ),
                    const SizedBox(height: 12),
                    const Text('Your Google account and Firebase identity stay the same.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
