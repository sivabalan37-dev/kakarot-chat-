import 'package:cloud_functions/cloud_functions.dart';

class UsernameTakenException implements Exception {
  const UsernameTakenException();
}

class ProfileService {
  ProfileService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<bool> isUsernameAvailable(String username) async {
    final callable = _functions.httpsCallable('checkUsername');
    final result = await callable.call<Map<String, dynamic>>({
      'username': username.trim(),
    });
    return result.data['available'] == true;
  }

  Future<void> completeProfile({
    required String username,
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      await _functions.httpsCallable('completeProfile').call({
        'username': username.trim(),
        'displayName': displayName.trim(),
        'photoURL': photoUrl,
      });
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'already-exists') {
        throw const UsernameTakenException();
      }
      rethrow;
    }
  }
}
