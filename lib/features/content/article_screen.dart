import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_language.dart';
import '../../core/failure.dart';
import '../../core/time_format.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../ui/async_view.dart';
import '../../ui/brand_logo.dart';
import '../../ui/error_view.dart';
import '../../ui/html_style.dart';
import '../../ui/language_flag_button.dart';
import '../../ui/nav/area_navigation_bar.dart';
import '../../ui/nav/tab_state.dart';
import '../../ui/network_image.dart';
import '../../ui/offline_banner.dart';
import '../../ui/text_scale_button.dart';
import '../../ui/theme/app_theme.dart';
import 'article.dart';
import 'article_gallery.dart';
import 'article_html.dart';
import 'article_navigation.dart';
import 'content_queries.dart';
import 'related_articles.dart';
import 'taxonomy.dart';
import 'taxonomy_name.dart';
import 'term_articles_screen.dart';

class ArticleScreen extends ConsumerWidget {
  const ArticleScreen({
    required this.language,
    required this.articleId,
    super.key,
  });

  final AppLanguage language;
  final int articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    final ArticleKey key = ArticleKey(language, articleId);
    final AsyncValue<Article?> article = ref.watch(articleProvider(key));

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(
        title: const BrandLogo(),
        titleSpacing: 0,
        actions: <Widget>[
          if (article.value case final Article value) ...<Widget>[
            _ShareButton(article: value),
            const TextScaleButton(),
          ],
          article.maybeWhen(
            data: (Article? value) => value == null
                ? const LanguageFlagButton()
                : _ArticleLanguageButton(
                    article: value,
                    source: language,
                    current: ref.watch(languageProvider),
                  ),
            orElse: () => const LanguageFlagButton(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          OfflineBanner(isOffline: isOfflineWithContent(article)),
          Expanded(
            child: nwbAsyncView<Article?>(
              article,
              onRetry: () => ref.invalidate(articleProvider(key)),
              data: (Article? value) => value == null
                  ? ErrorView(
                      error: const ContentFailure(),
                      onRetry: () => ref.invalidate(articleProvider(key)),
                    )
                  : _ArticleBody(
                      article: value,
                      language: language,
                      texts: texts,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleLanguageButton extends ConsumerWidget {
  const _ArticleLanguageButton({
    required this.article,
    required this.source,
    required this.current,
  });

  final Article article;

  /// Sprache des offenen Beitrags.
  final AppLanguage source;

  /// Sprache der App. Weicht sie von [source] ab, hat die Nutzerin nach dem
  /// Hinweis S-03 „weiterlesen" gewählt: Die App steht dann schon auf der
  /// anderen Sprache, der Beitrag nicht.
  final AppLanguage current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage target = current == AppLanguage.de
        ? AppLanguage.pl
        : AppLanguage.de;
    return LanguageFlagButton(
      target: target,
      onPressed: () => _handleTap(context, ref, target),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    AppLanguage target,
  ) async {
    // Der Beitrag liegt bereits in der Zielsprache vor (nach „weiterlesen"):
    // Nur die App kehrt zu ihr zurück, der Beitrag bleibt offen.
    if (target == source) {
      await ref.read(languageProvider.notifier).select(target);
      return;
    }
    final int? translationId = article.translationId(target.code);
    if (translationId != null) {
      await ref.read(languageProvider.notifier).select(target);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              ArticleScreen(language: target, articleId: translationId),
        ),
      );
      return;
    }
    if (!context.mounted) return;
    await _showTranslationMissing(context, ref, source: source, target: target);
  }
}

Future<void> _showTranslationMissing(
  BuildContext context,
  WidgetRef ref, {
  required AppLanguage source,
  required AppLanguage target,
}) {
  final Translations texts = ref.read(translationsProvider);
  String adverb(AppLanguage language) =>
      texts[language == AppLanguage.de
          ? 'language_adverb_de'
          : 'language_adverb_pl'];

  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      content: Text(
        texts.format('translation_missing_message', <String, Object?>{
          'language': adverb(source),
        }),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            await ref.read(languageProvider.notifier).select(target);
          },
          child: Text(
            texts.format('translation_missing_continue', <String, Object?>{
              'language': adverb(source),
            }),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            await ref.read(languageProvider.notifier).select(target);
            if (!context.mounted) return;
            ref.read(selectedTabProvider.notifier).select(0);
            Navigator.of(context)
                .popUntil((Route<void> route) => route.isFirst);
          },
          child: Text(
            texts.format('translation_missing_home', <String, Object?>{
              'language': adverb(target),
            }),
          ),
        ),
      ],
    ),
  );
}

class _ShareButton extends ConsumerWidget {
  const _ShareButton({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    return IconButton(
      tooltip: texts['share_action'],
      onPressed: () => _share(article),
      icon: const Icon(Icons.share),
    );
  }

  static Future<void> _share(Article article) async {
    final String? link = article.link;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: link == null ? article.title : '${article.title}\n$link',
          subject: article.title,
        ),
      );
    } on Object catch (error) {
      developer.log('Teilen gescheitert: $error', name: 'ArticleScreen');
    }
  }
}

class _ArticleBody extends ConsumerWidget {
  const _ArticleBody({
    required this.article,
    required this.language,
    required this.texts,
  });

  final Article article;
  final AppLanguage language;
  final Translations texts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int? primaryCategoryId = article.categoryIds.isEmpty
        ? null
        : article.categoryIds.first;
    final int? primaryAuthorId = article.authorIds.isEmpty
        ? null
        : article.authorIds.first;
    const double horizontalPadding = 32;
    final double contentWidth =
        MediaQuery.sizeOf(context).width - horizontalPadding;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Breadcrumb(
            categoryId: primaryCategoryId,
            language: language,
            texts: texts,
          ),
          const SizedBox(height: 12),
          if (article.overline case final String overline
              when overline.isNotEmpty) ...<Widget>[
            Text(overline.toUpperCase(), style: textTheme.labelLarge),
            const SizedBox(height: 4),
          ],
          Text(article.title, style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          _MetaLine(
            article: article,
            language: language,
            texts: texts,
            authorId: primaryAuthorId,
            categoryId: primaryCategoryId,
          ),
          if (article.imageUrl case final String imageUrl) ...<Widget>[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: NwbNetworkImage(url: imageUrl),
              ),
            ),
          ],
          if (article.captionLine case final String caption) ...<Widget>[
            const SizedBox(height: 6),
            Text(caption, style: nwbCaption(context)),
          ],
          if (article.content case final String html
              when html.isNotEmpty) ...<Widget>[
            const SizedBox(height: 20),
            for (final Widget block in _contentBlocks(
              context,
              ref,
              html,
              contentWidth,
            ))
              block,
          ],
          if (article.tagIds.isNotEmpty) ...<Widget>[
            const SizedBox(height: 24),
            _TagList(tagIds: article.tagIds, language: language),
          ],
        ],
      ),
    );
  }

  List<Widget> _contentBlocks(
    BuildContext context,
    WidgetRef ref,
    String html,
    double contentWidth,
  ) {
    final List<Widget> widgets = <Widget>[];
    final List<ContentBlock> blocks = splitDriveGallery(
      splitAuthorBox(splitRelatedArticles(html)),
    );
    for (final ContentBlock block in blocks) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 16));
      widgets.add(switch (block) {
        HtmlBlock(:final html) => Html(
          data: sanitizeArticleHtml(html, maxWidth: contentWidth),
          style: nwbHtmlStyle(context),
          extensions: <HtmlExtension>[
            articleImageExtension(contentWidth),
            blockquoteExtension(contentWidth),
          ],
          onLinkTap: (url, attributes, element) {
            if (url != null) openContentLink(context, ref, url);
          },
        ),
        RelatedArticleBlock() => _RelatedArticleCard(block: block),
        AuthorBoxBlock() => _AuthorBoxCard(block: block),
        DriveGalleryBlock() => ArticleGalleryView(
          block: block,
          language: language,
          contentWidth: contentWidth,
        ),
      });
    }
    return widgets;
  }
}

class _RelatedArticleCard extends ConsumerWidget {
  const _RelatedArticleCard({required this.block});

  final RelatedArticleBlock block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: NwbColors.divider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () => openContentLink(context, ref, block.href),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 96,
                  height: 72,
                  child: NwbNetworkImage(url: block.imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (block.category case final String category
                        when category.isNotEmpty)
                      Text(
                        category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge,
                      ),
                    Text(
                      block.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    if (block.moreLabel case final String label
                        when label.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          label,
                          style: textTheme.bodySmall?.copyWith(
                            color: NwbColors.brand,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthorBoxCard extends StatelessWidget {
  const _AuthorBoxCard({required this.block});

  final AuthorBoxBlock block;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NwbColors.authorBoxBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(block.heading, style: nwbAuthorBoxHeading(context)),
            const SizedBox(height: 12),
            if (block.imageUrl case final String url) ...<Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                // Die Website lässt das Bild in seinem eigenen
                // Seitenverhältnis stehen (`width: 100%`, Höhe frei) — ohne
                // bekannte Maße vorab setzt die App wie beim Autorenfoto im
                // Bestand ein Quadrat an, dieselbe Annahme wie beim
                // Platzhalter der Kachel darüber.
                child: AspectRatio(
                  aspectRatio: 1,
                  child: NwbNetworkImage(url: url),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(block.text, style: nwbAuthorBoxText(context)),
          ],
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({
    required this.categoryId,
    required this.language,
    required this.texts,
  });

  final int? categoryId;
  final AppLanguage language;
  final Translations texts;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(letterSpacing: 0.5);
    final int? id = categoryId;
    return Row(
      children: <Widget>[
        Text(texts['breadcrumb_home'].toUpperCase(), style: style),
        if (id != null)
          TaxonomyName(
            language: language,
            resource: TaxonomyResource.categories,
            id: id,
            builder: (BuildContext context, TaxonomyTerm term) => Flexible(
              child: Text(
                ' / ${term.displayName.toUpperCase()}',
                style: style,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.article,
    required this.language,
    required this.texts,
    required this.authorId,
    required this.categoryId,
  });

  final Article article;
  final AppLanguage language;
  final Translations texts;
  final int? authorId;
  final int? categoryId;

  @override
  Widget build(BuildContext context) {
    final TextStyle accent = nwbMetaAccent(context);
    final TextStyle? muted = Theme.of(context).textTheme.bodySmall;
    final int? author = authorId;
    final int? category = categoryId;

    const BoxConstraints linkHeight = BoxConstraints(
      minHeight: kMinTouchTarget,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (author != null)
          ConstrainedBox(
            constraints: linkHeight,
            child: TaxonomyName(
              language: language,
              resource: TaxonomyResource.authors,
              id: author,
              builder: (BuildContext context, TaxonomyTerm term) => _MetaLink(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TermArticlesScreen(
                      language: language,
                      title: term.name,
                      authorId: author,
                    ),
                  ),
                ),
                label: '${texts['article_author_label']}: ${term.name}'
                    .toUpperCase(),
                style: accent,
              ),
            ),
          ),
        ConstrainedBox(
          constraints: category != null ? linkHeight : const BoxConstraints(),
          child: Row(
            children: <Widget>[
              if (article.publishedAt case final DateTime published)
                Text(formatWarsawDate(published).toUpperCase(), style: muted),
              if (article.publishedAt != null && category != null)
                const SizedBox(width: 8),
              if (category != null)
                TaxonomyName(
                  language: language,
                  resource: TaxonomyResource.categories,
                  id: category,
                  builder: (BuildContext context, TaxonomyTerm term) =>
                      _MetaLink(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TermArticlesScreen(
                              language: language,
                              title: term.displayName,
                              categoryId: category,
                              categorySlug: term.slug,
                            ),
                          ),
                        ),
                        label: term.displayName.toUpperCase(),
                        style: accent,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaLink extends StatelessWidget {
  const _MetaLink({
    required this.onTap,
    required this.label,
    required this.style,
  });

  final VoidCallback onTap;
  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: kMinTouchTarget,
          minWidth: kMinTouchTarget,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          heightFactor: 1,
          child: Text(label, style: style),
        ),
      ),
    );
  }
}

class _TagList extends StatelessWidget {
  const _TagList({required this.tagIds, required this.language});

  final List<int> tagIds;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final int tagId in tagIds)
          TaxonomyName(
            language: language,
            resource: TaxonomyResource.tags,
            id: tagId,
            builder: (BuildContext context, TaxonomyTerm term) => ActionChip(
              label: Text(term.name),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TermArticlesScreen(
                    language: language,
                    title: term.name,
                    tagId: tagId,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
