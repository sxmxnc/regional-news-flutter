import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;

import 'app_language.dart';
import 'constants.dart';
import 'failure.dart';

abstract base class QueryKey {
  const QueryKey(this.language);

  /// Die Sprache, in der die Abfrage läuft. Teil der Gleichheit.
  final AppLanguage language;

  /// Die übrigen unterscheidenden Bestandteile, ohne die Sprache.
  /// Unterklassen geben hier ihre Felder in fester Reihenfolge zurück.
  List<Object?> get parts;

  Duration get freshFor => CachePolicy.list;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    final QueryKey typed = other as QueryKey;
    if (typed.language != language) return false;
    final List<Object?> a = parts;
    final List<Object?> b = typed.parts;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([runtimeType, language, ...parts]);

  @override
  String toString() => '$runtimeType(${language.code}, ${parts.join(', ')})';
}

Duration? nwbRetry(int retryCount, Object error) {
  if (error is! ConnectionFailure) return null;
  if (retryCount >= 3) return null;
  return Duration(seconds: 2 << retryCount);
}

extension QueryCache on Ref {
  void cacheFor(Duration duration) {
    final KeepAliveLink link = keepAlive();
    final Timer timer = Timer(duration, link.close);
    onDispose(timer.cancel);
  }
}

final NotifierProvider<LastSyncController, DateTime?> lastSyncProvider =
    NotifierProvider<LastSyncController, DateTime?>(LastSyncController.new);

final class LastSyncController extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void markNow() => state = DateTime.now();
}

/// Wird nach jedem erfolgreichen Abruf aufgerufen — steht hier und nicht in
/// jedem Repository, weil nur die Abfrageebene weiß, dass die Antwort wirklich
/// neu vom Server kam (nicht aus dem Zwischenspeicher).
extension QuerySync on Ref {
  void markSynced() => read(lastSyncProvider.notifier).markNow();
}

final class RefreshRequests {
  final Set<QueryKey> _pending = <QueryKey>{};

  /// Der nächste Abruf zu [key] soll den Zwischenspeicher umgehen.
  void request(QueryKey key) => _pending.add(key);

  /// Verbraucht die Anforderung: Beim zweiten Aufruf ist sie weg, damit nicht
  /// jeder spätere Abruf am Zwischenspeicher vorbeiläuft.
  bool consume(QueryKey key) => _pending.remove(key);
}

final Provider<RefreshRequests> refreshRequestsProvider =
    Provider<RefreshRequests>((Ref ref) => RefreshRequests());

/// Für die Abfrageebene: Läuft dieser Abruf am Zwischenspeicher vorbei?
extension QueryRefresh on Ref {
  bool consumeRefresh(QueryKey key) =>
      read(refreshRequestsProvider).consume(key);
}

/// Für die Ansichten: Der Wischgriff meldet **vor** dem Verwerfen an, dass der
/// nächste Abruf frisch sein soll. Erst danach `ref.invalidate(...)`, sonst
/// läuft der neue Abruf los, bevor die Anforderung steht.
extension WidgetQueryRefresh on WidgetRef {
  void requestNetworkRefresh(Iterable<QueryKey> keys) {
    final RefreshRequests requests = read(refreshRequestsProvider);
    for (final QueryKey key in keys) {
      requests.request(key);
    }
  }
}
