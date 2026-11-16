import 'package:flutter_test/flutter_test.dart';
import 'package:regional_news_app/core/time_format.dart';

/// Zeitstempel werden in `Europe/Warsaw` dargestellt, unabhängig von der
/// Gerätezeitzone (README.md, Konventionen). Die Umschaltzeitpunkte sind hier
/// festgehalten, damit die Umrechnung ohne Zeitzonendatenbank prüfbar bleibt.
void main() {
  group('Warschauer Kalendertag für den Zeitraumfilter (ANF-F-27 AK3)', () {
    test('ein gewählter Tag bleibt derselbe Tag, egal wie das Gerät steht', () {
      // Der Datumswähler liefert einen Kalendertag ohne Zeitzone. Beginn und
      // Ende müssen beim Zurückformatieren wieder genau diesen Tag ergeben —
      // sonst zeigt die App einen anderen Tag an als den gewählten.
      final DateTime gewaehlt = DateTime(2026, 9, 16);

      expect(formatWarsawDate(warsawDayStart(gewaehlt)), '16.09.2026');
      expect(formatWarsawDate(warsawDayEnd(gewaehlt)), '16.09.2026');
    });

    test('der Tag umfasst volle 24 Stunden, Ende nach Beginn', () {
      final DateTime tag = DateTime(2026, 9, 16);
      final Duration spanne = warsawDayEnd(tag).difference(warsawDayStart(tag));

      expect(spanne.inHours, 23);
      expect(spanne.inMinutes, 24 * 60 - 1);
    });

    test('Beginn und Ende sind Zeitpunkte in UTC, nicht Gerätezeit', () {
      expect(warsawDayStart(DateTime(2026, 9, 16)).isUtc, isTrue);
      expect(warsawDayEnd(DateTime(2026, 9, 16)).isUtc, isTrue);
    });

    test('im Winterhalbjahr gilt dieselbe Zusicherung (CET statt CEST)', () {
      final DateTime januar = DateTime(2026, 1, 15);
      expect(formatWarsawDate(warsawDayStart(januar)), '15.01.2026');
      expect(formatWarsawDate(warsawDayEnd(januar)), '15.01.2026');
    });

    test('warsawCalendarDay ist die Gegenrichtung', () {
      final DateTime tag = DateTime(2026, 9, 16);
      expect(warsawCalendarDay(warsawDayStart(tag)), tag);
      expect(warsawCalendarDay(warsawDayEnd(tag)), tag);
    });
  });

  test('Winterzeit: UTC+1', () {
    expect(
      toWarsaw(DateTime.utc(2026, 1, 15, 10)),
      DateTime.utc(2026, 1, 15, 11),
    );
  });

  test('Sommerzeit: UTC+2', () {
    expect(
      toWarsaw(DateTime.utc(2026, 7, 1, 10)),
      DateTime.utc(2026, 7, 1, 12),
    );
  });

  test('Umschaltung 2026: letzter Sonntag im März und im Oktober', () {
    expect(isWarsawSummerTime(DateTime.utc(2026, 3, 29, 0, 59)), isFalse);
    expect(isWarsawSummerTime(DateTime.utc(2026, 3, 29, 1)), isTrue);
    expect(isWarsawSummerTime(DateTime.utc(2026, 10, 25, 0, 59)), isTrue);
    expect(isWarsawSummerTime(DateTime.utc(2026, 10, 25, 1)), isFalse);
  });

  test('Umschaltung 2027 fällt auf andere Tage', () {
    expect(isWarsawSummerTime(DateTime.utc(2027, 3, 28, 0, 59)), isFalse);
    expect(isWarsawSummerTime(DateTime.utc(2027, 3, 28, 1)), isTrue);
    expect(isWarsawSummerTime(DateTime.utc(2027, 10, 31, 0, 59)), isTrue);
    expect(isWarsawSummerTime(DateTime.utc(2027, 10, 31, 1)), isFalse);
  });

  test('die Gerätezeitzone ändert das Ergebnis nicht', () {
    // Derselbe Zeitpunkt, einmal als Ortszeit des Geräts ausgedrückt.
    final DateTime instant = DateTime.utc(2026, 7, 1, 21, 30);
    expect(toWarsaw(instant.toLocal()), toWarsaw(instant));
    expect(formatWarsawDate(instant.toLocal()), '01.07.2026');
    expect(formatWarsawTime(instant.toLocal()), '23:30');
  });

  test('ein Beitrag um 23:30 Warschauer Zeit trägt auch dieses Datum', () {
    // 21:30 UTC im Sommer ist 23:30 in Warschau — nicht der Folgetag.
    expect(formatWarsawDate(DateTime.utc(2026, 7, 1, 21, 30)), '01.07.2026');
    // Und 22:30 UTC ist schon der Zweite.
    expect(formatWarsawDate(DateTime.utc(2026, 7, 1, 22, 30)), '02.07.2026');
  });

  test('Hin- und Rückrechnung sind zueinander passend', () {
    final DateTime wall = DateTime.utc(2026, 7, 1, 14);
    expect(toWarsaw(fromWarsawWallClock(wall)), wall);
  });
}
