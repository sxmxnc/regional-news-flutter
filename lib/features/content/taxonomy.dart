final class TaxonomyTerm {
  const TaxonomyTerm({
    required this.id,
    required this.name,
    required this.slug,
    this.count,
    this.inMenu,
    this.menuPosition,
    this.menuLabel,
    this.translations = const <String, int>{},
  });

  final int id;
  final String name;

  final String slug;

  /// Anzahl der Beiträge. `null`, wenn die Antwort das Feld nicht enthält.
  final int? count;

  final bool? inMenu;

  /// Platz im Menü, von 1 an. `null`, wenn der Begriff nicht im Menü steht
  /// oder das Feld fehlt. Die Reihenfolge ist die der Website — sie ist
  /// redaktionell gesetzt, nicht alphabetisch und nicht nach Beitragszahl.
  final int? menuPosition;

  final String? menuLabel;

  final Map<String, int> translations;

  /// Was in der Liste steht: die Menübeschriftung, sonst der Kategoriename.
  String get displayName => menuLabel ?? name;
}

abstract final class TaxonomyResource {
  static const String categories = 'categories';
  static const String tags = 'tags';
  static const String authors = 'redaktor';
}
