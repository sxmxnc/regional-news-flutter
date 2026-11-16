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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _requestFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _confirmFormKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordRepeatController =
      TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _codeSent = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordRepeatController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest(Translations texts, AppLanguage language) async {
    if (!(_requestFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(accountControllerProvider(language))
          .registerRequest(
            username: _usernameController.text.trim(),
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      setState(() => _codeSent = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = texts[_requestErrorKey(error)]);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _requestErrorKey(Object error) {
    final Set<String> fields = failureFields(error);
    final bool username = fields.contains('username');
    final bool email = fields.contains('email');
    if (username && email) return 'account_username_and_email_taken';
    if (username) return 'account_username_taken';
    if (email) return 'account_email_taken';
    return failureMessageKey(error);
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
          .registerConfirm(
            email: _emailController.text.trim(),
            confirmationCode: _codeController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts['account_register_confirmed'])),
      );
      Navigator.of(context).pop(_emailController.text.trim());
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
          texts[_codeSent
              ? 'account_register_confirm_title'
              : 'account_register_title'],
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
    return Form(
      key: _requestFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AccountErrorText(_errorMessage),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: texts['account_register_username_label'],
            ),
            validator: (String? value) =>
                AccountValidators.required(texts, value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: texts['account_register_first_name_label'],
            ),
            validator: (String? value) =>
                AccountValidators.required(texts, value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: texts['account_register_last_name_label'],
            ),
            validator: (String? value) =>
                AccountValidators.required(texts, value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const <String>[AutofillHints.email],
            decoration: InputDecoration(
              labelText: texts['account_email_label'],
            ),
            validator: (String? value) => AccountValidators.email(texts, value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: texts['account_password_label'],
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
            label: texts['account_register_submit'],
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
          Text(texts['account_register_request_success']),
          const SizedBox(height: 16),
          AccountErrorText(_errorMessage),
          AccountConfirmationCodeField(controller: _codeController),
          const SizedBox(height: 16),
          AccountSubmitButton(
            label: texts['account_register_confirm_submit'],
            isLoading: _isSubmitting,
            onPressed: () => _submitConfirm(texts, language),
          ),
        ],
      ),
    );
  }
}
