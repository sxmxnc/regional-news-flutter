import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../core/failure.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../ui/nav/area_navigation_bar.dart';
import 'account_controller.dart';
import 'account_widgets.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final GlobalKey<FormState> _confirmFormKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();

  bool _codeSent = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest(Translations texts, AppLanguage language) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(accountControllerProvider(language)).deleteRequest();
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
          .deleteConfirm(confirmationCode: _codeController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts['account_delete_success'])));
      Navigator.of(context).popUntil((Route<void> route) => route.isFirst);
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
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(title: Text(texts['account_delete_title'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                texts['account_delete_warning'],
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            const SizedBox(height: 16),
            AccountErrorText(_errorMessage),
            if (!_codeSent)
              AccountSubmitButton(
                label: texts['account_delete_request_submit'],
                isLoading: _isSubmitting,
                onPressed: () => _submitRequest(texts, language),
              )
            else
              Form(
                key: _confirmFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(texts['account_delete_request_success']),
                    const SizedBox(height: 16),
                    AccountConfirmationCodeField(controller: _codeController),
                    const SizedBox(height: 16),
                    AccountSubmitButton(
                      label: texts['account_delete_confirm_submit'],
                      isLoading: _isSubmitting,
                      onPressed: () => _submitConfirm(texts, language),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
