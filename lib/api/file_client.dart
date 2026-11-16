import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/constants.dart';
import '../core/failure.dart';
import '../state/session.dart';
import 'http_client.dart';
import 'wb_client.dart';

final class FileClient {
  const FileClient({
    required this.httpClient,
    required this.token,
    this.idleTimeout = Timeouts.download,
  });

  final http.Client httpClient;

  final Duration idleTimeout;

  /// Das Token der laufenden Nutzersitzung — geht **nur** an den eigenen
  /// Rechner (siehe [download]).
  final String? token;

  /// Endung der unvollständigen Datei. Erst nach vollständigem Empfang wird
  /// sie auf den Zielnamen umbenannt — eine Datei am Zielpfad ist damit immer
  /// vollständig.
  static const String partialSuffix = '.part';

  Future<File> download(
    Uri rawSource,
    File target, {
    void Function(int received, int? total)? onProgress,
    Future<void>? cancel,
  }) async {
    final Uri source = _https(rawSource);
    if (!_isOwnHost(source) && !_isArchiveHost(source)) {
      throw ContentFailure(cause: 'E-Paper-Adresse auf fremdem Rechner');
    }
    final File partial = File('${target.path}$partialSuffix');
    await partial.parent.create(recursive: true);
    int received = partial.existsSync() ? partial.lengthSync() : 0;

    final http.Request request = http.Request('GET', source)
      // Siehe Dokumentation oben: Der Header darf die eigene Domain nicht
      // verlassen, und eine umgeleitete Adresse liefert keine Ausgabe.
      ..followRedirects = false;
    // Nur an den eigenen Rechner — siehe Dokumentation oben.
    if (token case final String value when _isOwnHost(source)) {
      request.headers[WbClient.authorizationHeader] = value;
    }
    if (received > 0) request.headers['Range'] = 'bytes=$received-';

    return mapTransportErrors(() async {
      final http.StreamedResponse response = await httpClient
          .send(request)
          .timeout(Timeouts.request);

      if (response.statusCode >= 300 && response.statusCode < 400) {
        await response.stream.drain<void>();
        throw ContentFailure(
          cause: 'E-Paper-Adresse leitet um (${response.statusCode})',
        );
      }
      if (!_isPdf(response)) {
        await response.stream.drain<void>();
        throw ContentFailure(cause: 'E-Paper-Adresse liefert kein PDF');
      }

      final bool resuming = received > 0 && response.statusCode == 206;
      if (response.statusCode == 200) {
        // Kein Bereich — von vorn, ein altes Teilstück ist wertlos.
        received = 0;
      } else if (received > 0 && response.statusCode == 416) {
        await response.stream.drain<void>();
        await partial.delete();
        return download(source, target, onProgress: onProgress, cancel: cancel);
      } else if (!resuming) {
        throw ServerFailure(
          statusCode: response.statusCode,
          cause: source.path,
        );
      }

      final int? total = _totalLength(response, received);
      final IOSink sink = partial.openWrite(
        mode: resuming ? FileMode.append : FileMode.write,
      );
      bool cancelled = false;
      final Completer<void> done = Completer<void>();
      final StreamSubscription<List<int>> subscription = response.stream.listen(
        null,
        cancelOnError: true,
      );
      Timer? idle;
      void armIdle() {
        idle?.cancel();
        idle = Timer(idleTimeout, () {
          if (!done.isCompleted) {
            done.completeError(
              TimeoutException('Keine Daten empfangen', idleTimeout),
            );
          }
        });
      }

      subscription
        ..onData((List<int> chunk) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
          armIdle();
        })
        ..onError((Object error, StackTrace stack) {
          if (!done.isCompleted) done.completeError(error, stack);
        })
        ..onDone(() {
          if (!done.isCompleted) done.complete();
        });
      armIdle();
      unawaited(
        cancel?.then((_) {
          cancelled = true;
          if (!done.isCompleted) done.complete();
        }),
      );

      try {
        await done.future;
      } finally {
        idle?.cancel();
        await subscription.cancel();
        await sink.close();
      }

      if (cancelled) throw const DownloadCancelled();
      if (total != null && received < total) {
        throw ConnectionFailure(cause: 'Abbruch nach $received von $total');
      }
      await partial.rename(target.path);
      return target;
    });
  }

  Future<bool> isAvailable(Uri rawSource, {Duration? timeout}) async {
    final Uri source = _https(rawSource);
    if (!_isOwnHost(source) && !_isArchiveHost(source)) return false;
    final http.Request request = http.Request('GET', source)
      ..followRedirects = false;
    if (token case final String value when _isOwnHost(source)) {
      request.headers[WbClient.authorizationHeader] = value;
    }
    request.headers['Range'] = 'bytes=0-0';
    try {
      final http.StreamedResponse response = await httpClient
          .send(request)
          .timeout(timeout ?? Timeouts.availability);
      await response.stream.drain<void>();
      if (response.statusCode >= 300 && response.statusCode < 400) return false;
      if (response.statusCode >= 400) return false;
      return _isPdf(response);
    } on Object {
      return true;
    }
  }

  /// Nur `application/pdf` zählt. Fehlt der Kopf ganz, wird die Antwort
  /// durchgelassen — ein fehlender Inhaltstyp ist kein Beleg für HTML, und
  /// der Abruf scheitert sonst an einem schweigsamen Server.
  static bool _isPdf(http.StreamedResponse response) {
    final String? type = response.headers['content-type'];
    if (type == null) return true;
    return type.toLowerCase().contains('application/pdf');
  }

  static bool _isOwnHost(Uri source) =>
      source.host.isNotEmpty && source.host == Uri.parse(AppConfig.host).host;

  static bool _isArchiveHost(Uri source) =>
      source.host == AppConfig.epaperArchiveHost;

  /// `http` → `https`, aber **nur für den Archiv-Rechner**. Der eigene
  /// Rechner bleibt unangetastet: `AppConfig.overrideHost` darf auf eine
  /// Testinstanz im lokalen Netz zeigen, und die spricht oft nur `http`.
  static Uri _https(Uri source) =>
      source.scheme == 'http' && source.host == AppConfig.epaperArchiveHost
      ? source.replace(scheme: 'https')
      : source;

  /// Gesamtlänge aus `Content-Range` (beim Fortsetzen) oder `Content-Length`.
  static int? _totalLength(http.StreamedResponse response, int offset) {
    final String? range = response.headers['content-range'];
    if (range != null) {
      final int slash = range.lastIndexOf('/');
      final int? total = slash < 0
          ? null
          : int.tryParse(range.substring(slash + 1));
      if (total != null) return total;
    }
    final int? length = response.contentLength;
    return length == null ? null : length + offset;
  }
}

/// Der Nutzer hat abgebrochen — kein Fehler, deshalb keine [Failure]:
/// Es gibt nichts zu melden und nichts zu wiederholen.
final class DownloadCancelled implements Exception {
  const DownloadCancelled();
}

/// Ein Client mit dem Token der laufenden Sitzung. Nicht sprachgebunden:
/// Die Datei ist in beiden Sprachen dieselbe.
final Provider<FileClient> fileClientProvider = Provider<FileClient>((Ref ref) {
  final SessionState session = ref.watch(sessionProvider);
  return FileClient(
    httpClient: ref.watch(httpClientProvider),
    token: session.token,
  );
});
