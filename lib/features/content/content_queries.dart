import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/constants.dart';
import '../../core/query.dart';
import 'article.dart';
import 'content_repository.dart';

/// Abfrageschlüssel für Beitragslisten.
///
/// Der Basiskonstruktor verlangt die Sprache (Regel 3) — eine Liste ohne
/// Sprache ist nicht ausdrückbar. Ein Sprachwechsel erzeugt damit einen anderen
/// Schlüssel, die alte Abfrage wird entwertet und die Liste lädt neu. Die
/// Sprachbäume bleiben getrennt; es gibt keine gemischte Liste (Abgrenzung
/// A-04).
final class ArticleListKey extends QueryKey {
  const ArticleListKey(
    super.language, {
    this.page = 1,
    this.perPage = 10,
    this.categoryId,
    this.authorId,
    this.tagId,
    this.search,
    this.publishedAfter,
    this.publishedBefore,
    this.excludeIds = const <int>[],
    this.excludeTagId,
  });

  /// Seitenweises Nachladen (R-02).
  final int page;

  final int perPage;

  final int? categoryId;

  final int? authorId;

  final int? tagId;

  final String? search;

  final DateTime? publishedAfter;

  /// Obere Grenze (einschließlich). Die Filterfläche setzt hier bereits das
  /// Tagesende, damit der gewählte letzte Tag noch mitzählt.
  final DateTime? publishedBefore;

  final List<int> excludeIds;

  final int? excludeTagId;

  @override
  List<Object?> get parts => <Object?>[
    page,
    perPage,
    categoryId,
    authorId,
    tagId,
    search,
    publishedAfter,
    publishedBefore,
    // Eine Liste vergleicht Dart nach Identität — als Text ist der
    // Schlüssel gleich, wenn die IDs gleich sind.
    excludeIds.join(','),
    excludeTagId,
  ];
}

/// Abfrageschlüssel für einen einzelnen Beitrag.
final class ArticleKey extends QueryKey {
  const ArticleKey(super.language, this.id);

  final int id;

  @override
  List<Object?> get parts => <Object?>[id];

  /// Ein veröffentlichter Text ändert sich selten (60 Minuten statt 5).
  @override
  Duration get freshFor => CachePolicy.article;
}

final FutureProviderFamily<ArticlePage, ArticleListKey> articleListProvider =
    FutureProvider.family<ArticlePage, ArticleListKey>((
      Ref ref,
      ArticleListKey key,
    ) async {
      ref.cacheFor(key.freshFor);
      final ArticlePage page = await ref
          .watch(contentRepositoryProvider(key.language))
          .getArticles(key, refresh: ref.consumeRefresh(key));
      ref.markSynced();
      return page;
    }, isAutoDispose: true);

final FutureProviderFamily<Article?, ArticleKey> articleProvider =
    FutureProvider.family<Article?, ArticleKey>((
      Ref ref,
      ArticleKey key,
    ) async {
      ref.cacheFor(key.freshFor);
      final Article? article = await ref
          .watch(contentRepositoryProvider(key.language))
          .getArticle(key, refresh: ref.consumeRefresh(key));
      ref.markSynced();
      return article;
    }, isAutoDispose: true);
