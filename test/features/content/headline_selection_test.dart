import 'package:flutter_test/flutter_test.dart';
import 'package:regional_news_app/features/content/article.dart';
import 'package:regional_news_app/features/content/headline_selection.dart';

void main() {
  Article article(int id, {String? imageUrl}) =>
      Article(id: id, title: 'Beitrag $id', imageUrl: imageUrl);

  test('nimmt nur Beiträge mit Bild, in der gegebenen Reihenfolge', () {
    final List<Article> latest = <Article>[
      article(1),
      article(2, imageUrl: 'https://example.test/2.jpg'),
      article(3, imageUrl: 'https://example.test/3.jpg'),
      article(4),
      article(5, imageUrl: 'https://example.test/5.jpg'),
      article(6, imageUrl: 'https://example.test/6.jpg'),
    ];

    final List<Article> headline = selectHeadline(latest);

    expect(headline.map((Article a) => a.id), <int>[2, 3, 5]);
  });

  test('AK1: mindestens drei — hier genau drei bei ausreichendem Angebot', () {
    final List<Article> latest = List<Article>.generate(
      10,
      (int i) => article(i, imageUrl: 'https://example.test/$i.jpg'),
    );

    expect(selectHeadline(latest), hasLength(3));
  });

  test('weniger als drei Bilder ergeben eine kürzere Liste, keinen Fehler', () {
    final List<Article> latest = <Article>[
      article(1, imageUrl: 'https://example.test/1.jpg'),
      article(2),
      article(3),
    ];

    expect(selectHeadline(latest), hasLength(1));
  });

  test('keine Bilder ergeben eine leere Liste', () {
    final List<Article> latest = <Article>[article(1), article(2)];
    expect(selectHeadline(latest), isEmpty);
  });

  group('selectList', () {
    test(
      'E-096: lässt nur den ersten Schlagzeilen-Beitrag aus, rückt dafür nach',
      () {
        final List<Article> latest = List<Article>.generate(
          8,
          (int i) =>
              article(i + 1, imageUrl: 'https://example.test/${i + 1}.jpg'),
        );
        final List<Article> headline = selectHeadline(latest);

        final List<Article> list = selectList(latest, headline, count: 5);

        // Beitrag 1 (der erste Slider-Beitrag) fehlt, Beitrag 6 rückt nach.
        expect(list.map((Article a) => a.id), <int>[2, 3, 4, 5, 6]);
      },
    );

    test('ohne Schlagzeilen bleiben einfach die neuesten Beiträge', () {
      final List<Article> latest = <Article>[article(1), article(2)];

      expect(
        selectList(
          latest,
          const <Article>[],
          count: 5,
        ).map((Article a) => a.id),
        <int>[1, 2],
      );
    });
  });
}
