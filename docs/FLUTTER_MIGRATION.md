# Flutter migration implementation notes

## Current implementation

- Flutter app shell and dark theme.
- Firebase initialization.
- Google sign-in using google_sign_in 7.x with Firebase Auth credential sign-in.
- Auth state gate reading `profiles/{uid}`.
- First-run profile setup with Google display name/photo defaults, custom display name, unique username check, password strength checks, confirmation, and `linkWithCredential`.
- Username availability and profile completion callable Cloud Functions.
- Atomic username reservation and private username-to-email mapping in a Firestore transaction.
- Username and complete-profile callable rate limits.
- App Check activation: debug provider in debug builds, Play Integrity in release builds.
- Flutter Android CI workflow builds a debug APK and uploads it as an artifact.
- Original orange-orb/constellation/chat-bubble brand mark drawn in Flutter; it is not a reproduction of a franchise logo.

## Not implemented yet

- Username/password sign-in broker.
- Forgot password and change password UI.
- Username change with reauthentication/cooldown.
- Existing chat list, message timeline, sending, receipts, unread counts, typing, presence.
- Pinned/archived chats, message search.
- Storage uploads, voice notes, compression and attachment previews.
- FCM registration and push delivery.
- Account deletion flow.
- Full Firestore Emulator Suite and device tests.
- Signed release build.

## Important rollout requirements

1. Back up Firestore and inventory Storage objects before any production changes.
2. Enable Email/Password in the existing Firebase project while leaving Google enabled.
3. Verify the current Android Firebase app has the correct package and OAuth client entries.
4. Configure/register App Check debug and Play Integrity for the existing Android app.
5. Deploy functions to staging and test race conditions, rate limits and App Check.
6. Verify existing Google sign-in yields the same UID as the Capacitor app.
7. Verify a linked password provider belongs to that same UID.
8. Test that profile completion produces the expected profile document and valid SHA-256 email hash.
9. Verify the existing JavaScript app remains compatible with any rules changes.
10. Port the existing Firestore chat/message schema read-only first, then write only backward-compatible data.

## Release rule

No merge to production `main`, no production rules deployment, and no replacement APK until all migration gates and acceptance tests pass.
