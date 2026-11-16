import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../core/failure.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../ui/nav/area_navigation_bar.dart';
import 'account_controller.dart';
import 'account_validators.dart';
import 'account_widgets.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({this.knownEmail, this.prefillEmail, super.key})
    : assert(
        knownEmail == null || prefillEmail == null,
        'knownEmail und prefillEmail schließen sich aus',
      );

  final String? knownEmail;
  final String? prefillEmail;

  bool get isChangingPassword => knownEmail != null;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final GlobalKey<FormState> _requestFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _confirmFormKey = GlobalKey<FormState>();

  late final TextEditingController _emailController = TextEditingController(
    text: widget.knownEmail ?? widget.prefillEmail ?? '',
  );
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordRepeatController =
      TextEditingController();

  bool _codeSent = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _passwordRepeatController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest(Translations texts, AppLanguage language) async {
    if (!widget.isChangingPassword &&
        !(_requestFormKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(accountControllerProvider(language))
          .resetPasswordRequest(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() => _codeSent = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = texts[failureMessageKey(error)]);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitConfirm(Translations texts, AppLanguage language) async {
    if (!(_confirmFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(accountControllerProvider(language))
          .resetPasswordConfirm(
            email: _emailController.text.trim(),
            confirmationCode: _codeController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      // Beim „Passwort vergessen?"-Weg ist die Sitzung nicht angemeldet —
      // die Nutzerin muss sich mit dem neuen Passwort anmelden. Beim
      // „Passwort ändern" aus den Einstellungen bleibt sie angemeldet.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            texts[widget.isChangingPassword
                ? 'account_change_password_success'
                : 'account_reset_success'],
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            texts[failureMessageKeyForField(
              error,
              'confirmation_code',
              'account_confirmation_code_invalid',
            )],
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Translations texts = ref.watch(translationsProvider);
    final AppLanguage language = ref.watch(languageProvider);

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(
        title: Text(
          texts[widget.isChangingPassword
              ? 'account_overview_change_password_action'
              : (_codeSent
                    ? 'account_reset_confirm_title'
                    : 'account_reset_title')],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _codeSent
            ? _buildConfirmStep(texts, language)
            : _buildRequestStep(texts, language),
      ),
    );
  }

  Widget _buildRequestStep(Translations texts, AppLanguage language) {
    if (widget.isChangingPassword) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AccountErrorText(_errorMessage),
          Text(
            texts.format('account_change_password_intro', <String, Object?>{
              'email': widget.knownEmail,
            }),
          ),
          const SizedBox(height: 16),
          AccountSubmitButton(
            label: texts['account_reset_request_submit'],
            isLoading: _isSubmitting,
            onPressed: () => _submitRequest(texts, language),
          ),
        ],
      );
    }
    return Form(
      key: _requestFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AccountErrorText(_errorMessage),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const <String>[AutofillHints.email],
            decoration: InputDecoration(
              labelText: texts['account_email_label'],
            ),
            validator: (String? value) => AccountValidators.email(texts, value),
          ),
          const SizedBox(height: 16),
          AccountSubmitButton(
            label: texts['account_reset_request_submit'],
            isLoading: _isSubmitting,
            onPressed: () => _submitRequest(texts, language),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep(Translations texts, AppLanguage language) {
    return Form(
      key: _confirmFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(texts['account_reset_request_success']),
          if (!widget.isChangingPassword) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              texts['account_reset_request_success_hint'],
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          AccountErrorText(_errorMessage),
          AccountConfirmationCodeField(controller: _codeController),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: texts['account_reset_new_password_label'],
            ),
            validator: (String? value) =>
                AccountValidators.password(texts, value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordRepeatController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: texts['account_register_password_repeat_label'],
            ),
            validator: (String? value) => AccountValidators.passwordRepeat(
              texts,
              value,
              _passwordController.text,
            ),
          ),
          const SizedBox(height: 16),
          AccountSubmitButton(
            label: texts['account_reset_confirm_submit'],
            isLoading: _isSubmitting,
            onPressed: () => _submitConfirm(texts, language),
          ),
        ],
      ),
    );
  }
}
