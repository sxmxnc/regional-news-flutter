enum AppLanguage {
  /// Polnisch ist der Stamm des Portals, ohne Pfadpräfix.
  pl('pl', ''),

  /// Deutsch liegt unter `/de`.
  de('de', '/de');

  const AppLanguage(this.code, this.pathPrefix);

  /// Zweibuchstabiger Code. Teil jedes Abfrageschlüssels (Regel 3) und
  /// Name der Übersetzungsdatei in `lib/i18n/`.
  final String code;

  /// Anteil am Pfad der Basis-URL. Leer für Polnisch.
  final String pathPrefix;

  /// Löst einen gespeicherten Code auf. Unbekanntes ergibt `null`, damit der
  /// Aufrufer zwischen „nichts gespeichert" und „ungültig" nicht unterscheiden
  /// muss — beides führt über [fromDeviceLocale] zur Vorgabe.
  static AppLanguage? tryFromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }

  static AppLanguage fromDeviceLocale(String? languageCode) {
    return switch (languageCode?.toLowerCase()) {
      final String code when code.startsWith('de') => AppLanguage.de,
      final String code when code.startsWith('pl') => AppLanguage.pl,
      _ => AppLanguage.pl,
    };
  }
}
