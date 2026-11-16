import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../core/failure.dart';
import '../../core/query.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../ui/async_view.dart';
import '../../ui/empty_view.dart';
import '../../ui/language_flag_button.dart';
import '../../ui/nav/area_navigation_bar.dart';
import '../../ui/nav/tab_state.dart';
import '../../ui/offline_banner.dart';
import 'article.dart';
import 'article_navigation.dart';
import 'article_tile.dart';
import 'content_queries.dart';
import 'content_repository.dart';
import 'load_more_articles.dart';
import 'taxonomy.dart';
import 'taxonomy_queries.dart';

class TermArticlesScreen extends ConsumerStatefulWidget {
  const TermArticlesScreen({
    required this.language,
    required this.title,
    this.categoryId,
    this.categorySlug,
    this.authorId,
    this.tagId,
    this.dateFrom,
    this.dateTo,
    super.key,
  });

  final AppLanguage language;
  final String title;
  final int? categoryId;
  final String? categorySlug;
  final int? authorId;
  final int? tagId;

  final DateTime? dateFrom;
  final DateTime? dateTo;

  @override
  ConsumerState<TermArticlesScreen> createState() => _TermArticlesScreenState();
}

class _TermArticlesScreenState extends ConsumerState<TermArticlesScreen>
    with LoadMoreArticles<TermArticlesScreen> {
  late AppLanguage _language;
  late String _title;
  int? _categoryId;

  /// Wandert beim Sprachwechsel mit [_categoryId] mit. `widget.categorySlug`
  /// bliebe auf dem Slug der Ausgangssprache stehen und träfe schon beim
  /// zweiten Wechsel daneben.
  String? _categorySlug;
  int? _authorId;
  int? _tagId;

  @override
  void initState() {
    super.initState();
    _language = widget.language;
    _title = widget.title;
    _categoryId = widget.categoryId;
    _categorySlug = widget.categorySlug;
    _authorId = widget.authorId;
    _tagId = widget.tagId;
    listenForLoadMore(_loadNextPage);
  }

  /// Der Zeitraum ist sprachunabhängig und ändert sich nie — er kommt
  /// unverändert aus dem Widget, anders als Rubrik, Titel und Sprache, die
  /// der Sprachwechsel neu auflöst.
  ArticleListKey _keyForPage(int page) => ArticleListKey(
    _language,
    page: page,
    categoryId: _categoryId,
    authorId: _authorId,
    tagId: _tagId,
    publishedAfter: widget.dateFrom,
    publishedBefore: widget.dateTo,
  );

  void _loadNextPage() {
    loadMore(ref.read(contentRepositoryProvider(_language)), _keyForPage);
  }

  Future<void> _handleLanguageChange(AppLanguage newLanguage) async {
    final bool hasUntranslatableTerm = _authorId != null || _tagId != null;
    final AppLanguage oldLanguage = _language;
    final int? categoryId = _categoryId;
    final String? slug = _categorySlug;

    if (!hasUntranslatableTerm && categoryId == null) {
      setState(() => _language = newLanguage);
      resetPaging();
      return;
    }

    if (categoryId == null || hasUntranslatableTerm) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    List<TaxonomyTerm> categories = const <TaxonomyTerm>[];
    try {
      categories = await ref.read(
        taxonomyListProvider(
          TaxonomyListKey(newLanguage, TaxonomyResource.categories),
        ).future,
      );
    } on Failure {
      // siehe oben
    }
    if (!mounted) return;

    final TaxonomyTerm? resolved = _resolve(
      categories,
      fromLanguage: oldLanguage,
      categoryId: categoryId,
      slug: slug,
    );
    if (resolved == null) {
      ref.read(selectedTabProvider.notifier).select(1);
      Navigator.of(context).popUntil((Route<void> route) => route.isFirst);
      return;
    }

    setState(() {
      _language = newLanguage;
      _categoryId = resolved.id;
      _categorySlug = resolved.slug;
      _title = resolved.displayName;
    });
    resetPaging();
  }

  /// Sucht in [categories] — Begriffe der **Zielsprache** — die Entsprechung
  /// zu [categoryId] aus [fromLanguage]. Erster Anlauf: die
  /// Übersetzungsverknüpfung des Zusatz-Plugins. Zweiter Anlauf: der Slug,
  /// falls das Plugin nichts liefert. Kein Treffer ergibt `null`.
  static TaxonomyTerm? _resolve(
    List<TaxonomyTerm> categories, {
    required AppLanguage fromLanguage,
    required int categoryId,
    required String? slug,
  }) {
    for (final TaxonomyTerm term in categories) {
      if (term.translations[fromLanguage.code] == categoryId) return term;
    }
    if (slug == null || slug.isEmpty) return null;
    for (final TaxonomyTerm term in categories) {
      if (term.slug == slug) return term;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppLanguage>(languageProvider, (
      AppLanguage? previous,
      AppLanguage next,
    ) {
      if (previous != null && previous != next) _handleLanguageChange(next);
    });

    final Translations texts = ref.watch(translationsProvider);
    final ArticleListKey key = _keyForPage(1);
    final AsyncValue<ArticlePage> feed = ref.watch(articleListProvider(key));

    final bool isOffline = isOfflineWithContent(feed);

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(
        title: Text(_title),
        actions: const <Widget>[LanguageFlagButton()],
      ),
      body: Column(
        children: <Widget>[
          OfflineBanner(isOffline: isOffline),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                resetPaging();
                ref.requestNetworkRefresh(<QueryKey>[key]);
                ref.invalidate(articleListProvider(key));
                try {
                  await ref.read(articleListProvider(key).future);
                } on Failure {
                  // Absichtlich ohne Folge — siehe oben.
                }
              },
              child: nwbAsyncView<ArticlePage>(
                feed,
                onRetry: () => ref.invalidate(articleListProvider(key)),
                data: (ArticlePage page) => _buildList(page, texts),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ArticlePage page, Translations texts) {
    syncFirstPage(page);
    final List<Article> articles = <Article>[...page.articles, ...loadedExtra];
    if (articles.isEmpty) {
      return EmptyListView(
        message: texts['empty_list'],
        controller: scrollController,
      );
    }
    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverList.separated(
          itemCount: articles.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) => ArticleTile(
            article: articles[index],
            onTap: () => openArticle(context, _language, articles[index].id),
          ),
        ),
        SliverToBoxAdapter(
          child: LoadMoreFooter(
            isLoading: isLoadingMore,
            error: loadMoreError,
            onRetry: _loadNextPage,
            texts: texts,
          ),
        ),
      ],
    );
  }
}
