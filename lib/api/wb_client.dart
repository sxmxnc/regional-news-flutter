import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/app_language.dart';
import '../core/constants.dart';
import '../core/failure.dart';
import '../features/subscription/payments_switch.dart';
import '../state/session.dart';
import 'http_client.dart';

final class WbClient {
  WbClient({
    required this.httpClient,
    required this.language,
    required this.token,
    this.onUnauthorized,
    this.onPaymentsSwitch,
  });

  /// Namensraum der Zusatzschnittstelle.
  static const String namespace = 'reader/v1';

  static const String authorizationHeader = 'X-Api-Authorization';

  static const String paymentsEnabledHeader = 'x-payments-enabled';

  final http.Client httpClient;
  final AppLanguage language;

  final String? token;

  /// Wird bei HTTP 401 oder 403 aufgerufen — **nur** gesetzt, wenn diese
  /// Anfragen im Namen einer angemeldeten Nutzersitzung laufen
  /// (`wbClientProvider`). Beendet die Sitzung an der einen Stelle, an der
  /// Regel 5.4 es verlangt: Token verwerfen, Anmeldefläche zeigen — kein
  /// Wiederholungsversuch, keine Anmeldeschleife.
  final void Function()? onUnauthorized;

  final void Function(bool enabled)? onPaymentsSwitch;

  String get baseUrl => AppConfig.namespaceUrl(language, namespace);

  static const String _cacheBusterParam = 'cb';

  Future<WbResponse> get(
    String route, {
    Map<String, String> query = const <String, String>{},
  }) {
    final Map<String, String> withCacheBuster = <String, String>{
      ...query,
      _cacheBusterParam: DateTime.now().microsecondsSinceEpoch.toString(),
    };
    final Uri uri = Uri.parse('$baseUrl/$route')
        .replace(queryParameters: withCacheBuster);
    return _send(() => httpClient.get(uri, headers: _headers()), uri);
  }

  Future<WbResponse> post(
    String route, {
    Map<String, Object?> body = const <String, Object?>{},
  }) {
    final Uri uri = Uri.parse('$baseUrl/$route');
    return _send(
      () => httpClient.post(
        uri,
        headers: <String, String>{
          ..._headers(),
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(body),
      ),
      uri,
    );
  }

  Map<String, String> _headers() => <String, String>{
    'Accept': 'application/json',
    if (token case final String value) authorizationHeader: value,
  };

  Future<WbResponse> _send(Future<http.Response> Function() request, Uri uri) {
    return mapTransportErrors(() async {
      final http.Response response = await request().timeout(Timeouts.request);
      final Object? body = _decodeOrNull(response);
      final String? paymentsHeader = response.headers[paymentsEnabledHeader];
      if (paymentsHeader != null) onPaymentsSwitch?.call(paymentsHeader == '1');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final ServerFailure failure = ServerFailure(
          statusCode: response.statusCode,
          cause: uri.path,
          fields: _errorFields(body),
        );
        if (failure.isUnauthorized) onUnauthorized?.call();
        throw failure;
      }
      return WbResponse(body: body, paymentsEnabled: paymentsHeader == '1');
    });
  }

  Object? _decodeOrNull(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      // Manche Routen antworten mit leerem Text statt mit JSON. Das ist kein
      // Fehler, solange der Statuscode stimmt.
      return null;
    }
  }

  Set<String>? _errorFields(Object? body) {
    final Object? fields = switch (body) {
      final Map<String, Object?> map => switch (map['error']) {
        final Map<String, Object?> error => error['fields'],
        _ => null,
      },
      _ => null,
    };
    return switch (fields) {
      final Map<String, Object?> map => map.keys.toSet(),
      _ => null,
    };
  }
}

/// Antwort samt dem Server-Schalter für den Kaufweg.
final class WbResponse {
  const WbResponse({required this.body, required this.paymentsEnabled});

  final Object? body;
  final bool paymentsEnabled;

  Map<String, Object?> get asMap => switch (body) {
    final Map<String, Object?> map => map,
    _ => throw ServerFailure(cause: 'Objekt erwartet, ${body.runtimeType}'),
  };
}

/// Ein Client **je Sprache**, mit dem Token der laufenden Sitzung.
final ProviderFamily<WbClient, AppLanguage> wbClientProvider =
    Provider.family<WbClient, AppLanguage>((Ref ref, AppLanguage language) {
      final SessionState session = ref.watch(sessionProvider);
      return WbClient(
        httpClient: ref.watch(httpClientProvider),
        language: language,
        token: session.token,
        onUnauthorized: session.isAuthenticated
            ? () => ref.read(sessionProvider.notifier).end()
            : null,
        onPaymentsSwitch: (bool enabled) =>
            ref.read(paymentsEnabledProvider.notifier).set(enabled),
      );
    });
