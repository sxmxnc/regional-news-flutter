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

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({
    required this.firstName,
    required this.lastName,
    super.key,
  });

  final String firstName;
  final String lastName;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController = TextEditingController(
    text: widget.firstName,
  );
  late final TextEditingController _lastNameController = TextEditingController(
    text: widget.lastName,
  );
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
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
          .editProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texts['account_edit_success'])));
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
    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(title: Text(texts['account_edit_title'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AccountErrorText(_errorMessage),
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
              const SizedBox(height: 16),
              AccountSubmitButton(
                label: texts['account_edit_submit'],
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
