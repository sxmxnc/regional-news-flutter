import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/app_language.dart';
import '../core/constants.dart';
import '../core/failure.dart';
import 'http_client.dart';

final class WpClient {
  WpClient({required this.httpClient, required this.language});

  /// Namensraum der WordPress-Standardschnittstelle.
  static const String namespace = 'wp/v2';

  final http.Client httpClient;

  final AppLanguage language;

  String get baseUrl => AppConfig.namespaceUrl(language, namespace);

  Future<WpListPage> getList(
    String resource, {
    Map<String, String> query = const <String, String>{},
    bool refresh = false,
  }) async {
    final http.Response response = await _get(resource, query, refresh);
    final Object? decoded = _decode(response);
    if (decoded is! List) {
      throw ServerFailure(
        statusCode: response.statusCode,
        cause: 'Liste erwartet, ${decoded.runtimeType} erhalten',
      );
    }
    return WpListPage(
      items: decoded.whereType<Map<String, Object?>>().toList(growable: false),
      total: _intHeader(response, 'x-wp-total'),
      totalPages: _intHeader(response, 'x-wp-totalpages'),
    );
  }

  Future<Map<String, Object?>> getObject(
    String resource, {
    Map<String, String> query = const <String, String>{},
    bool refresh = false,
  }) async {
    final http.Response response = await _get(resource, query, refresh);
    final Object? decoded = _decode(response);
    if (decoded is! Map<String, Object?>) {
      throw ServerFailure(
        statusCode: response.statusCode,
        cause: 'Objekt erwartet, ${decoded.runtimeType} erhalten',
      );
    }
    return decoded;
  }

  Future<http.Response> _get(
    String resource,
    Map<String, String> query,
    bool refresh,
  ) {
    final Map<String, String> parameters = <String, String>{
      ...query,
      if (refresh) '_nocache': DateTime.now().microsecondsSinceEpoch.toString(),
    };
    final Uri uri = Uri.parse('$baseUrl/$resource')
        .replace(queryParameters: parameters.isEmpty ? null : parameters);

    return mapTransportErrors(() async {
      final http.Response response = await httpClient
          .get(
            uri,
            headers: <String, String>{
              'Accept': 'application/json',
              if (refresh) 'Cache-Control': 'no-cache',
            },
          )
          .timeout(Timeouts.request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ServerFailure(statusCode: response.statusCode, cause: uri.path);
      }
      return response;
    });
  }

  Object? _decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error) {
      // Ungültiges JSON ist ein Serverfehler, kein Inhaltsfehler:
      // die Antwort ist als Ganzes unbrauchbar.
      throw ServerFailure(statusCode: response.statusCode, cause: error);
    }
  }

  static int? _intHeader(http.Response response, String name) =>
      int.tryParse(response.headers[name] ?? '');
}

/// Eine Seite einer Liste samt den Zählern aus den Antwort-Headern.
/// `x-wp-total` belegt den Bestand je Sprachbaum und ist damit der schnellste
/// Nachweis, dass die Sprachableitung wirkt.
final class WpListPage {
  const WpListPage({required this.items, this.total, this.totalPages});

  final List<Map<String, Object?>> items;
  final int? total;
  final int? totalPages;
}

final ProviderFamily<WpClient, AppLanguage> wpClientProvider =
    Provider.family<WpClient, AppLanguage>((Ref ref, AppLanguage language) {
      return WpClient(
        httpClient: ref.watch(httpClientProvider),
        language: language,
      );
    });
