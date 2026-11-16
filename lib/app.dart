import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'core/app_language.dart';
import 'core/key_value_store.dart';
import 'core/secure_key_value_store.dart';
import 'features/account/account_controller.dart';
import 'features/settings/push_service.dart';
import 'i18n/translations.dart';
import 'state/language.dart';
import 'state/notifications.dart';
import 'state/settings.dart';
import 'ui/nav/app_shell.dart';
import 'ui/nav/root_navigator.dart';
import 'ui/theme/app_theme.dart';

Future<List<Override>> loadStartupOverrides() async {
  final SharedPreferencesStore store = await SharedPreferencesStore.load();
  final SecureKeyValueStore secureStore = await SecureKeyValueStore.load();
  final Map<AppLanguage, Translations> texts = await Translations.loadAll();
  return <Override>[
    keyValueStoreProvider.overrideWithValue(store),
    secureKeyValueStoreProvider.overrideWithValue(secureStore),
    translationBundleProvider.overrideWithValue(texts),
  ];
}

class NwbApp extends ConsumerWidget {
  const NwbApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NwbTextScale scale = ref.watch(
      settingsProvider.select((SettingsState s) => s.textScale),
    );

    final String title = ref.watch(
      translationsProvider.select((Translations t) => t['app_title']),
    );

    final AppLanguage language = ref.watch(languageProvider);

    return MaterialApp(
      title: title,
      theme: buildNwbTheme(scale),
      scrollBehavior: NwbScrollBehavior(),
      locale: Locale(language.code),
      supportedLocales: <Locale>[
        for (final AppLanguage value in AppLanguage.values) Locale(value.code),
      ],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorKey: rootNavigatorKey,
      home: const _PushBootstrap(child: AppShell()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _PushBootstrap extends ConsumerStatefulWidget {
  const _PushBootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_PushBootstrap> createState() => _PushBootstrapState();
}

class _PushBootstrapState extends ConsumerState<_PushBootstrap> {
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid && ref.read(notificationsProvider)) {
      ref.read(pushServiceProvider).startListening();
      ref.read(notificationsProvider.notifier).watchTokenRefresh();
      _gastsitzungWiederherstellen();
    }
  }

  Future<void> _gastsitzungWiederherstellen() async {
    try {
      final String? deviceToken = ref
          .read(secureKeyValueStoreProvider)
          .getString(SecureStoreKeys.fcmDeviceToken);
      if (deviceToken == null) return;
      await ref
          .read(accountControllerProvider(ref.read(languageProvider)))
          .ensureGuestSession(deviceToken: deviceToken);
    } on Object catch (error) {
      developer.log(
        'Gastsitzung nicht wiederhergestellt: $error',
        name: 'PushBootstrap',
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
