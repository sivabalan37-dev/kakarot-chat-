class UsernameValidator {
  static const reserved = <String>{
    'admin', 'administrator', 'support', 'help', 'moderator',
    'kakarot', 'firebase', 'google', 'root', 'system', 'null', 'undefined',
  };

  static String normalize(String input) => input.trim().toLowerCase();

  static String? validate(String input) {
    final value = normalize(input);
    if (value.length < 3 || value.length > 20) {
      return 'Username must be 3–20 characters.';
    }
    if (!RegExp(r'^[a-z0-9](?:[a-z0-9._]*[a-z0-9])$').hasMatch(value)) {
      return 'Use only letters, numbers, underscores, and periods. '
          'Do not begin or end with punctuation.';
    }
    if (reserved.contains(value)) return 'This username is not available.';
    return null;
  }
}
