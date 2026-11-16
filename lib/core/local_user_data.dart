import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/epaper/epaper_download_controller.dart';
import '../features/epaper/epaper_store.dart';

Future<void> clearLocalUserData(Ref ref) async {
  try {
    final Directory root = await ref.read(epaperDirectoryProvider.future);
    await EpaperStore.deleteAll(root);
  } on Object catch (error) {
    // Absichtlich nicht weitergereicht — siehe Dokumentation oben.
    developer.log(
      'E-Paper-Verzeichnis nicht geräumt: $error',
      name: 'clearLocalUserData',
    );
  }
  ref.invalidate(epaperDownloadProvider);
}
