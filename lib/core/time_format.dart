library;

/// Mitteleuropäische Zeit, Winterhalbjahr.
const Duration _cet = Duration(hours: 1);

/// Mitteleuropäische Sommerzeit.
const Duration _cest = Duration(hours: 2);

/// Rechnet [instant] in Warschauer Ortszeit um.
///
/// Das Ergebnis trägt die Kennung `isUtc`, weil Dart keine dritte Möglichkeit
/// kennt — seine Felder (`hour`, `day`, …) sind aber die Warschauer Wanduhr.
/// Deshalb wird es ausschließlich zur **Anzeige** verwendet und nie wieder in
/// eine Rechnung gegeben.
DateTime toWarsaw(DateTime instant) {
  final DateTime utc = instant.toUtc();
  return utc.add(isWarsawSummerTime(utc) ? _cest : _cet);
}

/// Gegenrichtung: deutet [wallClock] als Warschauer Wanduhrzeit und liefert den
/// Zeitpunkt in UTC.
///
/// Nötig, weil WordPress das Feld `date` in der Zeitzone der Website liefert,
/// ohne Kennung. Liegt `date_gmt` vor, ist es vorzuziehen — diese Umrechnung
/// ist der Rückfall. In der einen Umschaltstunde im Oktober ist sie um eine
/// Stunde unsicher; das ist bei einem Veröffentlichungsdatum ohne Belang.
DateTime fromWarsawWallClock(DateTime wallClock) {
  final DateTime asUtc = DateTime.utc(
    wallClock.year,
    wallClock.month,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
    wallClock.second,
  );
  return asUtc.subtract(isWarsawSummerTime(asUtc) ? _cest : _cet);
}

DateTime warsawDayStart(DateTime day) =>
    fromWarsawWallClock(DateTime(day.year, day.month, day.day));

/// Ende desselben Warschauer Kalendertages (23:59:59). Gegenstück zu
/// [warsawDayStart], damit der gewählte letzte Tag vollständig mitzählt.
DateTime warsawDayEnd(DateTime day) =>
    fromWarsawWallClock(DateTime(day.year, day.month, day.day, 23, 59, 59));

/// Der Warschauer Kalendertag zu einem Zeitpunkt, als schlichtes Datum ohne
/// Zeitzonenkennung — für den Datumswähler, der mit Kalendertagen arbeitet.
/// Gegenrichtung zu [warsawDayStart] und [warsawDayEnd].
DateTime warsawCalendarDay(DateTime instant) {
  final DateTime local = toWarsaw(instant);
  return DateTime(local.year, local.month, local.day);
}

/// Tag und Monat als `TT.MM.JJJJ` in Warschauer Zeit.
/// Dieselbe Schreibweise in beiden Sprachen — sie ist in Polen und
/// Deutschland gleich.
String formatWarsawDate(DateTime instant) {
  final DateTime local = toWarsaw(instant);
  return '${_two(local.day)}.${_two(local.month)}.${local.year}';
}

String formatWarsawTime(DateTime instant) {
  final DateTime local = toWarsaw(instant);
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// Gilt zum Zeitpunkt [utc] in Warschau Sommerzeit?
///
/// [utc] muss ein UTC-Zeitpunkt sein; die EU-Regel ist in UTC formuliert,
/// dadurch entfällt die Frage nach der doppelten Stunde in der Umschaltnacht.
bool isWarsawSummerTime(DateTime utc) {
  assert(utc.isUtc, 'Die EU-Regel ist in UTC formuliert.');
  final DateTime start = _lastSundayOfMonth(utc.year, 3).add(_cet);
  final DateTime end = _lastSundayOfMonth(utc.year, 10).add(_cet);
  return !utc.isBefore(start) && utc.isBefore(end);
}

/// Letzter Sonntag des Monats, 00:00 UTC.
DateTime _lastSundayOfMonth(int year, int month) {
  // Tag 0 des Folgemonats ist der letzte Tag des gesuchten Monats.
  final DateTime lastDay = DateTime.utc(year, month + 1, 0);
  // DateTime.weekday: Montag 1 … Sonntag 7.
  return lastDay.subtract(Duration(days: lastDay.weekday % 7));
}

String _two(int value) => value.toString().padLeft(2, '0');
