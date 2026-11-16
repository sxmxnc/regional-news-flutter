import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/app_language.dart';
import '../../core/query.dart';
import 'content_queries.dart';
import 'taxonomy.dart';
import 'taxonomy_queries.dart';

abstract final class HomeLayout {
  /// Beiträge, aus denen Schlagzeilen und Liste gewählt werden. Schlagzeilen
  /// brauchen ein Bild (Annahme A-6); ein Vorrat von 15 trifft auch dann
  /// drei, wenn einige Beiträge keines haben.
  static const int topCandidates = 15;

  /// Die Liste unter den Schlagzeilen: die fünf neuesten Beiträge.
  static const int listCount = 5;

  /// Ein Block: Leitartikel plus vier weitere.
  static const int sectionCount = 5;
}

abstract final class HomeSlugs {
  /// Erste Menürubrik „Nachrichten": Die Website zeigt für sie keinen Block,
  /// ihre Inhalte stehen in den Schlagzeilen.
  static String news(AppLanguage language) => switch (language) {
    AppLanguage.de => 'news-de',
    AppLanguage.pl => 'wydarzenia',
  };

  /// Rubrik „Kolumne" — auf der Website der Block „Ansichtssache". Steht
  /// nicht im Menü, deshalb nur über den Slug zu finden.
  static String column(AppLanguage language) => switch (language) {
    AppLanguage.de => 'kolumne-de',
    AppLanguage.pl => 'kolumne',
  };

  /// Schlagwort, das genau den Beitrag „Thema des Monats" trägt.
  static String themeTag(AppLanguage language) => switch (language) {
    AppLanguage.de => 'themadesmonats',
    AppLanguage.pl => 'tematmiesiaca',
  };
}

enum HomeSectionKind { category, themeOfMonth, column }

/// Ein Block der Startseite.
final class HomeSection {
  const HomeSection.category(TaxonomyTerm this.term)
    : kind = HomeSectionKind.category,
      tagId = null;

  const HomeSection.column(TaxonomyTerm this.term)
    : kind = HomeSectionKind.column,
      tagId = null;

  const HomeSection.themeOfMonth(int this.tagId)
    : kind = HomeSectionKind.themeOfMonth,
      term = null;

  final HomeSectionKind kind;

  /// Die Rubrik bei [HomeSectionKind.category] und [HomeSectionKind.column].
  final TaxonomyTerm? term;

  /// Das Schlagwort bei [HomeSectionKind.themeOfMonth].
  final int? tagId;

  /// „Mehr lesen" führt in die Rubrik. „Thema des Monats" hat nur einen
  /// Beitrag und keine Rubrik dahinter.
  bool get hasMore => term != null;

  /// Abfrage dieses Blocks. [excludeIds] sind die Beiträge der Liste darüber,
  /// [excludeTagId] das Schlagwort „Thema des Monats".
  ArticleListKey key(
    AppLanguage language, {
    required List<int> excludeIds,
    required int? excludeTagId,
  }) {
    return switch (kind) {
      // Ein einziger Beitrag, ohne Ausschlüsse: Er **ist** das Schlagwort.
      HomeSectionKind.themeOfMonth => ArticleListKey(
        language,
        perPage: 1,
        tagId: tagId,
      ),
      HomeSectionKind.category || HomeSectionKind.column => ArticleListKey(
        language,
        perPage: HomeLayout.sectionCount,
        categoryId: term!.id,
        excludeIds: excludeIds,
        excludeTagId: excludeTagId,
      ),
    };
  }
}

/// Die Blockfolge der Startseite.
///
/// Reihenfolge der Website: die Menürubriken in Menüreihenfolge (ohne
/// „Nachrichten"), dazwischen „Thema des Monats" nach der ersten und
/// „Ansichtssache" (Kolumne) nach der zweiten Rubrik. Die Lage ist relativ
/// zur Menüreihenfolge gewählt, nicht an Rubriknamen festgemacht — die
/// bleiben Sache der Redaktion.
///
/// [menu] ist die nach Menüplatz geordnete Auswahl (`editorial_menu`). Fehlt das
/// Zusatz-Plugin, trägt kein Begriff `inMenu == true` — dann gibt es keine
/// Rubrikblöcke statt achtzehn, wie sie die Website nie zeigt.
List<HomeSection> planHomeSections({
  required AppLanguage language,
  required List<TaxonomyTerm> menu,
  required List<TaxonomyTerm> allCategories,
  required int? themeTagId,
}) {
  final String news = HomeSlugs.news(language);
  final List<TaxonomyTerm> categories = menu
      .where((TaxonomyTerm term) => term.inMenu == true && term.slug != news)
      .toList(growable: false);
  final String columnSlug = HomeSlugs.column(language);
  TaxonomyTerm? column;
  for (final TaxonomyTerm term in allCategories) {
    if (term.slug == columnSlug) column = term;
  }

  final List<HomeSection> sections = <HomeSection>[];
  bool themeAdded = themeTagId == null;
  bool columnAdded = column == null;
  for (int i = 0; i < categories.length; i++) {
    sections.add(HomeSection.category(categories[i]));
    if (i == 0 && !themeAdded) {
      sections.add(HomeSection.themeOfMonth(themeTagId!));
      themeAdded = true;
    }
    if (i == 1 && !columnAdded) {
      sections.add(HomeSection.column(column!));
      columnAdded = true;
    }
  }
  // Weniger als zwei Menürubriken: die Sonderblöcke stehen trotzdem.
  if (!themeAdded) sections.add(HomeSection.themeOfMonth(themeTagId!));
  if (!columnAdded) sections.add(HomeSection.column(column!));
  return List<HomeSection>.unmodifiable(sections);
}

/// Was die Startseite vor dem ersten Beitragsabruf wissen muss.
final class HomePlan {
  const HomePlan({required this.themeTagId, required this.sections});

  /// `null`, wenn es das Schlagwort im Sprachbaum nicht gibt.
  final int? themeTagId;
  final List<HomeSection> sections;

  /// Abfrage für Schlagzeilen und Liste: die neuesten Beiträge, **ohne**
  /// „Thema des Monats" (der steht im eigenen Block).
  ArticleListKey topKey(AppLanguage language) => ArticleListKey(
    language,
    perPage: HomeLayout.topCandidates,
    excludeTagId: themeTagId,
  );

  List<ArticleListKey> sectionKeys(AppLanguage language, List<int> excludeIds) {
    return <ArticleListKey>[
      for (final HomeSection section in sections)
        section.key(language, excludeIds: excludeIds, excludeTagId: themeTagId),
    ];
  }
}

/// Abfrageschlüssel für den [HomePlan] — nur die Sprache (Regel 3).
final class HomePlanKey extends QueryKey {
  const HomePlanKey(super.language);

  @override
  List<Object?> get parts => const <Object?>[];
}

/// Die Schlüssel der drei Abfragen, aus denen der [HomePlan] entsteht. An einer
/// Stelle, damit Ansicht (Herunterziehen) und Provider dieselben meinen.
extension HomePlanSources on AppLanguage {
  MenuCategoryKey get homeMenuKey => MenuCategoryKey(this);
  TaxonomyListKey get homeCategoriesKey =>
      TaxonomyListKey(this, TaxonomyResource.categories);
  TermSlugKey get homeThemeTagKey =>
      TermSlugKey(this, TaxonomyResource.tags, HomeSlugs.themeTag(this));
}

/// Blockfolge und Schlagwort — drei Abrufe **nebeneinander**, ein Fehler in
/// einem davon ist ein Fehler der Startseite. Ein still fehlendes Schlagwort
/// ließe „Thema des Monats" unbemerkt in Politik und Schlagzeilen rutschen.
final FutureProviderFamily<HomePlan, HomePlanKey>
homePlanProvider = FutureProvider.family<HomePlan, HomePlanKey>((
  Ref ref,
  HomePlanKey key,
) async {
  final AppLanguage language = key.language;
  final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
    ref.watch(menuCategoryListProvider(language.homeMenuKey).future),
    ref.watch(taxonomyListProvider(language.homeCategoriesKey).future),
    ref.watch(taxonomyTermBySlugProvider(language.homeThemeTagKey).future),
  ]);
  final int? themeTagId = (results[2] as TaxonomyTerm?)?.id;
  return HomePlan(
    themeTagId: themeTagId,
    sections: planHomeSections(
      language: language,
      menu: results[0]! as List<TaxonomyTerm>,
      allCategories: results[1]! as List<TaxonomyTerm>,
      themeTagId: themeTagId,
    ),
  );
}, isAutoDispose: true);
