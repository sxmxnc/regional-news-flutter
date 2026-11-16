import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;

import '../../api/file_client.dart';
import 'epaper_store.dart';

/// Wo eine Ausgabe auf dem Gerät steht.
sealed class EpaperDownloadState {
  const EpaperDownloadState();
}

/// Nicht (vollständig) geladen — ein liegengebliebenes Teilstück wird beim
/// nächsten Start fortgesetzt (`FileClient`).
final class EpaperNotDownloaded extends EpaperDownloadState {
  const EpaperNotDownloaded();
}

final class EpaperDownloading extends EpaperDownloadState {
  const EpaperDownloading({required this.received, required this.total});

  final int received;

  /// `null`, wenn der Server keine Länge nennt.
  final int? total;

  /// 0 … 1, oder `null` ohne bekannte Gesamtlänge (unbestimmter Balken).
  double? get fraction =>
      total == null || total == 0 ? null : (received / total!).clamp(0, 1);
}

/// Vollständig auf dem Gerät — lesbar auch ohne Netz.
final class EpaperDownloaded extends EpaperDownloadState {
  const EpaperDownloaded(this.file);

  final File file;
}

final class EpaperDownloadFailed extends EpaperDownloadState {
  const EpaperDownloadFailed(this.error);

  /// Nur zum Übersetzen in einen Text (`failureMessageKey`).
  final Object error;
}

/// Kennung einer Ausgabe für den Download-Zustand: Jahrgang und Adresse.
/// **Ohne Sprache** — das ist kein Abfrageschlüssel, sondern eine Datei, und
/// die ist in beiden Sprachen dieselbe.
typedef EpaperDownloadKey = ({int yearId, Uri href});

/// Ein Zustand je Ausgabe, über die Fläche hinaus erhalten (kein
/// `autoDispose`): Ein laufender Abruf von 15 MB soll nicht enden, weil die
/// Nutzerin kurz zurückblättert.
final NotifierProviderFamily<
  EpaperDownloadController,
  EpaperDownloadState,
  EpaperDownloadKey
>
epaperDownloadProvider =
    NotifierProvider.family<
      EpaperDownloadController,
      EpaperDownloadState,
      EpaperDownloadKey
    >(EpaperDownloadController.new);

final class EpaperDownloadController extends Notifier<EpaperDownloadState> {
  EpaperDownloadController(this.key);

  final EpaperDownloadKey key;

  /// Gesetzt, solange ein Abruf läuft — vom ersten Antippen bis zum Ende,
  /// einschließlich der Wartezeit auf das Verzeichnis.
  Completer<void>? _cancel;

  /// Der laufende Abruf, damit [delete] ihn abwarten kann.
  Future<void>? _running;

  @override
  EpaperDownloadState build() {
    final AsyncValue<Directory> directory = ref.watch(epaperDirectoryProvider);
    // Wird das Verzeichnis erst während eines Abrufs bekannt, läuft dieser
    // Aufbau erneut — der Fortschritt darf dabei nicht hinter „nicht
    // geladen" verschwinden.
    if (stateOrNull case final EpaperDownloading running when _cancel != null) {
      return running;
    }
    final Directory? root = directory.value;
    if (root == null) return const EpaperNotDownloaded();
    final File file = EpaperStore.fileFor(
      root,
      yearId: key.yearId,
      href: key.href,
    );
    return file.existsSync()
        ? EpaperDownloaded(file)
        : const EpaperNotDownloaded();
  }

  Future<void> download() {
    if (_cancel != null) return _running ?? Future<void>.value();
    final Completer<void> cancel = Completer<void>();
    _cancel = cancel;
    return _running = _download(cancel);
  }

  Future<void> _download(Completer<void> cancel) async {
    state = const EpaperDownloading(received: 0, total: null);
    // Nach jeder Wartestelle: Nur die jüngste Runde dieses Anbieters darf
    // schreiben, und nur solange er lebt (`ref.mounted`).
    bool current() => ref.mounted && _cancel == cancel;
    try {
      final Directory root = await ref.read(epaperDirectoryProvider.future);
      if (!current()) return;
      final File target = EpaperStore.fileFor(
        root,
        yearId: key.yearId,
        href: key.href,
      );
      final File file = await ref
          .read(fileClientProvider)
          .download(
            key.href,
            target,
            cancel: cancel.future,
            onProgress: (int received, int? total) {
              if (!current()) return;
              state = EpaperDownloading(received: received, total: total);
            },
          );
      if (current()) state = EpaperDownloaded(file);
    } on DownloadCancelled {
      if (current()) state = const EpaperNotDownloaded();
    } catch (error) {
      if (current()) state = EpaperDownloadFailed(error);
    } finally {
      if (_cancel == cancel) {
        _cancel = null;
        _running = null;
      }
    }
  }

  /// Bricht ab; das Teilstück bleibt für ein späteres Fortsetzen liegen.
  void cancel() {
    final Completer<void>? cancel = _cancel;
    if (cancel != null && !cancel.isCompleted) cancel.complete();
  }

  Future<void> delete() async {
    cancel();
    await _running;
    final Directory root = await ref.read(epaperDirectoryProvider.future);
    final File file = EpaperStore.fileFor(
      root,
      yearId: key.yearId,
      href: key.href,
    );
    final File partial = File('${file.path}${FileClient.partialSuffix}');
    try {
      if (await file.exists()) await file.delete();
      if (await partial.exists()) await partial.delete();
    } on FileSystemException catch (error) {
      developer.log(
        'Ausgabe nicht gelöscht: $error',
        name: 'EpaperDownloadController',
      );
    }
    if (!ref.mounted) return;
    state = file.existsSync()
        ? EpaperDownloaded(file)
        : const EpaperNotDownloaded();
  }
}
