import 'dart:async' show unawaited;
import 'dart:developer' as developer;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_language.dart';
import '../core/key_value_store.dart';

final NotifierProvider<LanguageController, AppLanguage> languageProvider =
    NotifierProvider<LanguageController, AppLanguage>(LanguageController.new);

final class LanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    // Die Ablage ist zu diesem Zeitpunkt geladen — die Startschranke in
    // lib/app.dart hat darauf gewartet (P3(5)). Deshalb ist hier ein
    // unmittelbarer, synchroner Lesevorgang möglich und kein `_init()`,
    // das niemand abwartet.
    final KeyValueStore store = ref.watch(keyValueStoreProvider);
    final AppLanguage? stored = AppLanguage.tryFromCode(
      store.getString(StoreKeys.language),
    );
    if (stored != null) return stored;

    final AppLanguage resolved = AppLanguage.fromDeviceLocale(
      deviceLanguageCode(),
    );
    // Das Ablegen darf [build] nicht aufhalten — der erste Bildaufbau
    // wartet nicht auf die Platte.
    unawaited(_persist(store, resolved));
    return resolved;
  }

  static Future<void> _persist(KeyValueStore store, AppLanguage language) =>
      store.setString(StoreKeys.language, language.code).catchError((
        Object error,
      ) {
        developer.log(
          'Sprache konnte nicht abgelegt werden: $error',
          name: 'LanguageController',
        );
      });

  Future<void> select(AppLanguage language) async {
    if (language == state) return;
    state = language;
    await _persist(ref.read(keyValueStoreProvider), language);
  }

  Future<void> toggle() =>
      select(state == AppLanguage.de ? AppLanguage.pl : AppLanguage.de);
}

/// Sprachcode des Geräts. Ausgelagert, damit der Test die Auflösungsregel
/// ohne Plattformkanal prüfen kann.
String? deviceLanguageCode() => PlatformDispatcher.instance.locale.languageCode;
