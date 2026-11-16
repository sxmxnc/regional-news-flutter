import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:regional_news_app/core/secure_key_value_store.dart';

/// Die sichere Ablage wird in der Startschranke geladen, vor `runApp`
/// (`lib/app.dart`). Was hier wirft, lässt die App nicht starten.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel kanal = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kanal, null),
  );

  test('liest die abgelegten Werte beim Laden', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kanal, (MethodCall call) async {
          if (call.method == 'readAll') {
            return <String, String>{SecureStoreKeys.authToken: 'abc'};
          }
          return null;
        });

    final SecureKeyValueStore store = await SecureKeyValueStore.load();

    expect(store.getString(SecureStoreKeys.authToken), 'abc');
  });

  test('ist die Ablage unlesbar, startet sie leer statt zu werfen '
      '(ANF-NF-05, E-154)', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kanal, (MethodCall call) async {
          throw PlatformException(code: 'BadPaddingException');
        });

    final SecureKeyValueStore store = await SecureKeyValueStore.load();

    expect(store.getString(SecureStoreKeys.authToken), isNull);
  });
}
