import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../../api/mapper/taxonomy_mapper.dart';
import '../../api/wp_client.dart';
import '../../core/app_language.dart';
import 'taxonomy.dart';

final class TaxonomyRepository {
  const TaxonomyRepository(this._client, this.resource);

  final WpClient _client;

  /// Einer der drei Werte aus [TaxonomyResource].
  final String resource;

  /// `editorial_menu` und `editorial_translations` liefert nur das Zusatz-Plugin; für
  /// Schlagworte und Autoren gibt es sie nicht. WordPress lässt unbekannte
  /// Namen in `_fields` wortlos weg, deshalb steht **eine** Liste hier statt
  /// einer je Taxonomie.
  static const String _fields = 'id,name,slug,count,editorial_menu,editorial_translations';

  Future<List<TaxonomyTerm>> getList({
    int perPage = 100,
    bool refresh = false,
  }) async {
    final WpListPage page = await _client.getList(
      resource,
      query: <String, String>{
        'per_page': perPage.toString(),
        '_fields': _fields,
      },
      refresh: refresh,
    );
    return TaxonomyMapper.fromList(page.items);
  }

  Future<List<TaxonomyTerm>> getMenuCategories({
    int perPage = 100,
    bool refresh = false,
  }) async {
    return menuSelection(await getList(perPage: perPage, refresh: refresh));
  }

  /// Der Auswahlschritt aus [getMenuCategories], ohne Netz — damit die Regel
  /// selbst prüfbar ist und nicht nur ihr Ergebnis.
  static List<TaxonomyTerm> menuSelection(List<TaxonomyTerm> terms) {
    final bool pluginAnswers = terms.any(
      (TaxonomyTerm term) => term.inMenu != null,
    );
    if (!pluginAnswers) return terms;

    final List<TaxonomyTerm> selected = terms
        .where((TaxonomyTerm term) => term.inMenu ?? false)
        .toList();
    // Die Reihenfolge der Website ist redaktionell gesetzt. Begriffe ohne
    // Platznummer kämen sonst je nach Antwort mal hierhin, mal dorthin —
    // sie landen einheitlich hinten.
    selected.sort((TaxonomyTerm a, TaxonomyTerm b) {
      final int left = a.menuPosition ?? 1 << 30;
      final int right = b.menuPosition ?? 1 << 30;
      return left == right ? a.id.compareTo(b.id) : left.compareTo(right);
    });
    return List<TaxonomyTerm>.unmodifiable(selected);
  }

  Future<TaxonomyTerm?> findBySlug(String slug, {bool refresh = false}) async {
    final WpListPage page = await _client.getList(
      resource,
      query: <String, String>{'slug': slug, '_fields': _fields},
      refresh: refresh,
    );
    final List<TaxonomyTerm> terms = TaxonomyMapper.fromList(page.items);
    return terms.isEmpty ? null : terms.first;
  }

  /// Ein einzelner Begriff — für die Meta-Zeile eines Beitrags (Rubrik,
  /// Autorenname), der nur die ID mitbringt.
  Future<TaxonomyTerm?> getTerm(int id, {bool refresh = false}) async {
    final Map<String, Object?> json = await _client.getObject(
      '$resource/$id',
      query: const <String, String>{'_fields': _fields},
      refresh: refresh,
    );
    return TaxonomyMapper.fromJson(json);
  }
}

/// Ein Repository je Sprache **und** Taxonomie — beides gehört zur Adresse.
final ProviderFamily<TaxonomyRepository, (AppLanguage, String)>
taxonomyRepositoryProvider =
    Provider.family<TaxonomyRepository, (AppLanguage, String)>((
      Ref ref,
      (AppLanguage, String) args,
    ) {
      final (AppLanguage language, String resource) = args;
      return TaxonomyRepository(
        ref.watch(wpClientProvider(language)),
        resource,
      );
    });
