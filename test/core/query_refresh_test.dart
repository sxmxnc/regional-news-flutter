import 'package:flutter_test/flutter_test.dart';
import 'package:regional_news_app/core/app_language.dart';
import 'package:regional_news_app/core/query.dart';
import 'package:regional_news_app/features/content/content_queries.dart';
import 'package:regional_news_app/features/content/taxonomy_queries.dart';

void main() {
  test('eine Anforderung gilt genau einmal', () {
    final RefreshRequests requests = RefreshRequests();
    const MenuCategoryKey key = MenuCategoryKey(AppLanguage.de);

    expect(requests.consume(key), isFalse, reason: 'ohne Anforderung');

    requests.request(key);
    expect(requests.consume(key), isTrue);
    expect(
      requests.consume(key),
      isFalse,
      reason: 'sonst liefe jeder spätere Abruf am Zwischenspeicher vorbei',
    );
  });

  test('die Anforderung gilt je Schlüssel, nicht pauschal', () {
    final RefreshRequests requests = RefreshRequests();
    const MenuCategoryKey deutsch = MenuCategoryKey(AppLanguage.de);
    const MenuCategoryKey polnisch = MenuCategoryKey(AppLanguage.pl);

    requests.request(deutsch);

    // Regel 3: Die Sprache gehört zum Schlüssel. Ein Wischgriff in der
    // deutschen Liste darf die polnische nicht mitziehen.
    expect(requests.consume(polnisch), isFalse);
    expect(requests.consume(deutsch), isTrue);
  });

  test('gleichwertige Schlüssel sind derselbe Auftrag', () {
    final RefreshRequests requests = RefreshRequests();

    // Die Ansicht bildet den Schlüssel bei jedem Aufbau neu. Träfe die
    // Anforderung nur die eine Instanz, liefe der Wischgriff ins Leere.
    requests.request(ArticleListKey(AppLanguage.de, page: 1, categoryId: 7));
    expect(
      requests.consume(ArticleListKey(AppLanguage.de, page: 1, categoryId: 7)),
      isTrue,
    );
  });

  test('verschiedene Schlüssel derselben Familie bleiben getrennt', () {
    final RefreshRequests requests = RefreshRequests();

    requests.request(ArticleListKey(AppLanguage.de, page: 1));
    expect(requests.consume(ArticleListKey(AppLanguage.de, page: 2)), isFalse);
    expect(requests.consume(ArticleListKey(AppLanguage.de, page: 1)), isTrue);
  });
}
