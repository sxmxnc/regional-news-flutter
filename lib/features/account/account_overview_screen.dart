import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../core/failure.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../ui/async_view.dart';
import '../../ui/error_view.dart';
import '../../ui/offline_banner.dart';
import '../epaper/epaper_screen.dart';
import '../subscription/subscription_section.dart';
import 'account_queries.dart';
import 'user_profile.dart';

class AccountOverviewScreen extends ConsumerWidget {
  const AccountOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    final AppLanguage language = ref.watch(languageProvider);
    final CurrentUserKey key = CurrentUserKey(language);
    final AsyncValue<UserProfile?> profile = ref.watch(
      currentUserProvider(key),
    );
    final bool isOffline = isOfflineWithContent(profile);

    return Column(
      children: <Widget>[
        OfflineBanner(isOffline: isOffline),
        Expanded(
          child: nwbAsyncView<UserProfile?>(
            profile,
            onRetry: () => ref.invalidate(currentUserProvider(key)),
            error: (Object error) => _OfflineOverview(
              error: error,
              onRetry: () => ref.invalidate(currentUserProvider(key)),
            ),
            data: (UserProfile? value) => switch (value) {
              null => ErrorView(
                error: const ContentFailure(),
                onRetry: () => ref.invalidate(currentUserProvider(key)),
              ),
              final UserProfile user => ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Text(
                    '${user.firstName} ${user.lastName}'.trim(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(user.email),
                  const SizedBox(height: 2),
                  Text(
                    '${texts['account_overview_username_label']}: '
                    '${user.username}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  SubscriptionSection(status: user.subscription),
                ],
              ),
            },
          ),
        ),
      ],
    );
  }
}

class _OfflineOverview extends ConsumerWidget {
  const _OfflineOverview({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: <Widget>[
        ErrorView(error: error, onRetry: onRetry),
        const SizedBox(height: 8),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.menu_book_outlined),
          title: Text(texts['subscription_epaper_action']),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const EpaperScreen())),
        ),
      ],
    );
  }
}
