import 'package:flutter_test/flutter_test.dart';
import 'package:regional_news_app/core/app_language.dart';
import 'package:regional_news_app/features/content/home_sections.dart';
import 'package:regional_news_app/features/content/taxonomy.dart';

void main() {
  TaxonomyTerm term(int id, String slug, {bool? inMenu = true, int? pos}) =>
      TaxonomyTerm(
        id: id,
        name: slug,
        slug: slug,
        inMenu: inMenu,
        menuPosition: pos,
      );

  final List<TaxonomyTerm> menu = <TaxonomyTerm>[
    term(1, 'news-de', pos: 1),
    term(2, 'politik-de', pos: 2),
    term(3, 'geschichte-de', pos: 3),
    term(4, 'kultur-de', pos: 4),
  ];
  final List<TaxonomyTerm> all = <TaxonomyTerm>[
    ...menu,
    term(9, 'kolumne-de', inMenu: false),
  ];

  List<String> plan(
    List<TaxonomyTerm> menuTerms, {
    int? tag = 900,
    List<TaxonomyTerm>? categories,
  }) => planHomeSections(
    language: AppLanguage.de,
    menu: menuTerms,
    allCategories: categories ?? all,
    themeTagId: tag,
  ).map((HomeSection s) => '${s.kind.name}:${s.term?.id ?? s.tagId}').toList();

  test(
    'Menürubriken ohne Nachrichten, Sonderblöcke an der Stelle der Website',
    () {
      expect(plan(menu), <String>[
        'category:2',
        'themeOfMonth:900',
        'category:3',
        'column:9',
        'category:4',
      ]);
    },
  );

  test('ohne Schlagwort und ohne Kolumne entfallen die Sonderblöcke', () {
    expect(plan(menu, tag: null, categories: menu), <String>[
      'category:2',
      'category:3',
      'category:4',
    ]);
  });

  test('ohne Zusatz-Plugin (inMenu null) gibt es keine Rubrikblöcke', () {
    final List<TaxonomyTerm> ohnePlugin = <TaxonomyTerm>[
      term(2, 'politik-de', inMenu: null),
      term(3, 'geschichte-de', inMenu: null),
    ];
    expect(plan(ohnePlugin, categories: ohnePlugin), <String>[
      'themeOfMonth:900',
    ]);
  });

  test('bei nur einer Menürubrik stehen die Sonderblöcke trotzdem', () {
    expect(plan(<TaxonomyTerm>[menu[1]]), <String>[
      'category:2',
      'themeOfMonth:900',
      'column:9',
    ]);
  });

  test('Schlüssel: Blöcke schließen Liste und Schlagwort aus, das Thema nicht', () {
    final HomePlan p = HomePlan(
      themeTagId: 900,
      sections: planHomeSections(
        language: AppLanguage.de,
        menu: menu,
        allCategories: all,
        themeTagId: 900,
      ),
    );
    final top = p.topKey(AppLanguage.de);
    expect(top.perPage, 15);
    expect(top.excludeTagId, 900);

    final keys = p.sectionKeys(AppLanguage.de, const []);
    expect(keys.first.perPage, 5);
    expect(keys.first.categoryId, 2);
    // Das Thema des Monats: ein Beitrag, über das Schlagwort, ohne Ausschluss.
    expect(keys[1].tagId, 900);
    expect(keys[1].perPage, 1);
    expect(keys[1].excludeTagId, isNull);
  });

  test('Abfrageschlüssel mit gleichen Ausschlüssen sind gleich', () {
    final HomePlan p = HomePlan(
      themeTagId: 900,
      sections: <HomeSection>[HomeSection.category(menu[1])],
    );
    final a = p.sectionKeys(AppLanguage.de, const []);
    final b = p.sectionKeys(AppLanguage.de, const []);
    expect(a.first, b.first);
    expect(a.first.hashCode, b.first.hashCode);
    expect(p.sectionKeys(AppLanguage.pl, const []).first, isNot(a.first));
  });
}
