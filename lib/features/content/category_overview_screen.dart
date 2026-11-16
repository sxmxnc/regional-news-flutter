import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../core/failure.dart';
import '../../core/query.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../ui/async_view.dart';
import '../../ui/empty_view.dart';
import '../../ui/offline_banner.dart';
import 'article_filter_sheet.dart';
import 'taxonomy.dart';
import 'taxonomy_queries.dart';
import 'term_articles_screen.dart';

class CategoryOverviewScreen extends ConsumerWidget {
  const CategoryOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage language = ref.watch(languageProvider);
    final Translations texts = ref.watch(translationsProvider);
    final MenuCategoryKey key = MenuCategoryKey(language);
    final AsyncValue<List<TaxonomyTerm>> categories = ref.watch(
      menuCategoryListProvider(key),
    );

    final bool isOffline = isOfflineWithContent(categories);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFilter(context, ref, language, texts),
        icon: const Icon(Icons.filter_alt_outlined),
        label: Text(texts['filter_action']),
      ),
      body: Column(
        children: <Widget>[
          OfflineBanner(isOffline: isOffline),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.requestNetworkRefresh(<QueryKey>[key]);
                ref.invalidate(menuCategoryListProvider(key));
                try {
                  await ref.read(menuCategoryListProvider(key).future);
                } on Failure {
                  // Absichtlich ohne Folge — siehe oben.
                }
              },
              child: nwbAsyncView<List<TaxonomyTerm>>(
                categories,
                onRetry: () => ref.invalidate(menuCategoryListProvider(key)),
                data: (List<TaxonomyTerm> terms) {
                  if (terms.isEmpty) {
                    return EmptyListView(message: texts['empty_list']);
                  }
                  return ListView.separated(
                    itemCount: terms.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final TaxonomyTerm term = terms[index];
                      return ListTile(
                        title: Text(term.displayName),
                        trailing: term.count == null
                            ? null
                            : Text('${term.count}'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TermArticlesScreen(
                              language: language,
                              title: term.displayName,
                              categoryId: term.id,
                              categorySlug: term.slug,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilter(
    BuildContext context,
    WidgetRef ref,
    AppLanguage language,
    Translations texts,
  ) async {
    final ArticleFilter? result = await showArticleFilterSheet(
      context,
      language: language,
    );
    if (result == null || result.isEmpty || !context.mounted) return;

    final String heading = result.label.isEmpty
        ? texts['filter_results_title']
        : result.label;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TermArticlesScreen(
          language: language,
          title: heading,
          categoryId: result.categoryId,
          categorySlug: result.categorySlug,
          authorId: result.authorId,
          dateFrom: result.dateFrom,
          dateTo: result.dateTo,
        ),
      ),
    );
  }
}
