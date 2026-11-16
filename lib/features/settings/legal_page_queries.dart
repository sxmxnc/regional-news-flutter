import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/constants.dart';
import '../../core/query.dart';
import 'legal_page.dart';
import 'legal_page_repository.dart';

/// Abfrageschlüssel für eine Seite. Wie jeder Schlüssel Regel-3-pflichtig:
/// Sprache ist Teil des Schlüssels, weil Impressum und Datenschutzerklärung
/// unter unterschiedlichen Slugs je Sprachzweig liegen können
/// (`legal_pages_config.dart`).
final class LegalPageKey extends QueryKey {
  const LegalPageKey(super.language, this.slug);

  final String slug;

  @override
  List<Object?> get parts => <Object?>[slug];

  /// Seiten wie Impressum und Datenschutzerklärung ändern sich fast nie —
  /// dieselbe Vorhaltedauer wie Taxonomien.
  @override
  Duration get freshFor => CachePolicy.taxonomy;
}

final FutureProviderFamily<LegalPage?, LegalPageKey> legalPageProvider =
    FutureProvider.family<LegalPage?, LegalPageKey>((
      Ref ref,
      LegalPageKey key,
    ) async {
      ref.cacheFor(key.freshFor);
      final LegalPage? page = await ref
          .watch(legalPageRepositoryProvider(key.language))
          .getPage(key.slug);
      ref.markSynced();
      return page;
    }, isAutoDispose: true);
