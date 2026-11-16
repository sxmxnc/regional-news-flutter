import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../../core/app_language.dart';
import 'notification.dart';
import 'notification_queries.dart';
import 'notification_repository.dart';

final class NotificationCategoriesController {
  const NotificationCategoriesController(this._ref, this._language);

  final Ref _ref;
  final AppLanguage _language;

  NotificationRepository get _repository =>
      _ref.read(notificationRepositoryProvider(_language));

  Future<void> toggle(NotificationCategory category) async {
    final bool next = !category.subscribed;
    final NotificationOverrides overrides = _ref.read(
      notificationOverridesProvider.notifier,
    );
    overrides.set(category.id, next);
    try {
      await _repository.setCategory(id: category.id, subscribed: next);
    } on Object {
      overrides.clear(category.id);
      _ref.invalidate(notificationCategoriesProvider(_language));
      rethrow;
    }
  }

  Future<void> setAll(List<NotificationCategory> categories, bool value) async {
    final NotificationOverrides overrides = _ref.read(
      notificationOverridesProvider.notifier,
    );
    final List<NotificationCategory> betroffen = categories
        .where((NotificationCategory c) => c.subscribed != value)
        .toList();
    for (final NotificationCategory category in betroffen) {
      overrides.set(category.id, value);
    }
    try {
      for (final NotificationCategory category in betroffen) {
        await _repository.setCategory(id: category.id, subscribed: value);
      }
    } on Object {
      overrides.clearAll();
      _ref.invalidate(notificationCategoriesProvider(_language));
      rethrow;
    }
  }
}

final ProviderFamily<NotificationCategoriesController, AppLanguage>
notificationCategoriesControllerProvider =
    Provider.family<NotificationCategoriesController, AppLanguage>((
      Ref ref,
      AppLanguage language,
    ) {
      return NotificationCategoriesController(ref, language);
    });
