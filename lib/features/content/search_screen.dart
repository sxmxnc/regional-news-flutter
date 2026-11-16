import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../ui/async_view.dart';
import '../../ui/empty_view.dart';
import '../../ui/nav/area_navigation_bar.dart';
import '../../ui/offline_banner.dart';
import '../../ui/theme/app_theme.dart';
import 'article.dart';
import 'article_navigation.dart';
import 'article_tile.dart';
import 'content_queries.dart';
import 'content_repository.dart';
import 'load_more_articles.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with LoadMoreArticles<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    listenForLoadMore(_loadNextPage);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _loadNextPage() {
    final AppLanguage? language = pagingLanguage;
    if (language == null || _query.isEmpty) return;
    loadMore(
      ref.read(contentRepositoryProvider(language)),
      (int page) => ArticleListKey(language, page: page, search: _query),
    );
  }

  /// Wartet auf eine kurze Tippause, statt bei jedem Tastenanschlag eine
  /// eigene Anfrage auszulösen.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final String next = value.trim();
      if (next == _query) return;
      // Der nachgeladene Bestand gehört zum vorherigen Suchbegriff und muss
      // mit verworfen werden — `resetPaging` setzt den Zustand selbst,
      // deshalb kein zweites `setState` daneben.
      _query = next;
      resetPaging();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLanguage language = ref.watch(languageProvider);
    // Regel 3: Ein Sprachwechsel verwirft die nachgeladenen Treffer der
    // vorherigen Sprache (`LoadMoreArticles.syncPagingLanguage`).
    syncPagingLanguage(language);

    final Translations texts = ref.watch(translationsProvider);
    final bool hasQuery = _query.isNotEmpty;
    // Ohne Suchbegriff wird nichts abgefragt — ein leerer `search`-Parameter
    // lieferte die ungefilterte Beitragsliste, und die gehört auf die
    // Startseite, nicht in die Suche.
    final ArticleListKey key = ArticleListKey(language, search: _query);
    final AsyncValue<ArticlePage> results = hasQuery
        ? ref.watch(articleListProvider(key))
        : const AsyncValue<ArticlePage>.loading();

    final bool isOffline = hasQuery && isOfflineWithContent(results);

    // Dieselbe Schriftart wie jeder andere Kopfzeilentitel — Farbwerte und
    // Schriftgrößen stehen ausschließlich im Theme (README.md, Konventionen),
    // deshalb wird hier der vorhandene Wert gelesen statt einer eigenen Größe.
    final TextStyle? titleStyle = Theme.of(context).appBarTheme.titleTextStyle;

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          style: titleStyle,
          cursorColor: titleStyle?.color,
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText: texts['search_hint'],
            hintStyle: titleStyle?.copyWith(color: NwbColors.onBrandHint),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          OfflineBanner(isOffline: isOffline),
          Expanded(
            child: !hasQuery
                ? Center(child: Text(texts['search_hint']))
                : nwbAsyncView<ArticlePage>(
                    results,
                    onRetry: () => ref.invalidate(articleListProvider(key)),
                    data: (ArticlePage page) {
                      syncFirstPage(page);
                      return _Results(
                        scrollController: scrollController,
                        language: language,
                        texts: texts,
                        query: _query,
                        firstPage: page,
                        extra: loadedExtra,
                        isLoadingMore: isLoadingMore,
                        loadMoreError: loadMoreError,
                        onRetryLoadMore: _loadNextPage,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.scrollController,
    required this.language,
    required this.texts,
    required this.query,
    required this.firstPage,
    required this.extra,
    required this.isLoadingMore,
    required this.loadMoreError,
    required this.onRetryLoadMore,
  });

  final ScrollController scrollController;
  final AppLanguage language;
  final Translations texts;
  final String query;
  final ArticlePage firstPage;
  final List<Article> extra;
  final bool isLoadingMore;
  final Object? loadMoreError;
  final VoidCallback onRetryLoadMore;

  @override
  Widget build(BuildContext context) {
    final List<Article> articles = <Article>[...firstPage.articles, ...extra];
    if (articles.isEmpty) {
      return EmptyListView(
        message: texts.format('search_no_results', <String, Object?>{
          'query': query,
        }),
        controller: scrollController,
      );
    }
    return CustomScrollView(
      controller: scrollController,
      slivers: <Widget>[
        SliverList.separated(
          itemCount: articles.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) => ArticleTile(
            article: articles[index],
            onTap: () => openArticle(context, language, articles[index].id),
          ),
        ),
        SliverToBoxAdapter(
          child: LoadMoreFooter(
            isLoading: isLoadingMore,
            error: loadMoreError,
            onRetry: onRetryLoadMore,
            texts: texts,
          ),
        ),
      ],
    );
  }
}
