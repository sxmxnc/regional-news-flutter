import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Prüfung (a) aus dem Arbeitsplan: **Beide Sprachdateien haben dieselben
/// Schlüssel.**
///
/// Gelesen wird von der Platte, nicht über das Paketbündel — dieser Test soll
/// auch dann greifen, wenn jemand vergisst, eine neue Datei in `pubspec.yaml`
/// einzutragen.
void main() {
  late Map<String, Object?> de;
  late Map<String, Object?> pl;

  setUpAll(() {
    de = _read('lib/i18n/de.json');
    pl = _read('lib/i18n/pl.json');
  });

  test('de.json und pl.json haben genau dieselben Schlüssel', () {
    expect(
      pl.keys.toSet().difference(de.keys.toSet()),
      isEmpty,
      reason: 'Schlüssel fehlen in de.json',
    );
    expect(
      de.keys.toSet().difference(pl.keys.toSet()),
      isEmpty,
      reason: 'Schlüssel fehlen in pl.json',
    );
  });

  test('kein Text ist leer', () {
    for (final Map<String, Object?> file in <Map<String, Object?>>[de, pl]) {
      for (final MapEntry<String, Object?> entry in file.entries) {
        expect(
          '${entry.value}'.trim(),
          isNotEmpty,
          reason: 'Leerer Text bei "${entry.key}"',
        );
      }
    }
  });

  test('gleiche Platzhalter in beiden Sprachen', () {
    final RegExp placeholder = RegExp(r'\{(\w+)\}');
    for (final String key in de.keys) {
      Set<String> names(Map<String, Object?> file) => placeholder
          .allMatches('${file[key]}')
          .map((RegExpMatch match) => match.group(1)!)
          .toSet();
      expect(
        names(de),
        equals(names(pl)),
        reason: 'Unterschiedliche Platzhalter bei "$key"',
      );
    }
  });

  test('jede Fehlerklasse hat einen Text', () {
    for (final String key in <String>[
      'error_connection',
      'error_server',
      'error_content',
      'retry',
    ]) {
      expect(de.containsKey(key), isTrue, reason: '$key fehlt in de.json');
      expect(pl.containsKey(key), isTrue, reason: '$key fehlt in pl.json');
    }
  });
}

Map<String, Object?> _read(String path) {
  final File file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path fehlt');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}
