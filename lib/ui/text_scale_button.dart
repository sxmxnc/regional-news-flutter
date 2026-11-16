import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/translations.dart';
import '../state/settings.dart';
import 'theme/app_theme.dart';

class TextScaleButton extends ConsumerWidget {
  const TextScaleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    return IconButton(
      tooltip: texts['text_size_action'],
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        builder: (_) => const _TextScaleSheet(),
      ),
      icon: const Icon(Icons.text_fields),
    );
  }
}

class _TextScaleSheet extends ConsumerWidget {
  const _TextScaleSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    final NwbTextScale current = ref.watch(
      settingsProvider.select((SettingsState s) => s.textScale),
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              texts['text_size_action'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final NwbTextScale scale in NwbTextScale.values)
            ListTile(
              title: Text(texts['text_size_${scale.code}']),
              trailing: scale == current ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).selectTextScale(scale);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
