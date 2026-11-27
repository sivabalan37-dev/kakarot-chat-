class PasswordValidator {
  static Map<String, bool> checks(String value) => {
        'At least 8 characters': value.length >= 8,
        'One uppercase letter': RegExp(r'[A-Z]').hasMatch(value),
        'One lowercase letter': RegExp(r'[a-z]').hasMatch(value),
        'One number': RegExp(r'[0-9]').hasMatch(value),
        'One special character': RegExp(r'[^A-Za-z0-9]').hasMatch(value),
      };

  static bool isStrong(String value) => checks(value).values.every((ok) => ok);
}
