import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../../api/mapper/article_mapper.dart';
import '../../api/wp_client.dart';
import '../../core/app_language.dart';
import '../../core/failure.dart';
import 'article.dart';
import 'content_queries.dart';
import 'featured_media_fallback.dart';

final class ContentRepository {
  const ContentRepository(this._client);

  final WpClient _client;

  Future<ArticlePage> getArticles(
    ArticleListKey key, {
    bool refresh = false,
  }) async {
    final WpListPage page = await _client.getList(
      'posts',
      query: <String, String>{
        'per_page': key.perPage.toString(),
        'page': key.page.toString(),
        'orderby': 'date',
        'order': 'desc',
        '_fields': _listFields,
        if (key.categoryId case final int id) 'categories': id.toString(),
        if (key.authorId case final int id) 'redaktor': id.toString(),
        if (key.tagId case final int id) 'tags': id.toString(),
        if (key.excludeIds.isNotEmpty) 'exclude': key.excludeIds.join(','),
        if (key.excludeTagId case final int id) 'tags_exclude': id.toString(),
        if (key.search case final String search when search.isNotEmpty)
          'search': search,
        if (key.publishedAfter case final DateTime after)
          'after': after.toUtc().toIso8601String(),
        if (key.publishedBefore case final DateTime before)
          'before': before.toUtc().toIso8601String(),
      },
      refresh: refresh,
    );
    final List<Map<String, Object?>> items = await _withFallbackImages(
      page.items,
      refresh: refresh,
    );
    return ArticlePage(
      articles: ArticleMapper.fromList(items),
      total: page.total,
      totalPages: page.totalPages,
    );
  }

  Future<Article?> getArticle(ArticleKey key, {bool refresh = false}) async {
    final Map<String, Object?> json = await _client.getObject(
      'posts/${key.id}',
      refresh: refresh,
    );
    final Map<String, Object?> enriched = await _withFallbackImage(
      json,
      refresh: refresh,
    );
    return ArticleMapper.fromJson(enriched);
  }

  Future<int?> resolveSlug(String slug) async {
    final WpListPage page = await _client.getList(
      'posts',
      query: <String, String>{'slug': slug, '_fields': 'id'},
    );
    if (page.items.isEmpty) return null;
    final Object? id = page.items.first['id'];
    return id is int ? id : null;
  }

  static const String _listFields =
      'id,date,date_gmt,link,title,excerpt,categories,tags,'
      'editorial_fields,editorial_translations,featured_media';

  Future<List<Map<String, Object?>>> _withFallbackImages(
    List<Map<String, Object?>> items, {
    required bool refresh,
  }) async {
    items = await Future.wait(<Future<Map<String, Object?>>>[
      for (final Map<String, Object?> item in items)
        _withTranslationMediaId(item, refresh: refresh),
    ]);
    final Set<int> ids = <int>{
      for (final Map<String, Object?> item in items)
        if (!hasOwnFeaturedImage(item))
          if (featuredMediaId(item) case final int id) id,
    };
    if (ids.isEmpty) return items;

    final Map<int, Map<String, Object?>> media = await _fetchMedia(
      ids,
      refresh: refresh,
    );
    if (media.isEmpty) return items;
    return <Map<String, Object?>>[
      for (final Map<String, Object?> item in items)
        mergeFallbackImage(item, media),
    ];
  }

  /// Dieselbe Anreicherung für genau einen Beitrag (Beitragsansicht).
  Future<Map<String, Object?>> _withFallbackImage(
    Map<String, Object?> item, {
    required bool refresh,
  }) async {
    if (hasOwnFeaturedImage(item)) return item;
    item = await _withTranslationMediaId(item, refresh: refresh);
    final int? id = featuredMediaId(item);
    if (id == null) return item;

    final Map<int, Map<String, Object?>> media = await _fetchMedia(<int>{
      id,
    }, refresh: refresh);
    return media.isEmpty ? item : mergeFallbackImage(item, media);
  }

  Future<Map<String, Object?>> _withTranslationMediaId(
    Map<String, Object?> item, {
    required bool refresh,
  }) async {
    if (hasOwnFeaturedImage(item) || featuredMediaId(item) != null) {
      return item;
    }
    for (final int translationId in translationIds(item)) {
      try {
        final Map<String, Object?> other = await _client.getObject(
          'posts/$translationId',
          query: <String, String>{'_fields': 'id,featured_media'},
          refresh: refresh,
        );
        if (featuredMediaId(other) case final int id) {
          return withFeaturedMediaId(item, id);
        }
      } on Failure {
        // The article is still readable without the fallback image.
      }
    }
    return item;
  }

  Future<Map<int, Map<String, Object?>>> _fetchMedia(
    Set<int> ids, {
    required bool refresh,
  }) async {
    try {
      final WpListPage page = await _client.getList(
        'media',
        query: <String, String>{
          'include': ids.join(','),
          'per_page': ids.length.toString(),
          '_fields': 'id,media_details,caption',
        },
        refresh: refresh,
      );
      return <int, Map<String, Object?>>{
        for (final Map<String, Object?> item in page.items)
          if (item['id'] case final int id) id: item,
      };
    } on Failure {
      return const <int, Map<String, Object?>>{};
    }
  }
}

/// Eine Seite Beiträge samt Bestand. [total] stammt aus `x-wp-total` und belegt
/// den Bestand des Sprachbaums — der schnellste Nachweis, dass die
/// Sprachableitung greift.
final class ArticlePage {
  const ArticlePage({required this.articles, this.total, this.totalPages});

  final List<Article> articles;
  final int? total;
  final int? totalPages;

  bool get isEmpty => articles.isEmpty;
}

/// Ein Repository **je Sprache** — abgeleitet aus dem Client derselben Sprache.
final ProviderFamily<ContentRepository, AppLanguage> contentRepositoryProvider =
    Provider.family<ContentRepository, AppLanguage>((
      Ref ref,
      AppLanguage language,
    ) {
      return ContentRepository(ref.watch(wpClientProvider(language)));
    });
