import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_language.dart';
import '../i18n/translations.dart';
import '../state/language.dart';
import 'theme/app_theme.dart';

class LanguageFlagButton extends ConsumerWidget {
  const LanguageFlagButton({this.target, this.onPressed, super.key});

  /// Sprache, deren Flagge gezeigt wird. Ohne Angabe die jeweils andere als
  /// die aktive.
  final AppLanguage? target;

  /// Ohne Angabe der schlichte Wechsel über [LanguageController.toggle].
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage current = ref.watch(languageProvider);
    final AppLanguage flag =
        target ?? (current == AppLanguage.de ? AppLanguage.pl : AppLanguage.de);
    final Translations texts = ref.watch(translationsProvider);

    // Die Mindestgröße von 48 dp bringt `IconButton` selbst mit
    // (`kMinInteractiveDimension`), README.md, Konventionen.
    return IconButton(
      tooltip: texts['language_switch'],
      onPressed:
          onPressed ?? () => ref.read(languageProvider.notifier).toggle(),
      icon: Text(
        flag == AppLanguage.de ? '🇩🇪' : '🇵🇱',
        style: const TextStyle(fontSize: NwbTypography.flagIcon),
      ),
    );
  }
}
