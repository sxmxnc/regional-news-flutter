import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/translations.dart';
import 'nav/tab_state.dart';

class BrandLogo extends ConsumerWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    return Semantics(
      label: texts['app_title'],
      header: true,
      button: true,
      child: InkWell(
        onTap: () {
          ref.read(selectedTabProvider.notifier).select(0);
          Navigator.of(context).popUntil((Route<void> route) => route.isFirst);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ExcludeSemantics(
            child: Text(
              texts['app_title'],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
