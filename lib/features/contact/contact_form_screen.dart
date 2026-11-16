import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../core/failure.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../ui/nav/area_navigation_bar.dart';
import '../account/account_profile_prefill.dart';
import '../account/account_validators.dart';
import '../account/account_widgets.dart';
import '../account/user_profile.dart';
import 'contact_repository.dart';
import 'device_context.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  const ContactFormScreen({
    required this.titleKey,
    required this.kindKey,
    this.introKey,
    this.initialMessage,
    this.includeDeviceContext = false,
    super.key,
  });

  final String titleKey;

  final String kindKey;

  /// Kurzer Hinweistext über dem Nachrichtenfeld — `null` für ein schlichtes
  /// Formular ohne zusätzliche Erklärung.
  final String? introKey;

  final String? initialMessage;

  final bool includeDeviceContext;

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen>
    with AccountProfilePrefillState<ContactFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _messageController = TextEditingController(
    text: widget.initialMessage ?? '',
  );
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _optionalEmail(Translations texts, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return AccountValidators.email(texts, value);
  }

  Future<void> _submit(Translations texts, AppLanguage language) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      String message =
          '${texts[widget.kindKey]}\n\n${_messageController.text.trim()}';
      if (widget.includeDeviceContext) {
        final String? deviceContext = await currentDeviceContext();
        if (deviceContext != null) {
          message =
              '$message\n\n${texts['contact_device_context_label']}: '
              '$deviceContext';
        }
      }
      final String email = _emailController.text.trim();
      await ref
          .read(contactRepositoryProvider(language))
          .send(message: message, email: email.isEmpty ? null : email);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texts['contact_form_success'])));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = texts[failureMessageKey(error)]);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Translations texts = ref.watch(translationsProvider);
    final AppLanguage language = ref.watch(languageProvider);

    watchAccountProfilePrefill(language, (UserProfile profile) {
      if (_emailController.text.trim().isEmpty) {
        _emailController.text = profile.email;
      }
    });

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(title: Text(texts[widget.titleKey])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.introKey case final String key) ...<Widget>[
                Text(texts[key]),
                const SizedBox(height: 16),
              ],
              AccountErrorText(_errorMessage),
              TextFormField(
                controller: _messageController,
                minLines: 5,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: texts['contact_form_message_label'],
                  alignLabelWithHint: true,
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
                  labelText: texts['contact_form_email_label'],
                ),
                validator: (String? value) => _optionalEmail(texts, value),
              ),
              const SizedBox(height: 16),
              AccountSubmitButton(
                label: texts['contact_form_submit'],
                isLoading: _isSubmitting,
                onPressed: () => _submit(texts, language),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
