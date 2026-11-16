library;

/// Trägt dieser Beitrag bereits ein Bild aus `editorial_fields`? Dann bleibt es
/// unangetastet — der Ersatz greift nur bei dessen Abwesenheit.
bool hasOwnFeaturedImage(Map<String, Object?> post) {
  final Object? fields = post['editorial_fields'];
  if (fields is! Map<String, Object?>) return false;
  final Object? image = fields['featured_image'];
  if (image is! Map<String, Object?>) return false;
  final Object? sizes = image['sizes'];
  return sizes is Map<String, Object?> && sizes.isNotEmpty;
}

/// Die ID aus WordPress' eingebautem `featured_media` — `0` bedeutet „kein
/// Beitragsbild" (WordPress-Konvention) und liefert bewusst `null`.
int? featuredMediaId(Map<String, Object?> post) {
  return switch (post['featured_media']) {
    final int id when id > 0 => id,
    _ => null,
  };
}

List<int> translationIds(Map<String, Object?> post) {
  final Object? root = post['editorial_translations'];
  if (root is! Map<String, Object?>) return const <int>[];
  final Object? entries = root['translations'];
  if (entries is! Map<String, Object?>) return const <int>[];
  return <int>[
    for (final Object? entry in entries.values)
      if (entry case {'id': final int id, 'available': true}) id,
  ];
}

/// Setzt `featured_media` des Beitrags auf die ID der Übersetzung, damit
/// [mergeFallbackImage] unverändert greift.
Map<String, Object?> withFeaturedMediaId(Map<String, Object?> post, int id) =>
    <String, Object?>{...post, 'featured_media': id};

/// Baut aus einem Beitrag und der dazugehörigen `wp/v2/media`-Antwort
/// (`id` → Rohobjekt) dieselbe Form, die der Mapper für
/// `editorial_fields.featured_image` erwartet (`lib/api/mapper/article_mapper.dart`)
/// — der Mapper selbst bleibt unverändert und bevorzugt weiter ein echtes
/// `editorial_fields`, sobald es existiert.
Map<String, Object?> mergeFallbackImage(
  Map<String, Object?> post,
  Map<int, Map<String, Object?>> mediaById,
) {
  if (hasOwnFeaturedImage(post)) return post;
  final int? id = featuredMediaId(post);
  final Map<String, Object?>? media = id == null ? null : mediaById[id];
  if (media == null) return post;

  final Map<String, Object?> details = switch (media['media_details']) {
    final Map<String, Object?> value => value,
    _ => const <String, Object?>{},
  };
  final Map<String, Object?> sizes = switch (details['sizes']) {
    final Map<String, Object?> value => value,
    _ => const <String, Object?>{},
  };
  final Map<String, Map<String, String>> sourceUrls =
      <String, Map<String, String>>{
        for (final MapEntry<String, Object?> entry in sizes.entries)
          if (entry.value case final Map<String, Object?> size)
            if (size['source_url'] case final String url)
              entry.key: <String, String>{'url': url},
      };
  if (sourceUrls.isEmpty) return post;

  final String? renderedCaption = switch (media['caption']) {
    final Map<String, Object?> caption => switch (caption['rendered']) {
      final String rendered => rendered,
      _ => null,
    },
    _ => null,
  };
  final (:String? caption, :String? source) = splitMediaCaption(
    renderedCaption,
  );

  return <String, Object?>{
    ...post,
    'editorial_fields': <String, Object?>{
      'featured_image': <String, Object?>{
        'sizes': sourceUrls,
        'caption': ?caption,
        'source': ?source,
      },
    },
  };
}

final RegExp _paragraphTag = RegExp('</?p[^>]*>', caseSensitive: false);
final RegExp _lineBreakTag = RegExp(r'<br\s*/?>', caseSensitive: false);
final RegExp _anyTag = RegExp('<[^>]+>');
final RegExp _sourcePrefix = RegExp(r'^foto\s*:\s*', caseSensitive: false);

({String? caption, String? source}) splitMediaCaption(String? renderedHtml) {
  if (renderedHtml == null) return (caption: null, source: null);
  final String text = renderedHtml.replaceAll(_paragraphTag, '').trim();
  if (text.isEmpty) return (caption: null, source: null);

  final List<String> lines = text
      .split(_lineBreakTag)
      .map((String line) => line.replaceAll(_anyTag, '').trim())
      .where((String line) => line.isNotEmpty)
      .toList(growable: false);
  if (lines.isEmpty) return (caption: null, source: null);

  int sourceStart = lines.length;
  while (sourceStart > 1 && _sourcePrefix.hasMatch(lines[sourceStart - 1])) {
    sourceStart--;
  }
  if (sourceStart == lines.length) {
    return (caption: lines.join(' '), source: null);
  }
  return (
    caption: lines.sublist(0, sourceStart).join(' '),
    source: lines.last.replaceFirst(_sourcePrefix, '').trim(),
  );
}
