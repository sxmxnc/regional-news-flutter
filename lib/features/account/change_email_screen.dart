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

class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  final GlobalKey<FormState> _requestFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _confirmFormKey = GlobalKey<FormState>();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  /// Die Adresse, für die ein Code angefordert wurde — an dieser Stelle
  /// eingefroren, damit `confirm` garantiert dieselbe Adresse sendet, auch
  /// wenn das Feld im ersten Schritt technisch noch änderbar bliebe.
  String? _requestedEmail;
  bool _codeSent = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newEmailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest(Translations texts, AppLanguage language) async {
    if (!(_requestFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final String email = _newEmailController.text.trim();
    try {
      await ref
          .read(accountControllerProvider(language))
          .changeEmailRequest(email: email);
      if (!mounted) return;
      setState(() {
        _requestedEmail = email;
        _codeSent = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            texts[failureMessageKeyForField(
              error,
              'email',
              'account_email_taken',
            )],
      );
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
          .changeEmailConfirm(
            email: _requestedEmail!,
            confirmationCode: _codeController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts['account_change_email_success'])),
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
      appBar: AppBar(title: Text(texts['account_change_email_title'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _codeSent
            ? Form(
                key: _confirmFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      texts.format(
                        'account_change_email_request_success',
                        <String, Object?>{'email': _requestedEmail},
                      ),
                    ),
                    const SizedBox(height: 16),
                    AccountErrorText(_errorMessage),
                    AccountConfirmationCodeField(controller: _codeController),
                    const SizedBox(height: 16),
                    AccountSubmitButton(
                      label: texts['account_change_email_confirm_submit'],
                      isLoading: _isSubmitting,
                      onPressed: () => _submitConfirm(texts, language),
                    ),
                  ],
                ),
              )
            : Form(
                key: _requestFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AccountErrorText(_errorMessage),
                    TextFormField(
                      controller: _newEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: texts['account_change_email_new_label'],
                      ),
                      validator: (String? value) =>
                          AccountValidators.email(texts, value),
                    ),
                    const SizedBox(height: 16),
                    AccountSubmitButton(
                      label: texts['account_change_email_request_submit'],
                      isLoading: _isSubmitting,
                      onPressed: () => _submitRequest(texts, language),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
