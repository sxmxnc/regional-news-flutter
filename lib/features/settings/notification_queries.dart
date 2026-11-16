import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/app_language.dart';
import 'notification.dart';
import 'notification_repository.dart';

final FutureProviderFamily<List<NotificationCategory>, AppLanguage>
notificationCategoriesProvider =
    FutureProvider.family<List<NotificationCategory>, AppLanguage>((
      Ref ref,
      AppLanguage language,
    ) {
      return ref
          .watch(notificationRepositoryProvider(language))
          .getCategories();
    }, isAutoDispose: true);

final NotifierProvider<NotificationOverrides, Map<int, bool>>
notificationOverridesProvider =
    NotifierProvider<NotificationOverrides, Map<int, bool>>(
      NotificationOverrides.new,
    );

final class NotificationOverrides extends Notifier<Map<int, bool>> {
  @override
  Map<int, bool> build() => const <int, bool>{};

  void set(int id, bool subscribed) =>
      state = <int, bool>{...state, id: subscribed};

  void clear(int id) => state = <int, bool>{...state}..remove(id);

  void clearAll() => state = const <int, bool>{};
}
