# Kakarot Chat Flutter migration

## Safety boundary

- Work on `flutter-migration`; do not replace `main` during migration.
- Keep Firebase project `kakarot-chat` and Android application ID `com.kakarot.chat`.
- Do not delete, rename, bulk-rewrite, or recreate Firebase Authentication users.
- Preserve Firebase UIDs, chat IDs, message document IDs, Storage object paths, and attachment URLs.
- Do not deploy changed Firestore or Storage rules until they have been compared with the production rules and tested in the Firebase Emulator Suite.
- Never put service-account credentials, OAuth client secrets, signing keys, passwords, or tokens in source control.

## Current scaffold

This branch contains an isolated Flutter application foundation. It is intentionally not wired to production sign-in or production Firestore yet. The visible screen states this explicitly; it must not be presented as a working replacement APK.

## Required migration gates

1. Inventory the complete Firestore schema, subcollections, indexes, Storage paths, Cloud Functions, Authentication providers, and current security rules.
2. Back up Firestore and inventory Storage objects before any production data changes.
3. Configure Android Firebase using the existing Firebase Android app registration and a valid `google-services.json` for package `com.kakarot.chat`. Do not commit that file if repository policy treats it as sensitive; supply it through protected build configuration.
4. Implement Google sign-in and prove an existing test account returns exactly the same Firebase UID. Do not introduce a second Firebase project.
5. Implement read-only adapters for legacy `users`, `profiles`, `chats`, `messages`, and Storage paths. Verify actual document shapes before writing any migration.
6. Add profile backfill as an explicit, idempotent, owner-scoped operation. Do not assume the empty `profiles` collection means user accounts are absent.
7. Add linked email/password credentials with `linkWithCredential` only for the currently authenticated Google user. Never create duplicate users.
8. Add username reservation through a trusted server transaction and private username-to-email mapping. Do not let clients write private mappings.
9. Port chat features incrementally while retaining legacy document identifiers and compatible fields.
10. Run emulator tests, two-device end-to-end tests, debug and release builds before considering a rollout.

## Data compatibility questions to resolve from the full source

- Exact participant field names and chat ID generation.
- Message sender, timestamp, attachment, status, and read-receipt field names.
- Existing blocked-user subcollection format.
- Existing Storage metadata and access rules.
- Existing FCM token and notification payload format.
- Whether presence currently uses Firestore, Realtime Database, or another mechanism.

## Release rule

Do not merge this branch into `main`, deploy rules, or distribute its APK as a replacement until all migration gates and acceptance tests pass.
