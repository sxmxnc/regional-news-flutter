import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../core/failure.dart';
import '../../core/time_format.dart';
import '../../i18n/translations.dart';
import '../../ui/loading_view.dart';
import '../../ui/network_image.dart';
import '../../ui/theme/app_theme.dart';
import 'article.dart';
import 'article_navigation.dart';
import 'article_tile.dart';
import 'content_queries.dart';
import 'content_repository.dart';
import 'home_sections.dart';
import 'taxonomy.dart';
import 'term_articles_screen.dart';

class HomeSectionView extends ConsumerWidget {
  const HomeSectionView({
    required this.language,
    required this.section,
    required this.excludeIds,
    required this.excludeTagId,
    super.key,
  });

  final AppLanguage language;
  final HomeSection section;
  final List<int> excludeIds;
  final int? excludeTagId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    final ArticleListKey key = section.key(
      language,
      excludeIds: excludeIds,
      excludeTagId: excludeTagId,
    );
    final AsyncValue<ArticlePage> feed = ref.watch(articleListProvider(key));

    final List<Article>? articles = feed.value?.articles;
    // Ein Block ohne Beiträge — eine Rubrik, die nach den Ausschlüssen leer
    // ist — entfällt ganz, statt eine Überschrift über nichts zu setzen.
    if (articles != null && articles.isEmpty) return const SizedBox.shrink();

    if (section.kind == HomeSectionKind.themeOfMonth) {
      return _ThemeOfMonthBlock(
        texts: texts,
        article: articles?.first,
        error: feed.error,
        onRetry: () => ref.invalidate(articleListProvider(key)),
        onTap: articles == null
            ? null
            : () => openArticle(context, language, articles.first.id),
      );
    }

    // Nur noch Rubrik und Kolumne erreichen diese Stelle — „Thema des
    // Monats" ist oben bereits abgezweigt.
    final String label = switch (section.kind) {
      HomeSectionKind.category => section.term!.displayName,
      HomeSectionKind.column => texts['home_column'],
      HomeSectionKind.themeOfMonth => texts['home_theme_of_month'],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionHeader(label: label),
        if (articles == null)
          switch (feed.error) {
            final Object error => _SectionError(
              texts: texts,
              error: error,
              onRetry: () => ref.invalidate(articleListProvider(key)),
            ),
            null => const _SectionLoading(),
          }
        else ...<Widget>[
          _LeadArticle(
            article: articles.first,
            onTap: () => openArticle(context, language, articles.first.id),
          ),
          for (final Article article in articles.skip(1)) ...<Widget>[
            const Divider(height: 1),
            ArticleTile(
              article: article,
              onTap: () => openArticle(context, language, article.id),
            ),
          ],
          if (section.hasMore)
            _MoreButton(texts: texts, onPressed: () => _openMore(context)),
        ],
      ],
    );
  }

  void _openMore(BuildContext context) {
    final TaxonomyTerm term = section.term!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TermArticlesScreen(
          language: language,
          title: term.displayName,
          categoryId: term.id,
          categorySlug: term.slug,
        ),
      ),
    );
  }
}

/// Layoutmuster (d): Bezeichnung in Großbuchstaben auf schwarzem Kasten, darunter
/// die rote Linie über die ganze Breite (Screenshot der Website, Abschnitt 9
/// der Design-Referenz).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ColoredBox(
              color: NwbColors.surfaceDark,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: NwbColors.onBrand,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 3,
              width: double.infinity,
              child: ColoredBox(color: NwbColors.brand),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOfMonthBlock extends StatelessWidget {
  const _ThemeOfMonthBlock({
    required this.texts,
    required this.article,
    required this.error,
    required this.onRetry,
    required this.onTap,
  });

  final Translations texts;
  final Article? article;

  /// Der Fehler des Abrufs, solange noch kein Beitrag vorliegt.
  final Object? error;
  final VoidCallback onRetry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: ColoredBox(
        color: NwbColors.themeOfMonthBackground,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                header: true,
                child: Column(
                  children: <Widget>[
                    Text(
                      texts['home_theme_of_month'].toUpperCase(),
                      textAlign: TextAlign.center,
                      style: textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    const ColoredBox(
                      color: NwbColors.brand,
                      child: SizedBox(height: 2, width: double.infinity),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (article case final Article art)
                InkWell(
                  onTap: onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: NwbNetworkImage(url: art.imageUrl),
                      ),
                      const SizedBox(height: 10),
                      if (art.overline case final String overline
                          when overline.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            overline.toUpperCase(),
                            style: nwbThemeOfMonthKicker(context),
                          ),
                        ),
                      Text(art.title, style: nwbThemeOfMonthTitle(context)),
                    ],
                  ),
                )
              else if (error case final Object failure)
                _SectionError(texts: texts, error: failure, onRetry: onRetry)
              else
                const _SectionLoading(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Der Leitartikel: großes Bild, darunter Overline, Titel und Datum.
class _LeadArticle extends StatelessWidget {
  const _LeadArticle({required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 10,
              child: NwbNetworkImage(url: article.imageUrl),
            ),
            const SizedBox(height: 12),
            if (article.overline case final String overline
                when overline.isNotEmpty)
              Text(overline.toUpperCase(), style: textTheme.labelLarge),
            Text(article.title, style: textTheme.headlineMedium),
            if (article.publishedAt case final DateTime published)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  formatWarsawDate(published),
                  style: textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.texts, required this.onPressed});

  final Translations texts;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: FilledButton(
          onPressed: onPressed,
          child: Text(texts['home_read_more'].toUpperCase()),
        ),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LoadingPlaceholderRow(),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({
    required this.texts,
    required this.error,
    required this.onRetry,
  });

  final Translations texts;
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: <Widget>[
          Text(texts[failureMessageKey(error)], textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: Text(texts['retry'])),
        ],
      ),
    );
  }
}
