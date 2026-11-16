import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/app_language.dart';
import '../../i18n/translations.dart';
import '../../ui/loading_view.dart';
import 'article.dart';
import 'content_queries.dart';
import 'content_repository.dart';

mixin LoadMoreArticles<T extends StatefulWidget> on State<T> {
  final List<Article> loadedExtra = <Article>[];
  int _nextPage = 2;
  bool hasMore = true;
  bool isLoadingMore = false;
  Object? loadMoreError;

  /// Der Scroll-Controller der Liste — an die `CustomScrollView` des
  /// Bildschirms geben.
  final ScrollController scrollController = ScrollController();

  VoidCallback? _loadNextPage;
  AppLanguage? _pagingLanguage;

  int? _firstPageTotal;

  /// Aus `build` mit der ersten Seite aufrufen, sobald sie vorliegt.
  void syncFirstPage(ArticlePage page) => _firstPageTotal = page.totalPages;

  int _generation = 0;

  /// Abstand zum Listenende in logischen Pixeln, ab dem die nächste Seite
  /// geholt wird — etwa eine Bildschirmhöhe voraus, damit die Liste beim
  /// Weiterscrollen nicht abreißt.
  static const double _loadMoreThreshold = 480;

  /// Aus `initState` aufrufen. [loadNextPage] holt die nächste Seite über
  /// [loadMore]; der Bildschirm kennt Sprache und Filter, das Mixin nicht.
  void listenForLoadMore(VoidCallback loadNextPage) {
    _loadNextPage = loadNextPage;
    scrollController.addListener(_maybeLoadMore);
  }

  void _maybeLoadMore() {
    if (!hasMore || isLoadingMore) return;
    if (!scrollController.hasClients) return;
    final ScrollPosition position = scrollController.position;
    if (position.pixels > position.maxScrollExtent - _loadMoreThreshold) {
      _loadNextPage?.call();
    }
  }

  /// Die Sprache, in der zuletzt gebaut wurde — für das Nachladen, das
  /// außerhalb von `build` läuft.
  AppLanguage? get pagingLanguage => _pagingLanguage;

  /// Aus `build` aufrufen. Regel 3: Ein Sprachwechsel entwertet den
  /// Abfrageschlüssel von selbst; der zusätzlich nachgeladene Bestand gehört
  /// aber zur vorherigen Sprache und muss mit verworfen werden — sonst folgt
  /// auf zehn deutsche Beiträge eine angehängte polnische Seite 2.
  void syncPagingLanguage(AppLanguage language) {
    if (_pagingLanguage != null && _pagingLanguage != language) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) resetPaging();
      });
    }
    _pagingLanguage = language;
  }

  Future<void> loadMore(
    ContentRepository repository,
    ArticleListKey Function(int page) keyForPage,
  ) async {
    if (!hasMore || isLoadingMore) return;
    if (_firstPageTotal case final int total when _nextPage > total) return;
    final int generation = _generation;
    bool current() => mounted && generation == _generation;
    setState(() {
      isLoadingMore = true;
      loadMoreError = null;
    });
    try {
      final ArticlePage page = await repository.getArticles(
        keyForPage(_nextPage),
      );
      // Der Bildschirm kann während der Anfrage verlassen oder der Bestand
      // zurückgesetzt worden sein — dann gehört die Seite nicht mehr hierher.
      if (!current()) return;
      setState(() {
        loadedExtra.addAll(page.articles);
        hasMore =
            page.articles.isNotEmpty &&
            (page.totalPages == null || _nextPage < page.totalPages!);
        _nextPage += 1;
      });
    } catch (error) {
      if (!current()) return;
      setState(() => loadMoreError = error);
    } finally {
      if (current()) setState(() => isLoadingMore = false);
    }
  }

  /// Beim Sprachwechsel oder Herunterziehen zum Aktualisieren: Der
  /// nachgeladene Bestand gehört zur vorherigen Sprache bzw. zum alten Stand
  /// und muss verworfen werden, bevor Seite 1 neu einläuft.
  void resetPaging() {
    setState(() {
      _generation++;
      loadedExtra.clear();
      _nextPage = 2;
      hasMore = true;
      isLoadingMore = false;
      loadMoreError = null;
    });
  }

  @override
  void dispose() {
    scrollController
      ..removeListener(_maybeLoadMore)
      ..dispose();
    super.dispose();
  }
}

class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.texts,
    super.key,
  });

  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;
  final Translations texts;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LoadingPlaceholderRow(),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: Text(texts['retry']),
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}
