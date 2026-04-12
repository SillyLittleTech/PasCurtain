/// Represents the outcome of a breach check against the pwnedpasswords API.
class BreachResult {
  const BreachResult({
    required this.input,
    required this.checkType,
    required this.isPwned,
    this.pwnedCount = 0,
    this.breaches = const [],
    this.errorMessage,
  });

  /// The original value that was checked (password or email).
  final String input;

  /// Whether this was a password or email check.
  final CheckType checkType;

  /// True when the input was found in a data breach.
  final bool isPwned;

  /// Number of times the password hash appeared in breach data (passwords only).
  final int pwnedCount;

  /// Named breaches (email checks only).
  final List<String> breaches;

  /// Non-null when the check could not be completed due to an error.
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

enum CheckType { password, email }
