# Regional News Demo

Portfoliofassung der von Simon Cebula für die zweisprachige Regionalzeitung
**Neues Wochenblatt** entwickelten Flutter-App für Android und iOS.

Die Demo verwendet fiktive Artikel auf Deutsch und Polnisch. Sie zeigt
Startseite, Rubriken, Suche, Artikeldetails und Sprachwechsel. Ein lokaler
HTTP-Client liefert Beispieldaten an dieselben Parser und Repositories wie
eine externe Schnittstelle. Konto, E-Paper, Abos und Benachrichtigungen
sind im Code als Funktionsbereiche erkennbar. In der Demo gibt es keine
echten Ausgaben, Konten, Zahlungen oder Push-Nachrichten.

## Lokal starten

Mit Flutter 3.47 und einem Android-Emulator oder iOS-Simulator:

```sh
flutter pub get
flutter run
```

`flutter analyze` prüft den Quellcode und `flutter test` führt die Tests aus.
