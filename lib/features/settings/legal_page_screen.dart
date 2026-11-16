import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../i18n/translations.dart';
import '../../ui/nav/area_navigation_bar.dart';
import 'legal_page.dart';
import 'legal_page_queries.dart';
import 'wp_page_view.dart';

class LegalPageScreen extends ConsumerWidget {
  const LegalPageScreen({
    required this.language,
    required this.slug,
    required this.titleKey,
    super.key,
  });

  final AppLanguage language;
  final String slug;

  /// Übersetzungsschlüssel für die Kopfzeile — bereits bekannt, bevor die
  /// Seite geladen ist, damit die Kopfzeile nicht erst nachträglich springt.
  final String titleKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    final LegalPageKey key = LegalPageKey(language, slug);
    final AsyncValue<LegalPage?> page = ref.watch(legalPageProvider(key));

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(title: Text(texts[titleKey])),
      body: WpPageView(
        page: page,
        onRetry: () => ref.invalidate(legalPageProvider(key)),
        source: 'LegalPageScreen',
      ),
    );
  }
}
