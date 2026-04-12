import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../models/breach_result.dart';

/// Interfaces with the Have I Been Pwned and XposedOrNot APIs.
///
/// Password checks use k-anonymity: only the first 5 characters of the SHA-1
/// hash are sent to the server; the plaintext password is never transmitted.
///
/// Email checks send the full email address to the XposedOrNot API
/// (https://api.xposedornot.com) — free, no API key required.
///
/// Password endpoint: https://api.pwnedpasswords.com/range/{first5}
///   — free, no API key required.
///
/// Email endpoint: https://api.xposedornot.com/v1/check-email/{email}
///   — free, no API key required.
class PwnedApiService {
  PwnedApiService({
    http.Client? httpClient,
  })  : _client = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  final http.Client _client;
  final bool _ownsClient;

  /// Releases the internally created HTTP client.
  ///
  /// If a client was injected via the constructor, ownership remains with the
  /// caller and this method does not close it.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static const String _passwordRangeBase =
      'https://api.pwnedpasswords.com/range/';
  static const String _emailBreachBase =
      'https://api.xposedornot.com/v1/check-email/';

  // ─── Password check ─────────────────────────────────────────────────────────

  /// Checks [password] against the pwnedpasswords range API using k-anonymity.
  ///
  /// Only the first 5 characters of the SHA-1 hash are sent to the server;
  /// the full hash is never transmitted.
  Future<BreachResult> checkPassword(String password) async {
    if (password.isEmpty) {
      return BreachResult(
        input: password,
        checkType: CheckType.password,
        isPwned: false,
        errorMessage: 'Password must not be empty.',
      );
    }

    final hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();
    final prefix = hash.substring(0, 5);
    final suffix = hash.substring(5);

    try {
      final uri = Uri.parse('$_passwordRangeBase$prefix');
      final response = await _client.get(
        uri,
        headers: {'Add-Padding': 'true'},
      );

      if (response.statusCode != 200) {
        return BreachResult(
          input: password,
          checkType: CheckType.password,
          isPwned: false,
          errorMessage:
              'API request failed with status ${response.statusCode}.',
        );
      }

      final count = _findHashCount(response.body, suffix);
      return BreachResult(
        input: password,
        checkType: CheckType.password,
        isPwned: count > 0,
        pwnedCount: count,
      );
    } catch (e) {
      return BreachResult(
        input: password,
        checkType: CheckType.password,
        isPwned: false,
        errorMessage: 'Network error: $e',
      );
    }
  }

  // ─── Email check ────────────────────────────────────────────────────────────

  /// Checks [email] against the XposedOrNot breach database.
  ///
  /// No API key is required. Returns a [BreachResult] with named breaches
  /// when found, or a clean result when the email is not in any breach.
  Future<BreachResult> checkEmail(String email) async {
    if (email.isEmpty) {
      return BreachResult(
        input: email,
        checkType: CheckType.email,
        isPwned: false,
        errorMessage: 'Email must not be empty.',
      );
    }

    try {
      final encodedEmail = Uri.encodeComponent(email);
      final uri = Uri.parse('$_emailBreachBase$encodedEmail');
      final response = await _client.get(
        uri,
        headers: {
          'user-agent': 'pascurtain-app'
        },
      );

      if (response.statusCode == 404) {
        // 404 means no breaches found — this is not an error
        return BreachResult(
          input: email,
          checkType: CheckType.email,
          isPwned: false,
        );
      }

      if (response.statusCode == 429) {
        return BreachResult(
          input: email,
          checkType: CheckType.email,
          isPwned: false,
          errorMessage: 'Rate limit exceeded. Please wait a moment and try again.',
        );
      }

      if (response.statusCode != 200) {
        return BreachResult(
          input: email,
          checkType: CheckType.email,
          isPwned: false,
          errorMessage:
              'API request failed with status ${response.statusCode}.',
        );
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      // XposedOrNot returns {"Error":"Not found","email":null} with a 200 status
      // when no breaches are found.
      if (jsonData.containsKey('Error')) {
        return BreachResult(
          input: email,
          checkType: CheckType.email,
          isPwned: false,
        );
      }

      // Breaches are returned as a list of single-element lists, e.g.:
      // {"breaches":[["BreachName"]],"email":"...","status":"success"}
      final rawBreaches = jsonData['breaches'];
      final breachNames = <String>[];
      if (rawBreaches is List) {
        for (final b in rawBreaches) {
          if (b is List && b.isNotEmpty) {
            final name = b.first?.toString();
            if (name != null) breachNames.add(name);
          }
        }
      }

      return BreachResult(
        input: email,
        checkType: CheckType.email,
        isPwned: breachNames.isNotEmpty,
        breaches: breachNames,
      );
    } catch (e) {
      return BreachResult(
        input: email,
        checkType: CheckType.email,
        isPwned: false,
        errorMessage: 'Network error: $e',
      );
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  /// Parses the HIBP range response body and returns the occurrence count for
  /// [hashSuffix], or 0 if not found.
  int _findHashCount(String body, String hashSuffix) {
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split(':');
      if (parts.length != 2) continue;
      if (parts[0].toUpperCase() == hashSuffix) {
        return int.tryParse(parts[1]) ?? 0;
      }
    }
    return 0;
  }
}
