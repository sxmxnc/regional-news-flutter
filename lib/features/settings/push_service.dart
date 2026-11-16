import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../state/language.dart';
import '../../ui/nav/root_navigator.dart';
import '../../ui/nav/tab_state.dart';
import '../content/article_navigation.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  debugPrint('Push im Hintergrund empfangen: ${message.data}');
}

abstract interface class PushService {
  Future<String?> requestPermissionAndToken();

  void startListening();

  void stopListening();

  Future<void> deleteToken();

  Stream<String> get tokenRefreshes;
}

final class FirebaseMessagingPushService implements PushService {
  FirebaseMessagingPushService(this._ref);

  final Ref _ref;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  @override
  Future<String?> requestPermissionAndToken() async {
    final NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission();
    final bool granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted) return null;
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    return FirebaseMessaging.instance.getToken();
  }

  @override
  void startListening() {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen(
      _handleForeground,
    );
    _openedAppSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
      _openArticleFromMessage,
    );
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
          if (message != null) _openArticleFromMessage(message);
        })
        .catchError((Object error) {
          developer.log(
            'Startnachricht nicht lesbar: $error',
            name: 'FirebaseMessagingPushService',
          );
        });
  }

  @override
  void stopListening() {
    _foregroundSubscription?.cancel();
    _openedAppSubscription?.cancel();
    _foregroundSubscription = null;
    _openedAppSubscription = null;
  }

  @override
  Future<void> deleteToken() async {
    await FirebaseMessaging.instance.setAutoInitEnabled(false);
    await FirebaseMessaging.instance.deleteToken();
  }

  @override
  Stream<String> get tokenRefreshes =>
      FirebaseMessaging.instance.onTokenRefresh;

  void _handleForeground(RemoteMessage message) {
    final BuildContext? context = rootNavigatorKey.currentContext;
    final String? title = message.notification?.title;
    if (context == null || title == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title),
        action: SnackBarAction(
          label: '→',
          onPressed: () => _openArticleFromMessage(message),
        ),
      ),
    );
  }

  void _openArticleFromMessage(RemoteMessage message) {
    final BuildContext? context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final Map<String, dynamic> data = message.data;
    final bool neueAusgabe = switch (data['newNewspaper']) {
      true => true,
      'true' || '1' => true,
      _ => false,
    };
    final int? beitragsId = int.tryParse('${data['post_id'] ?? ''}');
    if (beitragsId != null) {
      final String? sprachcode = switch (data['lang']) {
        final String code when code.isNotEmpty => code,
        _ => null,
      };
      final AppLanguage sprache = _ref.read(languageProvider);
      if (sprachcode == null || sprachcode == sprache.code) {
        openArticle(context, sprache, beitragsId);
        return;
      }
    }
    _ref.read(selectedTabProvider.notifier).select(neueAusgabe ? 2 : 0);
    Navigator.of(context).popUntil((Route<void> route) => route.isFirst);
  }
}

final Provider<PushService> pushServiceProvider = Provider<PushService>(
  (Ref ref) => FirebaseMessagingPushService(ref),
);

/// Local portfolio builds do not register with a messaging project.
final class InactivePushService implements PushService {
  const InactivePushService();

  @override
  Future<String?> requestPermissionAndToken() async => null;
  @override
  void startListening() {}
  @override
  void stopListening() {}
  @override
  Future<void> deleteToken() async {}
  @override
  Stream<String> get tokenRefreshes => const Stream<String>.empty();
}
