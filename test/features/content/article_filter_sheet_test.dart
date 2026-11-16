import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:regional_news_app/api/http_client.dart';
import 'package:regional_news_app/core/app_language.dart';
import 'package:regional_news_app/core/key_value_store.dart';
import 'package:regional_news_app/core/query.dart';
import 'package:regional_news_app/features/content/article_filter_sheet.dart';
import 'package:regional_news_app/i18n/translations.dart';
import 'package:regional_news_app/ui/theme/app_theme.dart';

import '../../support/fake_key_value_store.dart';

void main() {
  late Map<AppLanguage, Translations> texte;

  setUpAll(() async {
    texte = await Translations.loadAll();
  });

  testWidgets('zeigt Rubrik und Autor zur Auswahl', (
    WidgetTester tester,
  ) async {
    await _oeffneFlaeche(tester, texte);

    expect(find.text('Beiträge filtern'), findsOneWidget);
    expect(find.text('Alle Rubriken'), findsOneWidget);
    expect(find.text('Alle Autoren'), findsOneWidget);
  });

  testWidgets(
    'eine gewählte Rubrik wird beim Anwenden samt Slug zurückgegeben',
    (WidgetTester tester) async {
      final ArticleFilter? ergebnis = await _waehleUndWende(
        tester,
        texte,
        buttonLabel: 'Anwenden',
        selectCategory: true,
      );

      expect(ergebnis, isNotNull);
      expect(ergebnis!.categoryId, 7);
      expect(ergebnis.categoryName, 'Kultur');
      expect(ergebnis.categorySlug, 'kultur');
    },
  );

  testWidgets('„Zurücksetzen" liefert eine leere Auswahl', (
    WidgetTester tester,
  ) async {
    final ArticleFilter? ergebnis = await _waehleUndWende(
      tester,
      texte,
      buttonLabel: 'Zurücksetzen',
      selectCategory: true,
    );

    expect(ergebnis, isNotNull);
    expect(ergebnis!.isEmpty, isTrue);
  });

  testWidgets('ANF-F-27 AK3: der Zeitraum reicht bis zum ältesten Beitrag '
      '(26.07.2016) zurück (E-134)', (WidgetTester tester) async {
    await _oeffneFlaeche(tester, texte);

    await tester.tap(find.text('Von'));
    await tester.pumpAndSettle();

    final DatePickerDialog auswahl = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(
      auswahl.firstDate.isAfter(DateTime(2016, 7, 26)),
      isFalse,
      reason: 'Beiträge ab dem 26.07.2016 müssen wählbar sein',
    );
  });

  testWidgets('Rubrik und Autor lassen sich gleichzeitig setzen', (
    WidgetTester tester,
  ) async {
    final ArticleFilter? ergebnis = await _waehleUndWende(
      tester,
      texte,
      buttonLabel: 'Anwenden',
      selectCategory: true,
      selectAuthor: true,
    );

    expect(ergebnis, isNotNull);
    expect(ergebnis!.categoryId, 7);
    expect(ergebnis.authorId, 12);
  });
}

MockClient _stammdatenClient() {
  return MockClient((http.Request request) async {
    final bool istAutoren = request.url.path.endsWith('/redaktor');
    return http.Response(
      jsonEncode(
        istAutoren
            ? <Map<String, Object?>>[
                <String, Object?>{'id': 12, 'name': 'Anna Nowak'},
              ]
            : <Map<String, Object?>>[
                <String, Object?>{'id': 7, 'name': 'Kultur', 'slug': 'kultur'},
              ],
      ),
      200,
      headers: <String, String>{
        'content-type': 'application/json; charset=utf-8',
      },
    );
  });
}

/// Öffnet die Fläche über eine Schaltfläche und lässt sie offen stehen — für
/// Prüfungen an der Fläche selbst.
Future<void> _oeffneFlaeche(
  WidgetTester tester,
  Map<AppLanguage, Translations> texte,
) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: nwbRetry,
      overrides: <Override>[
        keyValueStoreProvider.overrideWithValue(
          FakeKeyValueStore(<String, String>{'language': 'de'}),
        ),
        translationBundleProvider.overrideWithValue(texte),
        httpClientProvider.overrideWithValue(_stammdatenClient()),
      ],
      child: MaterialApp(
        theme: buildNwbTheme(NwbTextScale.normal),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    showArticleFilterSheet(context, language: AppLanguage.de),
                child: const Text('Filter öffnen'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Filter öffnen'));
  await tester.pumpAndSettle();
}

/// Öffnet die Fläche, trifft optional eine Auswahl bei Rubrik und Autor und
/// schließt mit [buttonLabel] („Anwenden" oder „Zurücksetzen"). Liefert die
/// Auswahl, mit der `showArticleFilterSheet` sich auflöst.
Future<ArticleFilter?> _waehleUndWende(
  WidgetTester tester,
  Map<AppLanguage, Translations> texte, {
  required String buttonLabel,
  bool selectCategory = false,
  bool selectAuthor = false,
}) async {
  ArticleFilter? ergebnis;

  await tester.pumpWidget(
    ProviderScope(
      retry: nwbRetry,
      overrides: <Override>[
        keyValueStoreProvider.overrideWithValue(
          FakeKeyValueStore(<String, String>{'language': 'de'}),
        ),
        translationBundleProvider.overrideWithValue(texte),
        httpClientProvider.overrideWithValue(_stammdatenClient()),
      ],
      child: MaterialApp(
        theme: buildNwbTheme(NwbTextScale.normal),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  ergebnis = await showArticleFilterSheet(
                    context,
                    language: AppLanguage.de,
                  );
                },
                child: const Text('Filter öffnen'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Filter öffnen'));
  await tester.pumpAndSettle();

  if (selectCategory) {
    await tester.tap(find.text('Alle Rubriken'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kultur').last);
    await tester.pumpAndSettle();
  }
  if (selectAuthor) {
    await tester.tap(find.text('Alle Autoren'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anna Nowak').last);
    await tester.pumpAndSettle();
  }

  await tester.tap(find.text(buttonLabel));
  await tester.pumpAndSettle();
  return ergebnis;
}
