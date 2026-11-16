import '../../core/app_language.dart';

abstract final class LegalPageSlugs {
  static String imprint(AppLanguage language) => switch (language) {
    AppLanguage.de => 'buero',
    AppLanguage.pl => 'biuro',
  };

  /// In beiden Sprachzweigen derselbe Schlüssel — die Seite liegt nur
  /// einmal vor, auf Polnisch (Datenlücke, siehe oben).
  static String privacy(AppLanguage language) => switch (language) {
    AppLanguage.de || AppLanguage.pl => 'polityka-prywatnosci',
  };
}
