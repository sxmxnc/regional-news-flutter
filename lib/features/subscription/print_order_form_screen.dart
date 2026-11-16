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
import '../contact/contact_repository.dart';

class PrintOrderFormScreen extends ConsumerStatefulWidget {
  const PrintOrderFormScreen({super.key});

  @override
  ConsumerState<PrintOrderFormScreen> createState() =>
      _PrintOrderFormScreenState();
}

class _PrintOrderFormScreenState extends ConsumerState<PrintOrderFormScreen>
    with AccountProfilePrefillState<PrintOrderFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _taxNumberController = TextEditingController();
  bool _needsInvoice = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _organizationController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxNumberController.dispose();
    super.dispose();
  }

  String? _requiredTaxNumber(Translations texts, String? value) {
    if (!_needsInvoice) return null;
    return AccountValidators.required(texts, value);
  }

  String _buildOrderMessage(Translations texts) {
    final List<(String, String)> fields = <(String, String)>[
      (texts['print_order_first_name_label'], _firstNameController.text.trim()),
      (texts['print_order_last_name_label'], _lastNameController.text.trim()),
      if (_organizationController.text.trim().isNotEmpty)
        (
          texts['print_order_organization_label'],
          _organizationController.text.trim(),
        ),
      (texts['print_order_street_label'], _streetController.text.trim()),
      (texts['print_order_city_label'], _cityController.text.trim()),
      (texts['print_order_country_label'], _countryController.text.trim()),
      (texts['print_order_phone_label'], _phoneController.text.trim()),
      (texts['print_order_email_label'], _emailController.text.trim()),
      (
        texts['print_order_invoice_checkbox_label'],
        _needsInvoice ? texts['print_order_yes'] : texts['print_order_no'],
      ),
      if (_needsInvoice)
        (
          texts['print_order_tax_number_label'],
          _taxNumberController.text.trim(),
        ),
    ];

    final String body = fields
        .map(((String, String) field) => '${field.$1}: ${field.$2}')
        .join('\n');
    return '${texts['print_order_contact_marker']}\n\n$body';
  }

  Future<void> _submit(Translations texts, AppLanguage language) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(contactRepositoryProvider(language))
          .send(
            message: _buildOrderMessage(texts),
            email: _emailController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texts['print_order_success'])));
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
      if (_firstNameController.text.trim().isEmpty) {
        _firstNameController.text = profile.firstName;
      }
      if (_lastNameController.text.trim().isEmpty) {
        _lastNameController.text = profile.lastName;
      }
      if (_streetController.text.trim().isEmpty) {
        _streetController.text = profile.shipping.street;
      }
      if (_cityController.text.trim().isEmpty) {
        final String cityLine = <String>[
          profile.shipping.postcode,
          profile.shipping.city,
        ].where((String value) => value.isNotEmpty).join(' ');
        _cityController.text = cityLine;
      }
      if (_countryController.text.trim().isEmpty) {
        _countryController.text = profile.shipping.country;
      }
      if (_phoneController.text.trim().isEmpty) {
        _phoneController.text = profile.shipping.phone;
      }
      if (_emailController.text.trim().isEmpty) {
        _emailController.text = profile.email;
      }
    });

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(title: Text(texts['print_order_title'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(texts['print_order_contact_intro']),
              const SizedBox(height: 16),
              AccountErrorText(_errorMessage),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: texts['print_order_first_name_label'],
                ),
                validator: (String? value) =>
                    AccountValidators.required(texts, value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: texts['print_order_last_name_label'],
                ),
                validator: (String? value) =>
                    AccountValidators.required(texts, value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _organizationController,
                decoration: InputDecoration(
                  labelText: texts['print_order_organization_label'],
                  helperText: texts['print_order_optional_hint'],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _streetController,
                decoration: InputDecoration(
                  labelText: texts['print_order_street_label'],
                ),
                validator: (String? value) =>
                    AccountValidators.required(texts, value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: texts['print_order_city_label'],
                ),
                validator: (String? value) =>
                    AccountValidators.required(texts, value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _countryController,
                decoration: InputDecoration(
                  labelText: texts['print_order_country_label'],
                ),
                validator: (String? value) =>
                    AccountValidators.required(texts, value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: texts['print_order_phone_label'],
                  helperText: texts['print_order_optional_hint'],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                decoration: InputDecoration(
                  labelText: texts['print_order_email_label'],
                ),
                validator: (String? value) =>
                    AccountValidators.email(texts, value),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _needsInvoice,
                title: Text(texts['print_order_invoice_checkbox_label']),
                onChanged: (bool? value) =>
                    setState(() => _needsInvoice = value ?? false),
              ),
              if (_needsInvoice) ...<Widget>[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _taxNumberController,
                  decoration: InputDecoration(
                    labelText: texts['print_order_tax_number_label'],
                  ),
                  validator: (String? value) =>
                      _requiredTaxNumber(texts, value),
                ),
              ],
              const SizedBox(height: 16),
              AccountSubmitButton(
                label: texts['print_order_submit'],
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
