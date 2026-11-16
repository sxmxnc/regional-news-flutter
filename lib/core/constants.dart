abstract final class Timeouts {
  static const Duration request = Duration(seconds: 20);

  static const Duration download = Duration(minutes: 3);

  static const Duration availability = Duration(seconds: 8);
}

abstract final class CachePolicy {
  /// Listen (Startseite, Rubriken, Suche).
  static const Duration list = Duration(minutes: 5);

  /// Einzelner Beitrag. Ein veröffentlichter Text ändert sich selten.
  static const Duration article = Duration(minutes: 60);

  /// Stammdaten, die sich fast nie ändern (Kategorien, Autoren, Schlagworte).
  static const Duration taxonomy = Duration(hours: 24);
}
