import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/account/account_screen.dart';
import '../../features/contact/contact_screen.dart';
import '../../features/content/category_overview_screen.dart';
import '../../features/content/search_screen.dart';
import '../../features/content/start_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../i18n/translations.dart';
import '../brand_logo.dart';
import '../language_flag_button.dart';
import 'area_navigation_bar.dart';
import 'tab_state.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int index = ref.watch(selectedTabProvider);
    final Translations texts = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(),
        actions: <Widget>[
          IconButton(
            tooltip: texts['search_action'],
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
            ),
            icon: const Icon(Icons.search),
          ),
          const LanguageFlagButton(),
          IconButton(
            tooltip: texts['settings_action'],
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: IndexedStack(
        index: index,
        children: const <Widget>[
          StartScreen(),
          CategoryOverviewScreen(),
          AccountScreen(),
          ContactScreen(),
        ],
      ),
      bottomNavigationBar: const AreaNavigationBar(),
    );
  }
}
