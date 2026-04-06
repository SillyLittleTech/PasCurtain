import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/breach_result.dart';
import '../services/password_generator.dart';
import '../services/pwned_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/check_type_selector.dart';
import '../widgets/result_card.dart';

/// The main screen of the app.
///
/// Allows the user to enter a password or email and check it against the
/// Have I Been Pwned API. Results and password suggestions are shown inline.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();
  final _apiKeyController = TextEditingController();

  CheckType _checkType = CheckType.password;
  bool _isLoading = false;
  bool _obscureInput = true;
  BreachResult? _result;
  List<String> _suggestions = [];

  final _generator = PasswordGenerator(length: 20);
  final _httpClient = http.Client();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _apiKeyController.dispose();
    _httpClient.close();
    super.dispose();
  }

  Future<void> _performCheck() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _result = null;
      _suggestions = [];
    });

    final input = _inputController.text.trim();
    final apiKey =
        _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim();
    final service = PwnedApiService(hibpApiKey: apiKey, httpClient: _httpClient);

    final result = _checkType == CheckType.password
        ? await service.checkPassword(input)
        : await service.checkEmail(input);

    List<String> suggestions = [];
    if (result.isPwned && _checkType == CheckType.password) {
      suggestions = _generator.generate(count: 3);
    }

    setState(() {
      _isLoading = false;
      _result = result;
      _suggestions = suggestions;
    });
  }

  void _resetForm() {
    setState(() {
      _result = null;
      _suggestions = [];
      _inputController.clear();
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        // TODO(rename): Update app name displayed in AppBar when rebranding
        title: const Text('powwow'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip:
                isDark ? 'Switch to light mode' : 'Switch to dark mode', // TODO(rename): update tooltip on rebrand
            onPressed: themeNotifier.toggle,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 28),
                  _buildCheckForm(theme),
                  if (_result != null) ...[
                    const SizedBox(height: 24),
                    ResultCard(
                      result: _result!,
                      suggestions: _suggestions,
                      onReset: _resetForm,
                    ),
                  ],
                  const SizedBox(height: 48),
                  _buildFooter(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO(rename): Update hero headline when rebranding
        Text(
          'Have you been pwned?',
          style: theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        // TODO(rename): Update subtitle when rebranding
        Text(
          'Check if your password or email address has appeared in a known data breach, '
          'using privacy-preserving k-anonymity.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Check type toggle
              CheckTypeSelector(
                selected: _checkType,
                onChanged: (t) => setState(() {
                  _checkType = t;
                  _result = null;
                  _suggestions = [];
                  _inputController.clear();
                  _obscureInput = t == CheckType.password;
                }),
              ),
              const SizedBox(height: 20),
              // Input field
              TextFormField(
                controller: _inputController,
                obscureText:
                    _checkType == CheckType.password && _obscureInput,
                keyboardType: _checkType == CheckType.email
                    ? TextInputType.emailAddress
                    : TextInputType.visiblePassword,
                // TODO(rename): update label text on rebrand
                decoration: InputDecoration(
                  labelText: _checkType == CheckType.password
                      ? 'Password' // TODO(rename)
                      : 'Email address', // TODO(rename)
                  prefixIcon: Icon(
                    _checkType == CheckType.password
                        ? Icons.lock_outline
                        : Icons.email_outlined,
                  ),
                  suffixIcon: _checkType == CheckType.password
                      ? IconButton(
                          icon: Icon(
                            _obscureInput
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscureInput ? 'Show password' : 'Hide password', // TODO(rename)
                          onPressed: () =>
                              setState(() => _obscureInput = !_obscureInput),
                        )
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return _checkType == CheckType.password
                        ? 'Please enter a password.' // TODO(rename)
                        : 'Please enter an email address.'; // TODO(rename)
                  }
                  if (_checkType == CheckType.email &&
                      !value.contains('@')) {
                    return 'Please enter a valid email address.'; // TODO(rename)
                  }
                  return null;
                },
              ),
              // Optional API key field for email checks
              if (_checkType == CheckType.email) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    // TODO(rename): update label on rebrand
                    labelText: 'HIBP API Key (required for email checks)',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                    helperText:
                        'Get a free key at haveibeenpwned.com/API/Key',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Submit button
              FilledButton.icon(
                onPressed: _isLoading ? null : _performCheck,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  // TODO(rename): update button label on rebrand
                  _isLoading ? 'Checking…' : 'Check now',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Text(
      // TODO(rename): update footer attribution on rebrand
      'Powered by Have I Been Pwned. '
      'Your password is hashed locally — only the first 5 characters of the hash are sent.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }
}
