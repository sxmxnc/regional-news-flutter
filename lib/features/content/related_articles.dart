import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parseFragment;

String nodeHtml(dom.Node node) =>
    (dom.DocumentFragment()..append(node.clone(true))).outerHtml;

sealed class ContentBlock {
  const ContentBlock();
}

/// Ein Ausschnitt des Beitragstexts, wie er hereinkam — unverändert an
/// `flutter_html` weitergereicht.
final class HtmlBlock extends ContentBlock {
  const HtmlBlock(this.html);
  final String html;
}

final class RelatedArticleBlock extends ContentBlock {
  const RelatedArticleBlock({
    required this.href,
    required this.title,
    this.imageUrl,
    this.category,
    this.moreLabel,
  });

  final String href;
  final String title;
  final String? imageUrl;
  final String? category;
  final String? moreLabel;
}

final class AuthorBoxBlock extends ContentBlock {
  const AuthorBoxBlock({
    required this.heading,
    required this.text,
    this.imageUrl,
  });

  final String heading;
  final String text;
  final String? imageUrl;
}

final class DriveGalleryBlock extends ContentBlock {
  const DriveGalleryBlock({
    required this.accountId,
    required this.listToken,
    required this.sort,
  });

  final String accountId;
  final String listToken;
  final String sort;
}

/// Erkennt jedes `<section class="newsy-widget">…</section>` im Beitragstext
/// und ersetzt es durch [RelatedArticleBlock]. Der übrige Text bleibt als
/// [HtmlBlock] unverändert — die meisten Beiträge tragen das Widget gar
/// nicht und ergeben dann genau **einen** Block mit dem vollständigen Text.
///
/// Die Fundstelle wird über eine einfache Zeichenkettensuche abgegrenzt,
/// nicht über einen vollständigen Dokumentbaum: So bleibt der unbeteiligte
/// Rest des Beitragstexts byteweise unverändert, und nur der gefundene
/// Ausschnitt selbst wird zur Feldauflösung geparst. Verschachtelte
/// `<section>`-Elemente innerhalb einer Karte sind im Bestand nicht
/// aufgetreten.
List<ContentBlock> splitRelatedArticles(String html) {
  if (!html.contains('newsy-widget')) return <ContentBlock>[HtmlBlock(html)];

  final List<ContentBlock> blocks = <ContentBlock>[];
  int cursor = 0;
  for (final RegExpMatch match in _newsyWidgetSection.allMatches(html)) {
    final String before = html.substring(cursor, match.start);
    if (before.trim().isNotEmpty) blocks.add(HtmlBlock(before));

    final String section = match.group(0)!;
    blocks.add(_parseCard(section) ?? HtmlBlock(section));
    cursor = match.end;
  }
  final String rest = html.substring(cursor);
  if (rest.trim().isNotEmpty) blocks.add(HtmlBlock(rest));

  return blocks.isEmpty ? <ContentBlock>[HtmlBlock(html)] : blocks;
}

final RegExp _newsyWidgetSection = RegExp(
  r'<section[^>]*\bclass="[^"]*\bnewsy-widget\b[^"]*"[^>]*>.*?</section>',
  dotAll: true,
);

RelatedArticleBlock? _parseCard(String sectionHtml) {
  final dom.DocumentFragment fragment = parseFragment(sectionHtml);
  final dom.Element? anchor = fragment.querySelector('a.newsy-card');
  final String? href = anchor?.attributes['href'];
  final String? title = anchor?.querySelector('h3')?.text.trim();
  if (href == null || title == null || title.isEmpty) return null;

  return RelatedArticleBlock(
    href: href,
    title: title,
    imageUrl: anchor?.querySelector('img')?.attributes['src'],
    category: _textOrNull(anchor?.querySelector('.slider-subtitle')),
    moreLabel: _textOrNull(anchor?.querySelector('.newsy-card-more')),
  );
}

String? _textOrNull(dom.Element? element) {
  final String? text = element?.text.trim();
  return text == null || text.isEmpty ? null : text;
}

/// Erkennt jedes `<div class="osoba-widget">…</div>` im Beitragstext und
/// ersetzt es durch [AuthorBoxBlock]. Läuft über den bereits von
/// [splitRelatedArticles] erzeugten Block-Bestand — nur [HtmlBlock]s werden
/// weiter zerlegt, andere Blöcke bleiben unverändert.
///
/// Die Fundstelle wird über den Dokumentbaum abgegrenzt, nicht über eine
/// Zeichenkettensuche wie bei [splitRelatedArticles]: `osoba-widget`
/// verschachtelt mehrere `<div>`-Ebenen (`osoba-body`, `osoba-text`,
/// `osoba-image`) ineinander — ein einfacher Suchlauf bis zum ersten
/// `</div>` träfe die falsche, innere Schließung.
List<ContentBlock> splitAuthorBox(List<ContentBlock> blocks) {
  final List<ContentBlock> result = <ContentBlock>[];
  for (final ContentBlock block in blocks) {
    if (block is! HtmlBlock || !block.html.contains('osoba-widget')) {
      result.add(block);
      continue;
    }
    result.addAll(_splitAuthorBoxHtml(block.html));
  }
  return result;
}

List<ContentBlock> _splitAuthorBoxHtml(String html) {
  final dom.DocumentFragment fragment = parseFragment(html);
  final List<ContentBlock> blocks = <ContentBlock>[];
  final StringBuffer pending = StringBuffer();

  void flushPending() {
    final String pendingHtml = pending.toString();
    if (pendingHtml.trim().isNotEmpty) blocks.add(HtmlBlock(pendingHtml));
    pending.clear();
  }

  for (final dom.Node node in fragment.nodes) {
    if (node is dom.Element && node.classes.contains('osoba-widget')) {
      flushPending();
      blocks.add(_parseAuthorBox(node) ?? HtmlBlock(node.outerHtml));
    } else {
      pending.write(nodeHtml(node));
    }
  }
  flushPending();

  return blocks.isEmpty ? <ContentBlock>[HtmlBlock(html)] : blocks;
}

AuthorBoxBlock? _parseAuthorBox(dom.Element widget) {
  final String? heading = _textOrNull(widget.querySelector('.osoba-naglowek'));
  final String? text = _paragraphText(widget.querySelector('.osoba-text'));
  if (heading == null || text == null) return null;

  return AuthorBoxBlock(
    heading: heading,
    text: text,
    imageUrl: widget.querySelector('.osoba-image img')?.attributes['src'],
  );
}

/// Verbindet die Absätze in [container] mit einer Leerzeile — `Element.text`
/// hängt sie sonst ohne jede Trennung aneinander, und `<br />` würde sonst
/// ganz verschwinden statt zum Zeilenumbruch zu werden (im Bestand gesehen:
/// „Der Schlesier in Warschau", ein `<p>` mit `<br />` zwischen
/// Kurzbiografie und Rubrik-Hinweis). Die feste Paketversion `html: 0.15.5`
/// (`pubspec.yaml`) kennt `Node.textContent(convertBRsToNewlines: …)` noch
/// nicht — `<br />` wird deshalb vor dem Lesen des Texts durch einen
/// Zeilenumbruch ersetzt, am rohen `innerHtml`.
String? _paragraphText(dom.Element? container) {
  if (container == null) return null;
  final List<dom.Element> paragraphs = container.querySelectorAll('p');
  final Iterable<dom.Element> source = paragraphs.isEmpty
      ? <dom.Element>[container]
      : paragraphs;
  final String joined = source
      .map(_textWithLineBreaks)
      .where((String s) => s.isNotEmpty)
      .join('\n\n');
  return joined.isEmpty ? null : joined;
}

final RegExp _lineBreakTag = RegExp(r'<br\s*/?>', caseSensitive: false);

String _textWithLineBreaks(dom.Element element) {
  final String withBreaks = element.innerHtml.replaceAll(_lineBreakTag, '\n');
  return parseFragment(withBreaks).text?.trim() ?? '';
}

List<ContentBlock> splitDriveGallery(List<ContentBlock> blocks) {
  final List<ContentBlock> result = <ContentBlock>[];
  for (final ContentBlock block in blocks) {
    if (block is! HtmlBlock || !block.html.contains('wpcp-container')) {
      result.add(block);
      continue;
    }
    result.addAll(_splitDriveGalleryHtml(block.html));
  }
  return result;
}

List<ContentBlock> _splitDriveGalleryHtml(String html) {
  final dom.DocumentFragment fragment = parseFragment(html);
  final List<ContentBlock> blocks = <ContentBlock>[];
  final StringBuffer pending = StringBuffer();

  void flushPending() {
    final String pendingHtml = pending.toString();
    if (pendingHtml.trim().isNotEmpty) blocks.add(HtmlBlock(pendingHtml));
    pending.clear();
  }

  // Eine **Kopie** der Knotenliste: Ein Behälter, der selbst ganz außen
  // steht, wird gleich aus genau dieser Liste entfernt.
  for (final dom.Node node in fragment.nodes.toList(growable: false)) {
    if (node is! dom.Element) {
      pending.write(nodeHtml(node));
      continue;
    }
    if (node.classes.contains('wpcp-container')) {
      flushPending();
      if (_parseGallery(node) case final DriveGalleryBlock gallery) {
        blocks.add(gallery);
      }
      continue;
    }
    final List<DriveGalleryBlock> galleries = <DriveGalleryBlock>[];
    bool found = false;
    for (
      dom.Element? container = node.querySelector('.wpcp-container');
      container != null;
      container = node.querySelector('.wpcp-container')
    ) {
      found = true;
      if (_parseGallery(container) case final DriveGalleryBlock gallery) {
        galleries.add(gallery);
      }
      container.remove();
    }
    pending.write(node.outerHtml);
    if (!found) continue;
    flushPending();
    blocks.addAll(galleries);
  }
  flushPending();

  return blocks;
}

DriveGalleryBlock? _parseGallery(dom.Element container) {
  final dom.Element? module = container.querySelector('.wpcp-module');
  final String? accountId = _attributeOrNull(module, 'data-account-id');
  final String? listToken = _attributeOrNull(module, 'data-token');
  if (accountId == null || listToken == null) return null;

  return DriveGalleryBlock(
    accountId: accountId,
    listToken: listToken,
    sort: _attributeOrNull(module, 'data-sort') ?? 'name:asc',
  );
}

String? _attributeOrNull(dom.Element? element, String name) {
  final String? value = element?.attributes[name]?.trim();
  return value == null || value.isEmpty ? null : value;
}
