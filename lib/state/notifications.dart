import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_language.dart';
import '../core/key_value_store.dart';
import '../core/secure_key_value_store.dart';
import '../features/account/account_controller.dart';
import '../features/settings/notification.dart';
import '../features/settings/notification_queries.dart';
import '../features/settings/notification_repository.dart';
import '../features/settings/push_service.dart';
import 'language.dart';
import 'session.dart';

final NotifierProvider<NotificationsController, bool> notificationsProvider =
    NotifierProvider<NotificationsController, bool>(
      NotificationsController.new,
    );

final class NotificationsController extends Notifier<bool> {
  StreamSubscription<String>? _tokenRefreshes;

  @override
  bool build() {
    ref.onDispose(() {
      _tokenRefreshes?.cancel();
      _tokenRefreshes = null;
    });
    // Wie bei Sprache und Schriftgröße: Die Ablage ist geladen, bevor der
    // erste Bildaufbau läuft (Startschranke in lib/app.dart).
    final KeyValueStore store = ref.watch(keyValueStoreProvider);
    return store.getString(StoreKeys.notificationsEnabled) == '1';
  }

  /// Beginnt, auf neue FCM-Tokens zu hören — beim Einschalten ([enable])
  /// und beim Start mit bereits eingeschaltetem Push (`lib/app.dart`).
  /// Ein zweiter Aufruf bleibt wirkungslos.
  void watchTokenRefresh() {
    _tokenRefreshes ??= ref
        .read(pushServiceProvider)
        .tokenRefreshes
        .listen(
          (String token) => unawaited(
            _onTokenRefresh(token).catchError((Object error) {
              // Ohne Netz bleibt der neue Token wenigstens abgelegt; der
              // nächste Start eröffnet die Gastsitzung damit
              // (`_gastsitzungWiederherstellen`, lib/app.dart).
              developer.log(
                'Neuer FCM-Token nicht gemeldet: $error',
                name: 'NotificationsController',
              );
            }),
          ),
        );
  }

  Future<void> _onTokenRefresh(String token) async {
    final KeyValueStore secure = ref.read(secureKeyValueStoreProvider);
    if (!state) return;
    if (secure.getString(SecureStoreKeys.fcmDeviceToken) == token) return;
    await secure.setString(SecureStoreKeys.fcmDeviceToken, token);
    if (ref.read(sessionProvider).isAuthenticated) return;

    final AppLanguage language = ref.read(languageProvider);
    List<NotificationCategory> bisher = const <NotificationCategory>[];
    if (ref.read(sessionProvider).token != null) {
      try {
        bisher = await ref
            .read(notificationRepositoryProvider(language))
            .getCategories();
      } on Object catch (error) {
        developer.log(
          'Rubrik-Abos vor dem Tokenwechsel nicht lesbar: $error',
          name: 'NotificationsController',
        );
      }
    }
    await ref
        .read(accountControllerProvider(language))
        .renewGuestSession(deviceToken: token);
    final NotificationRepository neu = ref.read(
      notificationRepositoryProvider(language),
    );
    for (final NotificationCategory category in bisher) {
      if (category.subscribed) {
        await neu.setCategory(id: category.id, subscribed: true);
      }
    }
    ref.invalidate(notificationCategoriesProvider(language));
  }

  Future<bool> enable(AppLanguage language) async {
    final PushService push = ref.read(pushServiceProvider);
    final String? token = await push.requestPermissionAndToken();
    if (token == null) return false;

    await ref
        .read(secureKeyValueStoreProvider)
        .setString(SecureStoreKeys.fcmDeviceToken, token);
    await ref
        .read(accountControllerProvider(language))
        .ensureGuestSession(deviceToken: token);
    push.startListening();

    state = true;
    watchTokenRefresh();
    await ref
        .read(keyValueStoreProvider)
        .setString(StoreKeys.notificationsEnabled, '1');
    return true;
  }

  Future<void> disable() async {
    final PushService push = ref.read(pushServiceProvider);
    push.stopListening();
    await _tokenRefreshes?.cancel();
    _tokenRefreshes = null;
    await push.deleteToken();
    await ref
        .read(secureKeyValueStoreProvider)
        .remove(SecureStoreKeys.fcmDeviceToken);

    state = false;
    await ref
        .read(keyValueStoreProvider)
        .setString(StoreKeys.notificationsEnabled, '0');
  }
}
