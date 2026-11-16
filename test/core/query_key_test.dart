import 'package:flutter_test/flutter_test.dart';
import 'package:regional_news_app/core/app_language.dart';
import 'package:regional_news_app/core/failure.dart';
import 'package:regional_news_app/core/query.dart';
import 'package:regional_news_app/features/content/content_queries.dart';

void main() {
  test('gleiche Liste, andere Sprache: verschiedene Schlüssel', () {
    const ArticleListKey de = ArticleListKey(AppLanguage.de);
    const ArticleListKey pl = ArticleListKey(AppLanguage.pl);

    expect(de, isNot(equals(pl)));
    expect(de.hashCode, isNot(equals(pl.hashCode)));
  });

  test('gleiche Sprache und gleiche Bestandteile: derselbe Schlüssel', () {
    expect(
      const ArticleListKey(AppLanguage.de, page: 2),
      equals(const ArticleListKey(AppLanguage.de, page: 2)),
    );
    expect(
      const ArticleListKey(AppLanguage.de, page: 2).hashCode,
      const ArticleListKey(AppLanguage.de, page: 2).hashCode,
    );
  });

  test('jeder Bestandteil unterscheidet', () {
    const ArticleListKey base = ArticleListKey(AppLanguage.de);
    expect(base, isNot(equals(const ArticleListKey(AppLanguage.de, page: 2))));
    expect(
      base,
      isNot(equals(const ArticleListKey(AppLanguage.de, perPage: 20))),
    );
    expect(
      base,
      isNot(equals(const ArticleListKey(AppLanguage.de, categoryId: 7))),
    );
    expect(
      base,
      isNot(equals(const ArticleListKey(AppLanguage.de, search: 'BJDM'))),
    );
  });

  test('verschiedene Schlüsselarten sind nie gleich', () {
    expect(
      const ArticleListKey(AppLanguage.de),
      isNot(equals(const ArticleKey(AppLanguage.de, 1))),
    );
  });

  test('der Sprachcode steht in jeder Beschreibung des Schlüssels', () {
    for (final AppLanguage language in AppLanguage.values) {
      expect(ArticleListKey(language).toString(), contains(language.code));
      expect(ArticleKey(language, 42).toString(), contains(language.code));
    }
  });

  test('ein Einzelbeitrag bleibt länger frisch als eine Liste', () {
    expect(
      const ArticleKey(AppLanguage.de, 1).freshFor,
      greaterThan(const ArticleListKey(AppLanguage.de).freshFor),
    );
    expect(
      const ArticleListKey(AppLanguage.de).freshFor,
      const Duration(minutes: 5),
    );
  });

  group('selbsttätige Wiederholung — ANF-NF-05', () {
    test('der Verbindungsfehler heilt sich, höchstens dreimal', () {
      const ConnectionFailure keinNetz = ConnectionFailure();
      expect(nwbRetry(0, keinNetz), const Duration(seconds: 2));
      expect(nwbRetry(1, keinNetz), const Duration(seconds: 4));
      expect(nwbRetry(2, keinNetz), const Duration(seconds: 8));
      expect(nwbRetry(3, keinNetz), isNull);
    });

    test('ein Serverfehler wird nicht selbsttätig wiederholt', () {
      // Sonst sieht die Leserin eine halbe Minute lang einen Ladezustand
      // statt eines Satzes mit „Erneut versuchen".
      expect(nwbRetry(0, const ServerFailure(statusCode: 500)), isNull);
      expect(nwbRetry(0, const ServerFailure(statusCode: 404)), isNull);
      expect(nwbRetry(0, const ContentFailure()), isNull);
      expect(nwbRetry(0, StateError('etwas anderes')), isNull);
    });

    test('401 und 403 sind als Sitzungsfehler erkennbar', () {
      expect(const ServerFailure(statusCode: 401).isUnauthorized, isTrue);
      expect(const ServerFailure(statusCode: 403).isUnauthorized, isTrue);
      expect(const ServerFailure(statusCode: 500).isUnauthorized, isFalse);
    });
  });
}
