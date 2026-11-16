import '../core/app_language.dart';

abstract final class AppConfig {
  static const bool usesDemoData = !bool.hasEnvironment('NEWS_API_HOST');
  static const String _defaultHost = String.fromEnvironment(
    'NEWS_API_HOST',
    defaultValue: 'https://news.example.invalid',
  );

  static String _host = _defaultHost;

  /// Adresse des Portals, ohne Schrägstrich am Ende.
  static String get host => _host;

  /// Setzt die Adresse zur Laufzeit, etwa für eine Testinstanz.
  /// Ein Schrägstrich am Ende wird entfernt, damit die Ableitung der
  /// Basis-URL nie einen doppelten enthält.
  static void overrideHost(String host) {
    _host = host.endsWith('/') ? host.substring(0, host.length - 1) : host;
  }

  /// Stellt den zur Bauzeit gesetzten Wert wieder her.
  static void resetHost() {
    _host = _defaultHost;
  }

  static String baseUrl(AppLanguage language) =>
      '$_host${language.pathPrefix}/wp-json';

  /// Basis-URL eines Namensraums, etwa `wp/v2` oder `reader/v1`.
  /// Welcher Namensraum wofür zuständig ist, entscheidet Regel 2 — und zwar
  /// in den Clients, nicht hier.
  static String namespaceUrl(AppLanguage language, String namespace) =>
      '${baseUrl(language)}/$namespace';

  static String get pluginAjaxUrl => '$_host/wp-admin/admin-ajax.php';

  static const String epaperArchiveHost = 'archive.example.invalid';

  static const String p24SdkVersion = '1.1.3';

  static const String _p24ProductionHost = 'https://payments.example.invalid';
  static const String _p24SandboxHost =
      'https://sandbox-payments.example.invalid';

  static Uri paymentUrl({required String token, required bool isSandbox}) {
    final String host = isSandbox ? _p24SandboxHost : _p24ProductionHost;
    return Uri.parse('$host/trnRequest/$token');
  }
}
