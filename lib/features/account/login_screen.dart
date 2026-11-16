import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../core/failure.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../subscription/print_order_screen.dart';
import 'account_controller.dart';
import 'account_validators.dart';
import 'account_widgets.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(Translations texts, AppLanguage language) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(accountControllerProvider(language))
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is ConnectionFailure
            ? texts['error_connection']
            : texts['account_login_error'];
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openRegistration(BuildContext context) async {
    final String? registeredEmail = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const RegisterScreen()),
    );
    if (!mounted || registeredEmail == null || registeredEmail.isEmpty) return;
    // Kein `setState`: Das Feld hängt am Controller und baut sich selbst neu.
    _emailController.text = registeredEmail;
  }

  @override
  Widget build(BuildContext context) {
    final Translations texts = ref.watch(translationsProvider);
    final AppLanguage language = ref.watch(languageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              texts['account_login_title'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            AccountErrorText(_errorMessage),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              decoration: InputDecoration(
                labelText: texts['account_email_label'],
              ),
              validator: (String? value) =>
                  AccountValidators.email(texts, value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              autofillHints: const <String>[AutofillHints.password],
              decoration: InputDecoration(
                labelText: texts['account_password_label'],
              ),
              validator: (String? value) =>
                  AccountValidators.required(texts, value),
            ),
            const SizedBox(height: 16),
            AccountSubmitButton(
              label: texts['account_login_submit'],
              isLoading: _isSubmitting,
              onPressed: () => _submit(texts, language),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    // Übernimmt die bereits eingetippte Adresse, falls
                    // schon eine dasteht — editierbar, kein fester Wert
                    // (anders als `knownEmail`, das ist „Passwort ändern"
                    // aus den Einstellungen vorbehalten).
                    builder: (_) => ResetPasswordScreen(
                      prefillEmail: _emailController.text.trim().isEmpty
                          ? null
                          : _emailController.text.trim(),
                    ),
                  ),
                ),
                child: Text(texts['account_login_reset_action']),
              ),
            ),
            const Divider(height: 32),
            Text(
              texts['account_login_no_account'],
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _openRegistration(context),
              child: Text(texts['account_login_register_action']),
            ),
            const Divider(height: 32),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrintOrderScreen(),
                  ),
                ),
                child: Text(texts['print_order_action']),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
