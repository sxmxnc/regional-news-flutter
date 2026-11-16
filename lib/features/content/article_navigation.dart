import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../core/failure.dart';
import '../../ui/external_link.dart';
import 'article_link.dart';
import 'article_screen.dart';
import 'content_repository.dart';

/// Öffnet die Beitragsansicht (S-02). Startseite, Suche sowie Rubriken-,
/// Autoren- und Schlagwortlisten rufen sie unverändert auf.
void openArticle(BuildContext context, AppLanguage language, int articleId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ArticleScreen(language: language, articleId: articleId),
    ),
  );
}

Future<void> openContentLink(
  BuildContext context,
  WidgetRef ref,
  String url,
) async {
  if (internalArticleLink(url) case (:final language, :final slug)) {
    final int? id = await _resolveSlug(ref, language, slug);
    if (!context.mounted) return;
    if (id != null) {
      openArticle(context, language, id);
      return;
    }
  }
  if (!context.mounted) return;
  openExternalHtmlLink(url, source: 'ArticleScreen');
}

Future<int?> _resolveSlug(
  WidgetRef ref,
  AppLanguage language,
  String slug,
) async {
  try {
    return await ref
        .read(contentRepositoryProvider(language))
        .resolveSlug(slug);
  } on Failure {
    return null;
  }
}
