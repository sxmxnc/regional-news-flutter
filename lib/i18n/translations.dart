import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_language.dart';
import '../state/language.dart';

final class Translations {
  const Translations(this.language, this._values);

  final AppLanguage language;
  final Map<String, String> _values;

  /// Fehlt ein Schlüssel, wird er selbst angezeigt. Das ist im Betrieb sichtbar
  /// und im Test zu fassen — besser als ein leerer Text, der unbemerkt bleibt.
  String operator [](String key) => _values[key] ?? key;

  /// Setzt benannte Platzhalter der Form `{name}` ein.
  ///
  /// In **einem** Durchgang, nicht in einer Schleife über die Werte: Sonst
  /// könnte ein eingesetzter Text, der selbst geschweifte Klammern enthält,
  /// von der nächsten Runde noch einmal ersetzt werden. Ein Platzhalter ohne
  /// Wert bleibt stehen und ist damit sichtbar.
  String format(String key, Map<String, Object?> values) {
    return this[key].replaceAllMapped(_placeholder, (Match match) {
      final String name = match.group(1)!;
      return values.containsKey(name) ? '${values[name]}' : match.group(0)!;
    });
  }

  static final RegExp _placeholder = RegExp(r'\{(\w+)\}');

  bool contains(String key) => _values.containsKey(key);

  /// Lädt **beide** Sprachdateien. Sie sind wenige Kilobyte groß, und danach
  /// ist jeder Text ohne Wartezeit verfügbar: Der Sprachwechsel braucht keinen
  /// Ladezustand, und die Oberfläche kommt ohne einen zweiten asynchronen
  /// Zustand neben der Sprache aus.
  static Future<Map<AppLanguage, Translations>> loadAll({
    AssetBundle? bundle,
  }) async {
    final Map<AppLanguage, Translations> result = <AppLanguage, Translations>{};
    for (final AppLanguage language in AppLanguage.values) {
      result[language] = await _load(language, bundle ?? rootBundle);
    }
    return result;
  }

  static Future<Translations> _load(
    AppLanguage language,
    AssetBundle bundle,
  ) async {
    final String raw = await bundle.loadString(
      'lib/i18n/${language.code}.json',
    );
    final Map<String, Object?> decoded =
        jsonDecode(raw) as Map<String, Object?>;
    return Translations(language, <String, String>{
      for (final MapEntry<String, Object?> entry in decoded.entries)
        entry.key: '${entry.value}',
    });
  }
}

/// Wird beim Start überschrieben (`lib/app.dart`), wie die
/// Schlüssel-Wert-Ablage. Ein Zugriff vor dem Laden soll auffallen.
final Provider<Map<AppLanguage, Translations>> translationBundleProvider =
    Provider<Map<AppLanguage, Translations>>(
      (Ref ref) => throw StateError(
        'translationBundleProvider muss beim Start überschrieben werden '
        '(siehe lib/app.dart).',
      ),
    );

/// Die Texte der **aktiven** Sprache — abgeleitet aus dem einen Sprachzustand,
/// nicht daneben geführt.
final Provider<Translations> translationsProvider = Provider<Translations>((
  Ref ref,
) {
  final AppLanguage language = ref.watch(languageProvider);
  return ref.watch(translationBundleProvider)[language]!;
});
