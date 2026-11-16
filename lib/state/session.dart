import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/key_value_store.dart';
import '../core/secure_key_value_store.dart';

final class SessionState {
  const SessionState({this.token, this.isGuest = false});

  const SessionState.anonymous() : this();

  final String? token;

  final bool isGuest;

  bool get isAuthenticated => token != null && !isGuest;
}

final NotifierProvider<SessionController, SessionState> sessionProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

final class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    final KeyValueStore store = ref.watch(secureKeyValueStoreProvider);
    final String? token = store.getString(SecureStoreKeys.authToken);
    if (token == null) return const SessionState.anonymous();
    // Nur Nutzersitzungen werden abgelegt (siehe [SessionState.isGuest]).
    return SessionState(token: token, isGuest: false);
  }

  Future<void> begin({required String token, required bool isGuest}) async {
    state = SessionState(token: token, isGuest: isGuest);
    if (!isGuest) {
      await ref
          .read(secureKeyValueStoreProvider)
          .setString(SecureStoreKeys.authToken, token);
    }
  }

  Future<void> end() async {
    state = const SessionState.anonymous();
    try {
      await ref
          .read(secureKeyValueStoreProvider)
          .remove(SecureStoreKeys.authToken);
    } on Object catch (error) {
      developer.log(
        'Token nicht aus der Ablage gelöscht: $error',
        name: 'SessionController',
      );
    }
  }
}

String generateInstallationId() {
  final Random random = Random.secure();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < 32; i++) {
    buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

/// Liest die abgelegte Installationskennung oder erzeugt und speichert eine
/// neue — **an einer Stelle**, damit nicht mehrere Anmeldeversuche
/// unterschiedliche Kennungen erzeugen.
extension SessionInstallation on Ref {
  Future<String> ensureInstallationId() async {
    final KeyValueStore store = read(secureKeyValueStoreProvider);
    final String? existing = store.getString(SecureStoreKeys.installationId);
    if (existing != null) return existing;
    final String generated = generateInstallationId();
    await store.setString(SecureStoreKeys.installationId, generated);
    return generated;
  }

  Future<String> currentDeviceToken() async {
    final KeyValueStore store = read(secureKeyValueStoreProvider);
    final String? fcmToken = store.getString(SecureStoreKeys.fcmDeviceToken);
    if (fcmToken != null) return fcmToken;
    return ensureInstallationId();
  }
}
