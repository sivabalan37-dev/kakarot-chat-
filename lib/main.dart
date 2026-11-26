import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app/kakarot_app.dart';
import 'services/google_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GoogleAuthService.instance.initialize();
  runApp(const KakarotApp());
}
