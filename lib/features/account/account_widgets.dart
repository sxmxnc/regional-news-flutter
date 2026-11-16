import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, TextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/translations.dart';
import 'account_validators.dart';

/// Gemeinsame Bausteine der Kontoflächen (Anmeldung, Registrierung,
/// Passwortrücksetzung, Profil, E-Mail-Änderung, Löschung) — **eine**
/// Absendeschaltfläche mit Ladezustand, **eine** Fehlerzeile, **ein**
/// Codefeld, statt sie in sechs Bildschirmen zu wiederholen.
class AccountSubmitButton extends StatelessWidget {
  const AccountSubmitButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

class AccountConfirmationCodeField extends ConsumerWidget {
  const AccountConfirmationCodeField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      maxLength: 6,
      decoration: InputDecoration(
        labelText: texts['account_confirmation_code_label'],
      ),
      validator: (String? value) => AccountValidators.required(texts, value),
    );
  }
}

class AccountErrorText extends StatelessWidget {
  const AccountErrorText(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final String? text = message;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
