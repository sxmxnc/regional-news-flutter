import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/translations.dart';
import 'tab_state.dart';

class AreaNavigationBar extends ConsumerWidget {
  const AreaNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int index = ref.watch(selectedTabProvider);
    final Translations texts = ref.watch(translationsProvider);

    // Die Leiste ist weiß wie der Inhalt (Website, Theme) — die Trennlinie
    // darüber setzt sie ab, so wie die Website Flächen durch Linien
    // gliedert, nicht durch Tönung.
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (int value) {
          ref.read(selectedTabProvider.notifier).select(value);
          Navigator.of(context).popUntil((Route<void> route) => route.isFirst);
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: texts['nav_home'],
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view),
            label: texts['nav_categories'],
          ),
          NavigationDestination(
            icon: const Icon(Icons.newspaper_outlined),
            selectedIcon: const Icon(Icons.newspaper),
            label: texts['nav_subscription'],
          ),
          NavigationDestination(
            icon: const Icon(Icons.mail_outline),
            selectedIcon: const Icon(Icons.mail),
            label: texts['nav_contact'],
          ),
        ],
      ),
    );
  }
}
