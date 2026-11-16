import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import 'dart:async';
import 'dart:io';

import '../../api/file_client.dart';
import '../../core/failure.dart';
import '../../core/query.dart';
import '../../state/session.dart';
import 'epaper_catalog.dart';
import 'epaper_issue.dart';
import 'epaper_repository.dart';
import 'epaper_store.dart';
import 'epaper_year.dart';

final class EpaperYearsKey extends QueryKey {
  const EpaperYearsKey(super.language);

  @override
  List<Object?> get parts => const <Object?>[];
}

/// Abfrageschlüssel für die Ausgaben eines Jahrgangs.
final class EpaperIssuesKey extends QueryKey {
  const EpaperIssuesKey(super.language, this.yearId);

  final int yearId;

  @override
  List<Object?> get parts => <Object?>[yearId];
}

final FutureProviderFamily<List<EpaperYear>, EpaperYearsKey>
epaperYearsProvider = FutureProvider.family<List<EpaperYear>, EpaperYearsKey>((
  Ref ref,
  EpaperYearsKey key,
) async {
  final bool isAuthenticated = ref.watch(
    sessionProvider.select((SessionState s) => s.isAuthenticated),
  );
  if (!isAuthenticated) return const <EpaperYear>[];
  ref.cacheFor(key.freshFor);
  final Directory root = await ref.read(epaperDirectoryProvider.future);
  try {
    final List<EpaperYear> years = await ref
        .watch(epaperRepositoryProvider(key.language))
        .getYears();
    // **Nicht abwarten:** Die Liste steht bereits, das Spiegeln ist
    // Nebensache und darf den Abruf nicht aufhalten. (Ein `await` auf echte
    // Datei-Arbeit kehrt in der nachgestellten Zeit eines Widget-Tests nie
    // zurück — der Bildschirm bliebe dort ewig im Ladezustand.)
    unawaited(EpaperCatalog.saveYears(root, years));
    ref.markSynced();
    return years;
  } on ConnectionFailure {
    final List<EpaperYear>? gespiegelt = await EpaperCatalog.loadYears(root);
    if (gespiegelt == null) rethrow;
    return gespiegelt;
  }
}, isAutoDispose: true);

final FutureProviderFamily<List<EpaperIssue>, EpaperIssuesKey>
epaperIssuesProvider =
    FutureProvider.family<List<EpaperIssue>, EpaperIssuesKey>((
      Ref ref,
      EpaperIssuesKey key,
    ) async {
      final bool isAuthenticated = ref.watch(
        sessionProvider.select((SessionState s) => s.isAuthenticated),
      );
      if (!isAuthenticated) return const <EpaperIssue>[];
      ref.cacheFor(key.freshFor);
      final Directory root = await ref.read(epaperDirectoryProvider.future);
      try {
        final List<EpaperIssue> roh = await ref
            .watch(epaperRepositoryProvider(key.language))
            .getIssues(yearId: key.yearId);
        final List<EpaperIssue> issues = await _ohneToteAusgaben(
          ref.read(fileClientProvider),
          roh,
        );
        // Nicht abwarten — siehe `epaperYearsProvider`.
        unawaited(EpaperCatalog.saveIssues(root, key.yearId, issues));
        ref.markSynced();
        return issues;
      } on ConnectionFailure {
        final List<EpaperIssue>? gespiegelt = await EpaperCatalog.loadIssues(
          root,
          key.yearId,
        );
        if (gespiegelt == null) rethrow;
        return gespiegelt;
      }
    }, isAutoDispose: true);

const int _gleichzeitig = 6;
const Duration _gesamtfrist = Duration(seconds: 20);

Future<List<EpaperIssue>> _ohneToteAusgaben(
  FileClient client,
  List<EpaperIssue> issues,
) async {
  final List<Uri> adressen = <Uri>[
    for (final EpaperIssue issue in issues)
      if (issue.href case final Uri href) href,
  ];
  if (adressen.isEmpty) return issues;

  final Set<Uri> tot = <Uri>{};
  Future<void> pruefen() async {
    for (int i = 0; i < adressen.length; i += _gleichzeitig) {
      final List<Uri> teil = adressen.skip(i).take(_gleichzeitig).toList();
      final List<bool> ergebnis = await Future.wait(
        teil.map((Uri url) => client.isAvailable(url)),
      );
      for (int j = 0; j < teil.length; j++) {
        if (!ergebnis[j]) tot.add(teil[j]);
      }
    }
  }

  try {
    await pruefen().timeout(_gesamtfrist);
  } on TimeoutException {
    // Was bis hierhin als tot erkannt wurde, bleibt erkannt; der Rest
    // steht weiter in der Liste.
  }
  if (tot.isEmpty) return issues;
  return <EpaperIssue>[
    for (final EpaperIssue issue in issues)
      if (issue.href == null || !tot.contains(issue.href)) issue,
  ];
}
