final class GalleryImage {
  const GalleryImage({
    required this.id,
    required this.url,
    this.name,
    this.description,
    this.width,
    this.height,
  });

  /// Dateikennung in Google Drive — stabil, dient als Widget-Schlüssel.
  final String id;

  /// Adresse des Bildes bei Google (`lh3.googleusercontent.com`).
  ///
  /// **Kurzlebig:** Die Adresse ist signiert und läuft ab; deshalb wird die
  /// Liste nur wenige Minuten vorgehalten (`GalleryKey.freshFor`) statt wie
  /// ein Beitragstext eine Stunde lang.
  final String url;

  /// Dateiname ohne Endung, etwa „post_1_von8". Im Bestand ist das eine
  /// technische Bezeichnung, keine Bildunterschrift — deshalb wird er nicht
  /// angezeigt, sondern dient nur der Fehlersuche.
  final String? name;

  /// Beschreibung aus Google Drive. Im Bestand durchweg leer; ist sie
  /// gefüllt, steht sie als Bildunterschrift unter dem Bild.
  final String? description;

  final int? width;
  final int? height;

  String sized(int edge) => url.contains('=') ? url : '$url=s$edge';

  /// Seitenverhältnis der Originaldatei; `null`, wenn die Antwort keine
  /// brauchbaren Maße trug — dann entscheidet die Ansicht.
  double? get aspectRatio {
    final int? w = width;
    final int? h = height;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    return w / h;
  }
}
