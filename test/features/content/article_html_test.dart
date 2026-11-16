import 'package:flutter_test/flutter_test.dart';
import 'package:regional_news_app/features/content/article_html.dart';

void main() {
  test('ein zu breites Bild wird seitenverhältnistreu verkleinert', () {
    const String html =
        '<img loading="lazy" src="https://example.test/a.jpg" '
        'alt="" width="1216" height="880" class="size-full">';

    final String verkleinert = sanitizeArticleHtml(html, maxWidth: 320);

    expect(verkleinert, contains('width="320"'));
    // 880 * 320 / 1216 = 231,58 → gerundet 232.
    expect(verkleinert, contains('height="232"'));
    expect(verkleinert, contains('src="https://example.test/a.jpg"'));
    expect(verkleinert, contains('alt=""'));
    expect(verkleinert, contains('class="size-full"'));
  });

  test('live gefunden: 1959×1442 auf eine schmale Spalte verkleinert (E-019 Nachtrag)', () {
    const String html = '<img src="a.jpg" width="1959" height="1442">';
    final String verkleinert = sanitizeArticleHtml(html, maxWidth: 328);

    expect(verkleinert, contains('width="328"'));
    // 1442 * 328 / 1959 = 241,5 → gerundet 241 statt der ganzen Bildschirmhöhe.
    expect(verkleinert, contains('height="241"'));
  });

  test('ein bereits schmaleres Bild bleibt unverändert', () {
    const String html = '<img src="a.jpg" width="300" height="200">';
    expect(sanitizeArticleHtml(html, maxWidth: 328), html);
  });

  test('lässt srcset und andere Angaben unverändert', () {
    const String html =
        '<img src="a.jpg" width="1200" height="800" '
        'srcset="a-300x200.jpg 300w, a.jpg 1200w">';

    final String verkleinert = sanitizeArticleHtml(html, maxWidth: 300);
    expect(verkleinert, contains('srcset="a-300x200.jpg 300w, a.jpg 1200w"'));
    expect(verkleinert, contains('src="a.jpg"'));
    expect(verkleinert, contains('width="300"'));
  });

  test(
    'mehrere Bilder im selben Text werden unabhängig voneinander verkleinert',
    () {
      const String html =
          '<p>Text</p><img src="a.jpg" width="1000" height="500">'
          '<p>Mitte</p><img src="b.jpg" width="3000" height="1000">';

      final String verkleinert = sanitizeArticleHtml(html, maxWidth: 300);
      expect(
        verkleinert,
        contains('<img width="300" height="150" src="a.jpg">'),
      );
      expect(
        verkleinert,
        contains('<img width="300" height="100" src="b.jpg">'),
      );
    },
  );

  test('Text ohne img bleibt unverändert', () {
    const String html = '<p>Ein Beitrag ganz ohne Bild.</p>';
    expect(sanitizeArticleHtml(html, maxWidth: 300), html);
  });

  test('width/height außerhalb eines img-Tags bleiben unberührt', () {
    const String html = '<table width="100"><tr><td>x</td></tr></table>';
    expect(sanitizeArticleHtml(html, maxWidth: 300), html);
  });

  test('ein img ohne width/height bleibt unverändert (kein Ratewert)', () {
    const String html = '<img src="a.jpg" alt="ohne Maße">';
    expect(sanitizeArticleHtml(html, maxWidth: 300), html);
  });

  group('wp-caption: style="width" an der Hülle (E-019, Nachtrag Teil 2)', () {
    // Live gefunden im Beitrag „Eine Danziger Straßenbahn von 1927 fährt
    // durch Warschau" (Anhang 85989): Die klassische Bearbeitung umschließt
    // Bild und Unterschrift mit `<div style="width: …px" class="wp-caption">`.
    // Das ist eine echte CSS-Breite, kein `<img>`-Attribut — der
    // Unterschriftstext bricht sonst innerhalb dieser überbreiten Box um,
    // sichtbar ist nur ihr linker Rand.
    const String wpCaptionHtml =
        '<div id="attachment_85989" style="width: 1226px" '
        'class="wp-caption aligncenter">'
        '<img src="a.jpg" alt="" width="1216" height="880">'
        '<p class="wp-caption-text">Die ersten Pferdebahnen nahmen 1873 '
        'ihren Betrieb in Danzig auf.<br />Foto: Gemini generiert.</p>'
        '</div>';

    test('die style-Breite an der Hülle entfällt, das Bild wird trotzdem verkleinert', () {
      final String bereinigt = sanitizeArticleHtml(
        wpCaptionHtml,
        maxWidth: 328,
      );

      expect(bereinigt, isNot(contains('width: 1226px')));
      expect(bereinigt, contains('width="328"'));
      expect(bereinigt, contains('class="wp-caption aligncenter"'));
      expect(bereinigt, contains('Die ersten Pferdebahnen'));
    });

    test('eine style-Angabe ohne width bleibt unangetastet', () {
      const String html = '<div style="text-align: center;">Text</div>';
      expect(sanitizeArticleHtml(html, maxWidth: 300), html);
    });

    test('max-width und border-width bleiben unberührt (E-135)', () {
      const String html =
          '<div style="max-width: 300px; color: red">Text</div>'
          '<table style="border-width: 1px; width: 500px"></table>';
      final String bereinigt = sanitizeArticleHtml(html, maxWidth: 300);

      expect(bereinigt, contains('max-width: 300px; color: red'));
      expect(bereinigt, contains('border-width: 1px;'));
      expect(bereinigt, isNot(contains('width: 500px')));
    });

    test('andere Eigenschaften im selben style bleiben erhalten', () {
      const String html =
          '<div style="width: 500px; text-align: center;">Text</div>';
      final String bereinigt = sanitizeArticleHtml(html, maxWidth: 300);

      expect(bereinigt, isNot(contains('width')));
      expect(bereinigt, contains('text-align: center'));
    });
  });

  test('splitBeforeFirstPrice gibt Text maskiert zurück und Kommentare nicht '
      'als Text (E-135)', () {
    final ({String before, String after}) teile = splitBeforeFirstPrice(
      'a &lt;b&gt;fett&lt;/b&gt;<!-- intern --><p>Preis 10,00 PLN</p>',
    );

    expect(teile.before, contains('&lt;b&gt;fett'));
    expect(teile.before, isNot(contains('<b>')));
    expect(
      teile.before.replaceAll('<!-- intern -->', ''),
      isNot(contains('intern')),
    );
    expect(teile.after, contains('10,00 PLN'));
  });
}
