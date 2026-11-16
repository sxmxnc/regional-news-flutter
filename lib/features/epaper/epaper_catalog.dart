import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'epaper_issue.dart';
import 'epaper_year.dart';

abstract final class EpaperCatalog {
  static const String _yearsFile = 'katalog-jahrgaenge.json';

  static File _issuesFile(Directory root, int yearId) => File(
    '${root.path}${Platform.pathSeparator}katalog-ausgaben-$yearId.json',
  );

  static File _years(Directory root) =>
      File('${root.path}${Platform.pathSeparator}$_yearsFile');

  /// Schreibt den Stand. Ein Fehler beim Schreiben ist **kein** Grund, den
  /// Abruf scheitern zu lassen — die Liste steht bereits auf dem Bildschirm.
  static Future<void> saveYears(Directory root, List<EpaperYear> years) async {
    await _write(_years(root), <Object?>[
      for (final EpaperYear year in years)
        <String, Object?>{'id': year.id, 'title': year.title},
    ]);
  }

  static Future<void> saveIssues(
    Directory root,
    int yearId,
    List<EpaperIssue> issues,
  ) async {
    await _write(_issuesFile(root, yearId), <Object?>[
      for (final EpaperIssue issue in issues)
        <String, Object?>{'title': issue.title, 'href': issue.href?.toString()},
    ]);
  }

  /// Der gespiegelte Stand, oder `null`, wenn keiner vorliegt oder er
  /// unlesbar ist. Unlesbar wird wie „nicht vorhanden" behandelt: Der
  /// Aufrufer meldet dann den ursprünglichen Verbindungsfehler.
  static Future<List<EpaperYear>?> loadYears(Directory root) async {
    final List<Object?>? raw = await _read(_years(root));
    if (raw == null) return null;
    final List<EpaperYear> result = <EpaperYear>[];
    for (final Object? entry in raw) {
      if (entry is! Map<String, Object?>) continue;
      final Object? id = entry['id'];
      final Object? title = entry['title'];
      if (id is! int || title is! String) continue;
      result.add(EpaperYear(id: id, title: title));
    }
    return result.isEmpty ? null : result;
  }

  static Future<List<EpaperIssue>?> loadIssues(
    Directory root,
    int yearId,
  ) async {
    final List<Object?>? raw = await _read(_issuesFile(root, yearId));
    if (raw == null) return null;
    final List<EpaperIssue> result = <EpaperIssue>[];
    for (final Object? entry in raw) {
      if (entry is! Map<String, Object?>) continue;
      final Object? title = entry['title'];
      if (title is! String) continue;
      final Object? href = entry['href'];
      result.add(
        EpaperIssue(
          title: title,
          href: href is String ? Uri.tryParse(href) : null,
        ),
      );
    }
    return result.isEmpty ? null : result;
  }

  static Future<void> _write(File file, List<Object?> value) async {
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(value));
    } on Object catch (error) {
      // Absichtlich kein Wurf: siehe [saveYears]. Protokolliert, damit ein
      // dauerhaft scheiterndes Schreiben bei der Fehlersuche auffällt.
      developer.log(
        'Katalog nicht geschrieben (${file.path}): $error',
        name: 'EpaperCatalog',
      );
    }
  }

  static Future<List<Object?>?> _read(File file) async {
    try {
      if (!await file.exists()) return null;
      final Object? decoded = jsonDecode(await file.readAsString());
      return decoded is List<Object?> ? decoded : null;
    } on Object catch (error) {
      developer.log(
        'Katalog nicht lesbar (${file.path}): $error',
        name: 'EpaperCatalog',
      );
      return null;
    }
  }
}
