library;

/// Zeichenkette ohne Rand-Leerraum; leer oder ein anderer Typ gilt als
/// nicht vorhanden.
String? jsonString(Object? value) => switch (value) {
  final String text when text.trim().isNotEmpty => text.trim(),
  _ => null,
};

/// Ganze Zahl — als `int`, als `double` (JSON kennt nur „Zahl"; ein
/// Bruchteil wird abgeschnitten) oder als Zifferntext (`"12"`).
int? jsonInt(Object? value) => switch (value) {
  final int number => number,
  final double number => number.toInt(),
  final String text => int.tryParse(text.trim()),
  _ => null,
};

/// Objekt; alles andere ergibt ein leeres Objekt, damit verschachteltes
/// Lesen (`jsonMap(jsonMap(json['a'])['b'])`) ohne Nullprüfung auskommt.
Map<String, Object?> jsonMap(Object? value) =>
    value is Map<String, Object?> ? value : const <String, Object?>{};

/// Objekt oder `null` — wo der Aufrufer zwischen „fehlt" und „leer"
/// unterscheiden muss, etwa beim `subscription`-Block aus `GET /user`.
Map<String, Object?>? jsonMapOrNull(Object? value) =>
    value is Map<String, Object?> ? value : null;

/// Liste; alles andere ergibt eine leere Liste.
List<Object?> jsonList(Object? value) => switch (value) {
  final List<Object?> list => list,
  _ => const <Object?>[],
};

/// Liste ganzer Zahlen, unbrauchbare Einträge übersprungen.
List<int> jsonIntList(Object? value) =>
    jsonList(value).map(jsonInt).whereType<int>().toList(growable: false);

/// WordPress liefert Texte als `{ "rendered": "…" }`, manche Felder auch
/// unmittelbar als Zeichenkette. Beides wird angenommen; Leerraum am Rand
/// fällt weg, ein leerer Text gilt als nicht vorhanden.
String? jsonRendered(Object? value) => switch (value) {
  final String text => text.trim().isEmpty ? null : text.trim(),
  final Map<String, Object?> map => jsonRendered(map['rendered']),
  _ => null,
};

String? jsonPlainText(Object? value) {
  final String? text = jsonRendered(value);
  return text == null ? null : decodeHtmlEntities(text);
}

final RegExp _entity = RegExp(r'&(#[xX]?[0-9a-fA-F]+|[a-zA-Z]+);');

/// Die Entitäten, die im Bestand tatsächlich vorkommen — Gedankenstriche,
/// typografische Anführungszeichen, kaufmännisches Und. Keine vollständige
/// HTML-Tabelle: Was nicht getroffen wird, bleibt unverändert stehen und ist
/// damit sichtbar statt still falsch.
///
/// Unsichtbare Zeichen stehen als Fluchtfolge da, nicht als Zeichen: Ein
/// geschütztes Leerzeichen im Quelltext ist von einem gewöhnlichen nicht zu
/// unterscheiden.
const Map<String, String> _namedEntities = <String, String>{
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': '\u00A0',
  'shy': '\u00AD',
  'ndash': '–',
  'mdash': '—',
  'hellip': '…',
  'laquo': '«',
  'raquo': '»',
  'bdquo': '„',
  'ldquo': '“',
  'rdquo': '”',
  'sbquo': '‚',
  'lsquo': '‘',
  'rsquo': '’',
  'euro': '€',
  'deg': '°',
};

String decodeHtmlEntities(String text) {
  if (!text.contains('&')) return text;
  return text.replaceAllMapped(_entity, (Match match) {
    final String body = match.group(1)!;
    final String whole = match.group(0)!;
    if (!body.startsWith('#')) return _namedEntities[body] ?? whole;

    final bool hex = body.length > 1 && (body[1] == 'x' || body[1] == 'X');
    final int? code = int.tryParse(
      body.substring(hex ? 2 : 1),
      radix: hex ? 16 : 10,
    );
    if (code == null || code <= 0 || code > 0x10FFFF) return whole;
    return String.fromCharCode(code);
  });
}
