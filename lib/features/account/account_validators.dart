import '../../i18n/translations.dart';

/// Feldprüfungen der Kontoformulare — an einer Stelle, damit „Pflichtfeld"
/// und „ungültige E-Mail" überall gleich geprüft werden.
abstract final class AccountValidators {
  static String? required(Translations texts, String? value) {
    if (value == null || value.trim().isEmpty) {
      return texts['account_field_required'];
    }
    return null;
  }

  static String? email(Translations texts, String? value) {
    final String? requiredError = required(texts, value);
    if (requiredError != null) return requiredError;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return texts['account_email_invalid'];
    }
    return null;
  }

  static String? password(Translations texts, String? value) {
    final String? requiredError = required(texts, value);
    if (requiredError != null) return requiredError;
    if (value!.length < 8) {
      return texts['account_password_too_short'];
    }
    return null;
  }

  static String? passwordRepeat(
    Translations texts,
    String? value,
    String original,
  ) {
    final String? requiredError = required(texts, value);
    if (requiredError != null) return requiredError;
    if (value != original) {
      return texts['account_password_mismatch'];
    }
    return null;
  }

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
