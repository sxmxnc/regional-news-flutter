import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/constants.dart';
import '../../core/query.dart';
import 'taxonomy.dart';
import 'taxonomy_repository.dart';

/// Abfrageschlüssel für die vollständige Liste einer Taxonomie (R-01).
final class TaxonomyListKey extends QueryKey {
  const TaxonomyListKey(super.language, this.resource);

  final String resource;

  @override
  List<Object?> get parts => <Object?>[resource];

  @override
  Duration get freshFor => CachePolicy.taxonomy;
}

final class MenuCategoryKey extends QueryKey {
  const MenuCategoryKey(super.language);

  @override
  List<Object?> get parts => const <Object?>[];

  @override
  Duration get freshFor => CachePolicy.taxonomy;
}

/// Abfrageschlüssel für einen einzelnen Begriff — Rubrik- oder Autorenname in
/// der Meta-Zeile der Beitragsansicht.
final class TaxonomyTermKey extends QueryKey {
  const TaxonomyTermKey(super.language, this.resource, this.id);

  final String resource;
  final int id;

  @override
  List<Object?> get parts => <Object?>[resource, id];

  @override
  Duration get freshFor => CachePolicy.taxonomy;
}

final class TermSlugKey extends QueryKey {
  const TermSlugKey(super.language, this.resource, this.slug);

  final String resource;
  final String slug;

  @override
  List<Object?> get parts => <Object?>[resource, slug];

  @override
  Duration get freshFor => CachePolicy.taxonomy;
}

final FutureProviderFamily<List<TaxonomyTerm>, TaxonomyListKey>
taxonomyListProvider =
    FutureProvider.family<List<TaxonomyTerm>, TaxonomyListKey>((
      Ref ref,
      TaxonomyListKey key,
    ) async {
      ref.cacheFor(key.freshFor);
      final List<TaxonomyTerm> terms = await ref
          .watch(taxonomyRepositoryProvider((key.language, key.resource)))
          .getList(refresh: ref.consumeRefresh(key));
      ref.markSynced();
      return terms;
    }, isAutoDispose: true);

final FutureProviderFamily<TaxonomyTerm?, TaxonomyTermKey>
taxonomyTermProvider = FutureProvider.family<TaxonomyTerm?, TaxonomyTermKey>((
  Ref ref,
  TaxonomyTermKey key,
) {
  ref.cacheFor(key.freshFor);
  return ref
      .watch(taxonomyRepositoryProvider((key.language, key.resource)))
      .getTerm(key.id, refresh: ref.consumeRefresh(key));
}, isAutoDispose: true);

final FutureProviderFamily<List<TaxonomyTerm>, MenuCategoryKey>
menuCategoryListProvider =
    FutureProvider.family<List<TaxonomyTerm>, MenuCategoryKey>((
      Ref ref,
      MenuCategoryKey key,
    ) async {
      ref.cacheFor(key.freshFor);
      final List<TaxonomyTerm> terms = await ref
          .watch(
            taxonomyRepositoryProvider((
              key.language,
              TaxonomyResource.categories,
            )),
          )
          .getMenuCategories(refresh: ref.consumeRefresh(key));
      ref.markSynced();
      return terms;
    }, isAutoDispose: true);

/// Ein Begriff zu seinem Slug; `null`, wenn es ihn im Sprachbaum nicht gibt.
final FutureProviderFamily<TaxonomyTerm?, TermSlugKey>
taxonomyTermBySlugProvider = FutureProvider.family<TaxonomyTerm?, TermSlugKey>((
  Ref ref,
  TermSlugKey key,
) async {
  ref.cacheFor(key.freshFor);
  final TaxonomyTerm? term = await ref
      .watch(taxonomyRepositoryProvider((key.language, key.resource)))
      .findBySlug(key.slug, refresh: ref.consumeRefresh(key));
  ref.markSynced();
  return term;
}, isAutoDispose: true);
