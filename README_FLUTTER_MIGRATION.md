# Kakarot Chat — Flutter migration workspace

Production remains on `main`; Flutter development is isolated on `flutter-migration`.

## Current implementation status

This branch contains the Flutter app shell, Firebase initialization, Google sign-in integration, auth-state routing, username/password profile onboarding, password and username validators, a branded Kakarot Chat mark, and callable username/profile functions.

It is not yet a full chat replacement. Existing chat/message UI, username/password sign-in broker, password reset/change, full profile settings, media upload, notifications, presence, and end-to-end migration tests are still pending.

## Firebase configuration

- Existing project: `kakarot-chat`.
- Existing Android package: `com.kakarot.chat`.
- Keep Google sign-in enabled and enable Email/Password before testing password linking.
- Add the Android signing SHA-1/SHA-256 fingerprints to the same Firebase Android app.
- Add repository Actions secret `GOOGLE_SERVICES_JSON` with the complete Android configuration, or `GOOGLE_SERVICES_JSON_BASE64` with the complete file encoded once.
- The config must contain Android OAuth client type 1 and Web OAuth client type 3.
- Never commit service-account keys, signing keys, passwords, or tokens.

## Local Android setup

Install Flutter 3.44 or newer and Java 17. Generate the Android platform directory:

```bash
flutter create --platforms=android --org com.kakarot --project-name chat --no-pub .
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_OAUTH_CLIENT_ID
```

The web OAuth client ID is public client configuration, not a client secret. Obtain it from the type 3 OAuth entry in the existing Firebase Android configuration.

For debug App Check, register the debug token for your test installation in Firebase Console. Keep that token private and out of source control. Release builds use Play Integrity.

## Cloud Functions

```bash
cd functions
npm install
npm run build
cd ..
```

The callable functions enforce App Check and authentication. Deploy to a staging Firebase project first and test with the Firebase Emulator Suite before production deployment.

## Data preservation

The migration retains Firebase project, UID, chat ID, message ID, and Storage object paths. Profile completion writes `users/{uid}` and `profiles/{uid}` through Admin SDK using legacy-compatible fields. It does not migrate or rewrite chats yet.

Do not merge this branch into `main` or distribute the Flutter APK as a production replacement until Google UID continuity, Firestore rules, legacy conversation compatibility, and two-device end-to-end tests pass.
