# Kakarot Chat

Kakarot Chat is a browser-first Firebase chat application with a Capacitor Android wrapper.

## Firebase project

The web app uses the Firebase project `kakarot-chat`. Keep the Firebase configuration consistent in `index.html`, `firebase.js`, and `firebase-messaging-sw.js`.

## Required Firebase setup

In Firebase Console for project `kakarot-chat`:

1. Enable **Authentication → Google** and add every deployed web host under **Authorized domains**.
2. Create/enable the **Cloud Firestore** database.
3. Enable **Storage**.
4. Deploy the repository rules from the project root:
   ```sh
   npm install -g firebase-tools
   firebase login
   firebase use kakarot-chat
   firebase deploy --only firestore:rules,storage
   ```
5. For web push, configure a Web Push certificate (VAPID key) and verify the public VAPID key in `index.html` belongs to this same Firebase project.

The attachment feature stores files in Firebase Storage under `chat_uploads/{chatId}/{uid}/`. Files are limited to 15 MB. Storage access is restricted to authenticated members of that chat. The rules rely on the Firestore chat document existing before upload.

## Android Google sign-in

The Android build includes `@capacitor-firebase/authentication`. Native Google sign-in also needs the Android Firebase app registered in Firebase Console:

1. Add an Android app with package name `com.kakarot.chat`.
2. Add the SHA-1 and SHA-256 signing fingerprints for the signing key used by the APK.
3. Download that app's `google-services.json`.
4. Base64-encode the file and add it to GitHub Actions secrets as `GOOGLE_SERVICES_JSON_BASE64`.
5. Re-run the **Build Android APK** workflow.

Without that Android configuration, the APK may compile but native Google sign-in will not complete. The web app continues to use Firebase Google popup sign-in on supported browsers.

## Build

The GitHub Actions workflow `.github/workflows/build_apk.yml` builds a debug APK and uploads it as the `kakarot-chat-apk` artifact. Open the latest successful workflow run in GitHub Actions to download it.

## Important

- Never commit a Firebase service-account key, private key, or production credentials.
- Firebase web configuration and Web Push VAPID keys are client-side identifiers; protect data with Firebase Security Rules and App Check.
- Test authentication, chat creation, messaging, read receipts, blocking, and attachments using two separate test accounts before production use.
- The optional `cloud_server.js` relay is separate from the Firebase chat path and must be deployed/configured independently if the app is extended to use it.
