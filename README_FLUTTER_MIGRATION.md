# Kakarot Chat — Flutter migration workspace

The active production application remains on `main`. Flutter work is isolated on `flutter-migration`.

This branch currently contains only a Flutter foundation and migration safety documentation. It is **not yet a production-ready chat application** and does not yet implement Google sign-in, username/password login, chat access, notifications, or file sharing.

See [docs/FLUTTER_MIGRATION.md](docs/FLUTTER_MIGRATION.md) for the staged migration and data-preservation gates.

## Local setup

1. Install Flutter and Android Studio.
2. Configure the existing Firebase Android app for package `com.kakarot.chat`.
3. Supply a valid Firebase Android configuration securely.
4. Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Do not deploy Firestore/Storage rules or replace the production APK from this scaffold.
