import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../core/failure.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../state/notifications.dart';
import '../../ui/loading_view.dart';
import '../../ui/nav/area_navigation_bar.dart';
import 'notification.dart';
import 'notification_controller.dart';
import 'notification_queries.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    Translations texts,
    AppLanguage language,
    bool value,
  ) async {
    try {
      if (!value) {
        await ref.read(notificationsProvider.notifier).disable();
        return;
      }
      final bool granted = await ref
          .read(notificationsProvider.notifier)
          .enable(language);
      if (!granted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(texts['settings_notifications_permission_denied']),
          ),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts[failureMessageKey(error)])));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    final AppLanguage language = ref.watch(languageProvider);
    final bool enabled = ref.watch(notificationsProvider);

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(title: Text(texts['settings_section_notifications'])),
      body: ListView(
        children: <Widget>[
          SwitchListTile(
            title: Text(texts['settings_notifications_label']),
            subtitle: Text(texts['settings_notifications_hint']),
            value: enabled,
            onChanged: (bool value) =>
                _setEnabled(context, ref, texts, language, value),
          ),
          if (enabled) ...<Widget>[
            const Divider(height: 1),
            _NotificationCategoriesSection(language: language, texts: texts),
          ],
        ],
      ),
    );
  }
}

class _NotificationCategoriesSection extends ConsumerWidget {
  const _NotificationCategoriesSection({
    required this.language,
    required this.texts,
  });

  final AppLanguage language;
  final Translations texts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<NotificationCategory>> categories = ref.watch(
      notificationCategoriesProvider(language),
    );
    final Map<int, bool> overrides = ref.watch(notificationOverridesProvider);

    return categories.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LoadingPlaceholderRow(),
      ),
      error: (Object error, StackTrace _) {
        final bool loginRequired =
            error is ServerFailure && error.statusCode == 403;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            texts[loginRequired
                ? 'settings_notifications_login_required'
                : failureMessageKey(error)],
          ),
        );
      },
      data: (List<NotificationCategory> geladen) {
        if (geladen.isEmpty) return const SizedBox.shrink();
        final List<NotificationCategory> list = geladen.map((
          NotificationCategory c,
        ) {
          final bool? wert = overrides[c.id];
          return wert == null ? c : c.copyWith(subscribed: wert);
        }).toList();
        final NotificationCategoriesController controller = ref.read(
          notificationCategoriesControllerProvider(language),
        );
        final bool allSubscribed = list.every(
          (NotificationCategory c) => c.subscribed,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                texts['settings_notifications_categories_heading']
                    .toUpperCase(),
              ),
            ),
            SwitchListTile(
              title: Text(texts['settings_notifications_categories_all']),
              value: allSubscribed,
              onChanged: (bool value) =>
                  _logFailure(controller.setAll(list, value)),
            ),
            for (final NotificationCategory category in list)
              SwitchListTile(
                title: Text(
                  category.isEpaper
                      ? texts['settings_notifications_categories_epaper']
                      : category.title,
                ),
                value: category.subscribed,
                onChanged: (bool _) => _logFailure(controller.toggle(category)),
              ),
          ],
        );
      },
    );
  }

  static void _logFailure(Future<void> call) {
    call.catchError((Object error) {
      developer.log(
        'Rubrik-Abo nicht gespeichert: $error',
        name: 'NotificationSettingsScreen',
      );
    });
  }
}
