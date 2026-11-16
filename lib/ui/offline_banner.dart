import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/query.dart';
import '../core/time_format.dart';
import '../i18n/translations.dart';
import 'theme/app_theme.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({required this.isOffline, super.key});

  final bool isOffline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isOffline) return const SizedBox.shrink();

    final Translations texts = ref.watch(translationsProvider);
    // Der Stand der ganzen App, nicht der einer einzelnen Liste — siehe
    // lastSyncProvider.
    final DateTime? syncedAt = ref.watch(lastSyncProvider);
    final String time = syncedAt == null ? '—' : formatWarsawTime(syncedAt);

    return Container(
      width: double.infinity,
      color: NwbColors.surfaceDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        texts.format('offline_banner', <String, Object?>{'time': time}),
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: NwbColors.onBrand),
      ),
    );
  }
}
