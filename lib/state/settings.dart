import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/key_value_store.dart';
import '../ui/theme/app_theme.dart';

/// Einstellungen, die die Darstellung betreffen. Die Sprache gehört
/// **nicht** hierher — sie hat ihre eigene, einzige Quelle
/// (`lib/state/language.dart`, Regel 3).
final class SettingsState {
  const SettingsState({this.textScale = NwbTextScale.normal});

  final NwbTextScale textScale;

  SettingsState copyWith({NwbTextScale? textScale}) =>
      SettingsState(textScale: textScale ?? this.textScale);
}

final NotifierProvider<SettingsController, SettingsState> settingsProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

final class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    // Wie bei der Sprache: Die Ablage ist geladen, bevor der erste Bildaufbau
    // läuft (Startschranke in lib/app.dart).
    final KeyValueStore store = ref.watch(keyValueStoreProvider);
    return SettingsState(
      textScale:
          NwbTextScale.tryFromCode(store.getString(StoreKeys.textScale)) ??
          NwbTextScale.normal,
    );
  }

  Future<void> selectTextScale(NwbTextScale scale) async {
    if (scale == state.textScale) return;
    state = state.copyWith(textScale: scale);
    try {
      await ref
          .read(keyValueStoreProvider)
          .setString(StoreKeys.textScale, scale.code);
    } on Object catch (error) {
      developer.log(
        'Schriftgröße konnte nicht abgelegt werden: $error',
        name: 'SettingsController',
      );
    }
  }
}
