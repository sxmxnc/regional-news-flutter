import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../core/failure.dart';
import '../../core/query.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../ui/async_view.dart';
import '../../ui/empty_view.dart';
import '../../ui/network_image.dart';
import '../../ui/offline_banner.dart';
import '../../ui/theme/app_theme.dart';
import 'article.dart';
import 'article_navigation.dart';
import 'article_tile.dart';
import 'content_queries.dart';
import 'content_repository.dart';
import 'headline_selection.dart';
import 'home_section_view.dart';
import 'home_sections.dart';
import 'taxonomy_queries.dart';

class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Regel 3: Ein Sprachwechsel erzeugt andere Schlüssel, alles lädt neu.
    final AppLanguage language = ref.watch(languageProvider);
    final Translations texts = ref.watch(translationsProvider);
    final HomePlanKey planKey = HomePlanKey(language);
    final AsyncValue<HomePlan> plan = ref.watch(homePlanProvider(planKey));

    return nwbAsyncView<HomePlan>(
      plan,
      onRetry: () => ref.invalidate(homePlanProvider(planKey)),
      data: (HomePlan value) => _Start(
        language: language,
        texts: texts,
        plan: value,
        // Auch ein gescheiterter Abruf der Blockfolge zählt: Beim Herunterziehen
        // ohne Netz scheitert er als erster, noch vor den Beiträgen.
        planOffline: isOfflineWithContent(plan),
      ),
    );
  }
}

class _Start extends ConsumerWidget {
  const _Start({
    required this.language,
    required this.texts,
    required this.plan,
    required this.planOffline,
  });

  final AppLanguage language;
  final Translations texts;
  final HomePlan plan;
  final bool planOffline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ArticleListKey topKey = plan.topKey(language);
    final AsyncValue<ArticlePage> top = ref.watch(articleListProvider(topKey));

    final bool isOffline = planOffline || isOfflineWithContent(top);

    return Column(
      children: <Widget>[
        OfflineBanner(isOffline: isOffline),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: nwbAsyncView<ArticlePage>(
              top,
              onRetry: () => ref.invalidate(articleListProvider(topKey)),
              data: (ArticlePage page) => page.isEmpty
                  ? EmptyListView(message: texts['empty_list'])
                  : _Feed(
                      language: language,
                      plan: plan,
                      articles: page.articles,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    final HomePlanKey planKey = HomePlanKey(language);
    ref.requestNetworkRefresh(<QueryKey>[
      language.homeMenuKey,
      language.homeCategoriesKey,
      language.homeThemeTagKey,
    ]);
    ref.invalidate(menuCategoryListProvider(language.homeMenuKey));
    ref.invalidate(taxonomyListProvider(language.homeCategoriesKey));
    ref.invalidate(taxonomyTermBySlugProvider(language.homeThemeTagKey));

    try {
      final HomePlan fresh = await ref.read(homePlanProvider(planKey).future);
      final ArticleListKey topKey = fresh.topKey(language);
      ref.requestNetworkRefresh(<QueryKey>[topKey]);
      ref.invalidate(articleListProvider(topKey));
      final ArticlePage top = await ref.read(
        articleListProvider(topKey).future,
      );

      final List<Article> headline = selectHeadline(top.articles);
      final List<Article> list = selectList(
        top.articles,
        headline,
        count: HomeLayout.listCount,
      );
      final List<ArticleListKey> sectionKeys = fresh.sectionKeys(
        language,
        <int>[
          if (headline.isNotEmpty) headline.first.id,
          for (final Article article in list) article.id,
        ],
      );
      ref.requestNetworkRefresh(sectionKeys);
      for (final ArticleListKey key in sectionKeys) {
        ref.invalidate(articleListProvider(key));
      }
      await Future.wait(<Future<void>>[
        for (final ArticleListKey key in sectionKeys)
          ref
              .read(articleListProvider(key).future)
              .then<void>((_) {})
              .catchError((Object _) {}, test: (Object e) => e is Failure),
      ]);
    } on Failure {
      // Individual sections render their own loading errors.
    }
  }
}

class _Feed extends StatelessWidget {
  const _Feed({
    required this.language,
    required this.plan,
    required this.articles,
  });

  final AppLanguage language;
  final HomePlan plan;
  final List<Article> articles;

  @override
  Widget build(BuildContext context) {
    final List<Article> headline = selectHeadline(articles);
    final List<Article> list = selectList(
      articles,
      headline,
      count: HomeLayout.listCount,
    );
    // Der Leitartikel bleibt ausgeschlossen, auch wenn er nicht mehr in
    // `list` steht — sonst tauchte er in einem Rubrikblock darunter erneut auf.
    final List<int> excludeIds = <int>[
      if (headline.isNotEmpty) headline.first.id,
      for (final Article article in list) article.id,
    ];

    return CustomScrollView(
      slivers: <Widget>[
        if (headline.isNotEmpty)
          SliverToBoxAdapter(
            child: _HeadlineCarousel(articles: headline, language: language),
          ),
        SliverList.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) => ArticleTile(
            article: list[index],
            onTap: () => openArticle(context, language, list[index].id),
          ),
        ),
        SliverList.builder(
          itemCount: plan.sections.length,
          itemBuilder: (BuildContext context, int index) => HomeSectionView(
            language: language,
            section: plan.sections[index],
            excludeIds: excludeIds,
            excludeTagId: plan.themeTagId,
          ),
        ),
        // Ende der Seite — kein Nachladen, wie auf der Website.
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _HeadlineCarousel extends StatefulWidget {
  const _HeadlineCarousel({required this.articles, required this.language});

  final List<Article> articles;
  final AppLanguage language;

  @override
  State<_HeadlineCarousel> createState() => _HeadlineCarouselState();
}

class _HeadlineCarouselState extends State<_HeadlineCarousel> {
  final PageController _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: _pageController,
            itemCount: widget.articles.length,
            onPageChanged: (int value) => setState(() => _index = value),
            itemBuilder: (BuildContext context, int index) => _HeadlineTile(
              article: widget.articles[index],
              language: widget.language,
            ),
          ),
          if (widget.articles.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < widget.articles.length; i++)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index
                            ? NwbColors.onBrand
                            : NwbColors.onBrandMuted,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Layoutmuster (a) der Design-Referenz, wie die Telefonaufnahmen es zeigen
/// (Abschnitt 9): großes Bild, unten ein abgedunkelter Streifen mit dem Titel
/// weiß und groß — **ohne** Overline, anders als in den Kacheln darunter.
class _HeadlineTile extends StatelessWidget {
  const _HeadlineTile({required this.article, required this.language});

  final Article article;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openArticle(context, language, article.id),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Dunkle Ausweichfläche statt der hellen Vorgabe: Darüber liegt die
          // weiße Schlagzeile, die auf hellem Grau nicht mehr lesbar wäre.
          NwbNetworkImage(
            url: article.imageUrl,
            placeholderColor: NwbColors.surfaceDark,
          ),
          Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  NwbColors.headlineScrimTop,
                  NwbColors.headlineScrimBottom,
                ],
              ),
            ),
            child: Text(
              article.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: NwbColors.onBrand),
            ),
          ),
        ],
      ),
    );
  }
}
