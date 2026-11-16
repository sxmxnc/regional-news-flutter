import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final FutureProvider<Directory> epaperDirectoryProvider =
    FutureProvider<Directory>((Ref ref) async {
      final Directory support = await getApplicationSupportDirectory();
      return Directory('${support.path}${Platform.pathSeparator}epaper');
    });

/// Rechnet eine Ausgabe auf ihren Zielpfad um und räumt das Verzeichnis.
abstract final class EpaperStore {
  static File fileFor(
    Directory root, {
    required int yearId,
    required Uri href,
  }) {
    final String segment = href.pathSegments.isEmpty
        ? 'ausgabe'
        : href.pathSegments.last;
    String name = segment.replaceAll(_unsafe, '_');
    if (!name.toLowerCase().endsWith('.pdf')) name = '$name.pdf';
    return File(
      '${root.path}${Platform.pathSeparator}$yearId'
      '${Platform.pathSeparator}$name',
    );
  }

  static final RegExp _unsafe = RegExp(r'[^A-Za-z0-9._-]');

  static Future<void> deleteAll(Directory root) async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}
