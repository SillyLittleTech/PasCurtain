import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../models/breach_result.dart';

/// Interfaces with the Have I Been Pwned API using k-anonymity so that
/// the full password or email is never transmitted to any remote server.
///
/// Password endpoint: https://api.pwnedpasswords.com/range/{first5}
///   — free, no API key required.
///
/// Email endpoint: https://haveibeenpwned.com/api/v3/breachedaccount/{email}
///   — requires a paid API key set via [hibpApiKey].
class PwnedApiService {
  PwnedApiService({
    this.hibpApiKey,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  /// Optional Have I Been Pwned API key for email breach lookups.
  /// See https://haveibeenpwned.com/API/Key
  final String? hibpApiKey;

  final http.Client _client;

  static const String _passwordRangeBase =
      'https://api.pwnedpasswords.com/range/';
  static const String _emailBreachBase =
      'https://haveibeenpwned.com/api/v3/breachedaccount/';

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

  /// Checks [email] against the HIBP breached account API.
  ///
  /// Requires a valid [hibpApiKey] to be configured; returns an error result
  /// when no key is provided so the UI can prompt the user to add one.
  Future<BreachResult> checkEmail(String email) async {
    if (email.isEmpty) {
      return BreachResult(
        input: email,
        checkType: CheckType.email,
        isPwned: false,
        errorMessage: 'Email must not be empty.',
      );
    }

    if (hibpApiKey == null || hibpApiKey!.isEmpty) {
      return BreachResult(
        input: email,
        checkType: CheckType.email,
        isPwned: false,
        errorMessage:
            'An API key is required to check email addresses. '
            'Get one at https://haveibeenpwned.com/API/Key',
      );
    }

    try {
      final encodedEmail = Uri.encodeComponent(email);
      final uri = Uri.parse(
        '$_emailBreachBase$encodedEmail?truncateResponse=false',
      );
      final response = await _client.get(
        uri,
        headers: {
          'hibp-api-key': hibpApiKey!,
          'user-agent': 'powwow-app', // TODO(rename): update user-agent on rebrand
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

      if (response.statusCode == 401) {
        return BreachResult(
          input: email,
          checkType: CheckType.email,
          isPwned: false,
          errorMessage: 'Invalid API key. Check your HIBP API key and try again.',
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

      final jsonData = jsonDecode(response.body) as List<dynamic>;
      final breachNames = jsonData
          .map((b) => (b as Map<String, dynamic>)['Name'] as String)
          .toList();

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
