import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/constants.dart';
import '../core/failure.dart';
import 'http_client.dart';

final class DriveGalleryClient {
  const DriveGalleryClient({required this.httpClient});

  final http.Client httpClient;

  /// Die Aktion, die das Plugin für beide Modularten kennt.
  static const String _action = 'useyourdrive-get-gallery';

  static const String _type = 'carousel';

  /// Die Bilder eines Galerieblocks, in der Reihenfolge, die [sort] vorgibt
  /// (aus `data-sort` des Blocks, im Bestand durchweg `name:asc`).
  ///
  /// Gibt die rohe Liste zurück; das Übersetzen in Modelle macht
  /// `DriveGalleryMapper`.
  Future<List<Map<String, Object?>>> getImages({
    required String accountId,
    required String listToken,
    required String sort,
  }) {
    final Uri uri = Uri.parse(AppConfig.pluginAjaxUrl);

    return mapTransportErrors(() async {
      final http.Response response = await httpClient
          .post(
            uri,
            headers: const <String, String>{'Accept': 'application/json'},
            body: <String, String>{
              'action': _action,
              'type': _type,
              'sort': sort,
              'account_id': accountId,
              'listtoken': listToken,
            },
          )
          .timeout(Timeouts.request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ServerFailure(statusCode: response.statusCode, cause: uri.path);
      }
      return _images(response);
    });
  }

  List<Map<String, Object?>> _images(http.Response response) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error) {
      throw ServerFailure(statusCode: response.statusCode, cause: error);
    }
    if (decoded is! Map<String, Object?>) return const <Map<String, Object?>>[];
    final Object? images = decoded['images'];
    if (images is! List) return const <Map<String, Object?>>[];
    return images.whereType<Map<String, Object?>>().toList(growable: false);
  }
}

final Provider<DriveGalleryClient> driveGalleryClientProvider =
    Provider<DriveGalleryClient>((Ref ref) {
      return DriveGalleryClient(httpClient: ref.watch(httpClientProvider));
    });
