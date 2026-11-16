import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'api/http_client.dart';
import 'app.dart';
import 'config/app_config.dart';
import 'core/query.dart';
import 'demo/editorial_demo_client.dart';
import 'features/settings/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final List<Override> startup = await loadStartupOverrides();
  runApp(
    ProviderScope(
      overrides: [
        ...startup,
        pushServiceProvider.overrideWithValue(const InactivePushService()),
        if (AppConfig.usesDemoData)
          httpClientProvider.overrideWith((Ref ref) {
            final EditorialDemoClient client = EditorialDemoClient();
            ref.onDispose(client.close);
            return client;
          }),
      ],
      retry: nwbRetry,
      child: const NwbApp(),
    ),
  );
}
