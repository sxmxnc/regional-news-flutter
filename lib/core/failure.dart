sealed class Failure implements Exception {
  const Failure(this.messageKey, {this.cause});

  /// Schlüssel in `lib/i18n/*.json`.
  final String messageKey;

  /// Nur zum Protokollieren, nie zur Anzeige.
  final Object? cause;

  @override
  String toString() => '$runtimeType($messageKey, cause: $cause)';
}

/// Kein Netz, Zeitüberschreitung, abgebrochene Verbindung.
/// Verhalten: Offline-Band, vorhandene Inhalte bleiben sichtbar,
/// automatischer neuer Versuch bei Netzrückkehr. Nie ein leerer Bildschirm.
final class ConnectionFailure extends Failure {
  const ConnectionFailure({super.cause}) : super('error_connection');
}

/// 4xx, 5xx oder ungültiges JSON. Verständlicher Satz plus „Erneut versuchen".
final class ServerFailure extends Failure {
  const ServerFailure({this.statusCode, this.fields, super.cause})
    : super('error_server');

  /// Nur zum Protokollieren und für die Sitzungsführung (401/403),
  /// nicht für die Anzeige.
  final int? statusCode;

  final Set<String>? fields;

  bool get isUnauthorized =>
      (statusCode == 401 || statusCode == 403) &&
      (fields == null || fields!.isEmpty);
}

final class ContentFailure extends Failure {
  const ContentFailure({super.cause}) : super('error_content');
}

/// Übersetzungsschlüssel zu einem beliebigen Fehler — dieselbe Regel wie in
/// `lib/ui/error_view.dart`, hier für Formulare, die selbst keine
/// [ErrorView] zeigen (Anmeldung, Registrierung, Kontoabläufe).
String failureMessageKey(Object error) => switch (error) {
  final Failure failure => failure.messageKey,
  _ => 'error_server',
};

Set<String> failureFields(Object error) => switch (error) {
  final ServerFailure failure => failure.fields ?? const <String>{},
  _ => const <String>{},
};

String failureMessageKeyForField(
  Object error,
  String field,
  String specificKey,
) {
  if (failureFields(error).contains(field)) return specificKey;
  return failureMessageKey(error);
}
