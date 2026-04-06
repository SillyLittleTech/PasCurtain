import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/breach_result.dart';
import '../theme/app_theme.dart';

/// Displays the result of a breach check and, when the input was pwned,
/// offers suggested replacement passwords.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.result,
    required this.suggestions,
    required this.onReset,
  });

  final BreachResult result;
  final List<String> suggestions;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (result.hasError) {
      return _ErrorCard(message: result.errorMessage!, onReset: onReset);
    }

    if (result.isPwned) {
      return _PwnedCard(
        result: result,
        suggestions: suggestions,
        onReset: onReset,
      );
    }

    return _SafeCard(result: result, onReset: onReset);
  }
}

// ─── Safe card ───────────────────────────────────────────────────────────────

class _SafeCard extends StatelessWidget {
  const _SafeCard({required this.result, required this.onReset});

  final BreachResult result;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successColor = AppTheme.successColor(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.verified_user_outlined, size: 48, color: successColor),
            const SizedBox(height: 12),
            // TODO(rename): update safe-result headline on rebrand
            Text(
              'No breaches found!',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: successColor, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // TODO(rename): update safe-result body on rebrand
            Text(
              result.checkType == CheckType.password
                  ? 'This password does not appear in any known breach database. '
                    'Keep using it — but never share it with anyone.'
                  : 'This email address was not found in any known breaches.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              // TODO(rename): update button label on rebrand
              label: const Text('Check another'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pwned card ───────────────────────────────────────────────────────────────

class _PwnedCard extends StatelessWidget {
  const _PwnedCard({
    required this.result,
    required this.suggestions,
    required this.onReset,
  });

  final BreachResult result;
  final List<String> suggestions;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = AppTheme.errorColor(context);

    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: errorColor.withAlpha(120)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: errorColor, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TODO(rename): update pwned headline on rebrand
                          Text(
                            'Breach detected!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: errorColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (result.checkType == CheckType.password &&
                              result.pwnedCount > 0)
                            Text(
                              // TODO(rename): update count description on rebrand
                              'Seen ${_formatCount(result.pwnedCount)} time${result.pwnedCount == 1 ? '' : 's'} in data breaches',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // TODO(rename): update breach advice on rebrand
                Text(
                  result.checkType == CheckType.password
                      ? 'This password has been exposed in known data breaches. '
                        'You should change it immediately on any account where you use it.'
                      : 'This email address was found in the following breach${result.breaches.length == 1 ? '' : 'es'}:',
                  style: theme.textTheme.bodyMedium,
                ),
                if (result.checkType == CheckType.email &&
                    result.breaches.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.breaches
                        .map(
                          (b) => Chip(
                            label: Text(b),
                            avatar: const Icon(
                              Icons.security_outlined,
                              size: 16,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SuggestionsCard(suggestions: suggestions),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          // TODO(rename): update button label on rebrand
          label: const Text('Check another'),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─── Suggestions card ────────────────────────────────────────────────────────

class _SuggestionsCard extends StatelessWidget {
  const _SuggestionsCard({required this.suggestions});

  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_fix_high_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                // TODO(rename): update suggestions headline on rebrand
                Text(
                  'Suggested passwords',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // TODO(rename): update suggestions description on rebrand
            Text(
              'Tap a suggestion to copy it to your clipboard.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...suggestions.map(
              (s) => _SuggestionTile(password: s),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _copyToClipboard(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  password,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(
                Icons.copy_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: password));
    ScaffoldMessenger.of(context).showSnackBar(
      // TODO(rename): update copied snackbar message on rebrand
      const SnackBar(content: Text('Password copied to clipboard!')),
    );
  }
}

// ─── Error card ───────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onReset});

  final String message;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48,
                color: theme.colorScheme.error),
            const SizedBox(height: 12),
            // TODO(rename): update error headline on rebrand
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              // TODO(rename): update button label on rebrand
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
