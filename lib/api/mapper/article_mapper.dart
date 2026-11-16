import 'dart:developer' as developer;

import '../../core/time_format.dart';
import '../../features/content/article.dart';
import 'json_fields.dart';

abstract final class ArticleMapper {
  /// Bildet eine Liste ab und überspringt unbrauchbare Datensätze.
  static List<Article> fromList(List<Map<String, Object?>> json) {
    final List<Article> articles = <Article>[];
    for (final Map<String, Object?> item in json) {
      final Article? article = fromJson(item);
      if (article != null) articles.add(article);
    }
    return articles;
  }

  /// Bildet einen Beitrag ab. Liefert `null`, wenn `id` oder `title` fehlt.
  static Article? fromJson(Map<String, Object?> json) {
    final int? id = jsonInt(json['id']);
    final String? title = jsonPlainText(json['title']);
    if (id == null || title == null || title.isEmpty) {
      developer.log(
        'Beitrag übersprungen: id oder title fehlt (id=${json['id']})',
        name: 'ArticleMapper',
      );
      return null;
    }

    final Map<String, Object?> fields = jsonMap(json['editorial_fields']);
    final Map<String, Object?> acf = jsonMap(fields['acf']);
    final Map<String, Object?> image = jsonMap(fields['featured_image']);

    return Article(
      id: id,
      title: title,
      overline: jsonPlainText(jsonString(acf['post_podtytul'])),
      excerpt: jsonRendered(json['excerpt']),
      content: jsonRendered(json['content']),
      publishedAt: _publishedAt(json),
      link: jsonString(json['link']),
      imageUrl: _imageUrl(image),
      imageCaption: jsonPlainText(jsonString(image['caption'])),
      imageSource: jsonPlainText(jsonString(image['source'])),
      imageCaptionText: image.containsKey('caption_text')
          ? jsonPlainText(image['caption_text']) ?? ''
          : null,
      categoryIds: jsonIntList(json['categories']),
      tagIds: jsonIntList(json['tags']),
      authorIds: jsonIntList(json['redaktor']),
      translations: _translations(json['editorial_translations']),
    );
  }

  static String? _imageUrl(Map<String, Object?> image) {
    final Map<String, Object?> sizes = jsonMap(image['sizes']);
    for (final String size in <String>[
      'large',
      'medium',
      'full',
      'thumbnail',
    ]) {
      final String? url = jsonString(jsonMap(sizes[size])['url']);
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  /// `date_gmt` ist der Zeitpunkt in UTC und damit die erste Wahl. `date`
  /// steht in der Zeitzone der Website und wird als Warschauer Wanduhrzeit
  /// gedeutet.
  static DateTime? _publishedAt(Map<String, Object?> json) {
    final String? gmt = jsonString(json['date_gmt']);
    if (gmt != null) {
      final DateTime? parsed = _parseUtc(gmt);
      if (parsed != null) return parsed;
    }
    final String? local = jsonString(json['date']);
    if (local != null) {
      final DateTime? parsed = DateTime.tryParse(local);
      if (parsed != null) return fromWarsawWallClock(parsed);
    }
    return null;
  }

  /// WordPress liefert `date_gmt` **ohne** Zeitzonenkennung, obwohl der Wert in
  /// UTC steht. Trägt die Zeichenkette wider Erwarten doch eine Kennung, deutet
  /// Dart sie selbst — dann wird nichts angehängt. Andernfalls würde aus einem
  /// gültigen Zeitstempel durch das angehängte `Z` eine unlesbare Zeichenkette,
  /// und das Datum fiele stillschweigend auf `date` zurück.
  static DateTime? _parseUtc(String raw) {
    final DateTime? asWritten = DateTime.tryParse(raw);
    if (asWritten != null && asWritten.isUtc) return asWritten;
    return DateTime.tryParse('${raw}Z');
  }

  static Map<String, ArticleTranslation> _translations(Object? value) {
    final Map<String, Object?> root = jsonMap(value);
    final Map<String, Object?> entries = jsonMap(root['translations']);
    final Map<String, ArticleTranslation> result =
        <String, ArticleTranslation>{};
    entries.forEach((String code, Object? entry) {
      final Map<String, Object?> map = jsonMap(entry);
      if (map.isEmpty) return;
      result[code] = ArticleTranslation(
        available: map['available'] == true,
        id: jsonInt(map['id']),
      );
    });
    return result;
  }
}
