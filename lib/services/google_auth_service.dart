import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();
  static final instance = GoogleAuthService._();

  final GoogleSignIn _google = GoogleSignIn.instance;
  Future<void>? _ready;

  Future<void> initialize() {
    return _ready ??= _initializeGoogle();
  }

  Future<void> _initializeGoogle() async {
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    await _google.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
  }

  Future<UserCredential?> signIn() async {
    await initialize();
    try {
      final account = await _google.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google sign-in did not return an ID token.',
        );
      }
      return FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: token),
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      await _google.signOut();
    } catch (_) {
      // Do not log authentication material.
    }
  }
}
