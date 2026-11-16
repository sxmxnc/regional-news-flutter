final class Article {
  const Article({
    required this.id,
    required this.title,
    this.overline,
    this.excerpt,
    this.content,
    this.publishedAt,
    this.link,
    this.imageUrl,
    this.imageCaption,
    this.imageSource,
    this.imageCaptionText,
    this.categoryIds = const <int>[],
    this.tagIds = const <int>[],
    this.authorIds = const <int>[],
    this.translations = const <String, ArticleTranslation>{},
  });

  final int id;

  /// Nie leer. Fehlt der Titel in der Antwort, entsteht kein [Article].
  final String title;

  final String? overline;

  final String? excerpt;
  final String? content;

  /// Immer ein Zeitpunkt, nie eine Zeichenkette. Dargestellt wird er in
  /// `Europe/Warsaw` (`lib/core/time_format.dart`).
  final DateTime? publishedAt;

  final String? link;

  final String? imageUrl;

  final String? imageCaption;
  final String? imageSource;

  final String? imageCaptionText;

  final List<int> categoryIds;
  final List<int> tagIds;

  final List<int> authorIds;

  /// Aus `editorial_translations`. Leer, wenn das Zusatz-Plugin fehlt.
  final Map<String, ArticleTranslation> translations;

  bool hasTranslation(String languageCode) =>
      translations[languageCode]?.available ?? false;

  int? translationId(String languageCode) {
    final ArticleTranslation? translation = translations[languageCode];
    return (translation?.available ?? false) ? translation?.id : null;
  }

  String? get captionLine {
    if (imageCaptionText case final String text) {
      final List<String> parts = <String>[
        if (text.isNotEmpty) text,
        if (imageSource case final String name when name.isNotEmpty)
          'Foto: $name',
      ];
      return parts.isEmpty ? null : parts.join(' ');
    }
    String? caption = _withoutTrailingSource(imageCaption, imageSource);
    String? source = imageSource;
    if (caption != null && source != null && source.trim().isNotEmpty) {
      final String wanted = source.trim().toLowerCase();
      if (caption.trim().toLowerCase() == wanted) {
        caption = null;
      } else if (caption.split('\n').last.trim().toLowerCase() == wanted) {
        source = null;
      }
    }
    final List<String> parts = <String>[
      if (caption case final String value when value.isNotEmpty) value,
      if (source case final String value when value.isNotEmpty) 'Foto: $value',
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }

  static String? _withoutTrailingSource(String? caption, String? source) {
    if (caption == null || source == null || source.isEmpty) return caption;
    final RegExp trailingSource = RegExp(
      '(?:\\s*foto\\s*:\\s*${RegExp.escape(source)}\\s*)+\$',
      caseSensitive: false,
    );
    return caption.replaceFirst(trailingSource, '').trim();
  }
}

final class ArticleTranslation {
  const ArticleTranslation({required this.available, this.id});

  final bool available;
  final int? id;
}
