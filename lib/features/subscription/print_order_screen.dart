import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../ui/nav/area_navigation_bar.dart';
import '../settings/legal_page.dart';
import '../settings/legal_page_queries.dart';
import '../settings/wp_page_view.dart';
import 'print_order_config.dart';
import 'print_order_form_screen.dart';

class PrintOrderScreen extends ConsumerWidget {
  const PrintOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    final AppLanguage language = ref.watch(languageProvider);
    final LegalPageKey key = LegalPageKey(
      language,
      PrintOrderSlugs.page(language),
    );
    final AsyncValue<LegalPage?> page = ref.watch(legalPageProvider(key));

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(title: Text(texts['print_order_title'])),
      body: WpPageView(
        page: page,
        onRetry: () => ref.invalidate(legalPageProvider(key)),
        source: 'PrintOrderScreen',
        action: FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PrintOrderFormScreen(),
            ),
          ),
          child: Text(texts['print_order_order_action']),
        ),
      ),
    );
  }
}
