import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/kakarot_app.dart';
import 'services/google_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // firebase_app_check 0.5.x uses provider objects and providerAndroid.
  // Debug tokens must be registered in Firebase Console for development;
  // production builds use Play Integrity.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
  );

  await GoogleAuthService.instance.initialize();
  runApp(const KakarotApp());
}
