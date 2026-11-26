import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/kakarot_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android Firebase options are loaded from the native
  // google-services.json configuration. Never commit private credentials.
  await Firebase.initializeApp();

  runApp(const KakarotApp());
}
