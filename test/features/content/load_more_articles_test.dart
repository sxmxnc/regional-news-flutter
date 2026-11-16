import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:regional_news_app/api/wp_client.dart';
import 'package:regional_news_app/core/app_language.dart';
import 'package:regional_news_app/features/content/content_queries.dart';
import 'package:regional_news_app/features/content/content_repository.dart';
import 'package:regional_news_app/features/content/load_more_articles.dart';

void main() {
  testWidgets('eine Seite aus der Zeit vor dem Zurücksetzen wird verworfen, '
      'nicht angehängt (E-128)', (WidgetTester tester) async {
    final Completer<http.Response> antwort = Completer<http.Response>();
    final ContentRepository repository = ContentRepository(
      WpClient(
        httpClient: MockClient((_) => antwort.future),
        language: AppLanguage.de,
      ),
    );
    final GlobalKey<_ProbeState> key = GlobalKey<_ProbeState>();
    await tester.pumpWidget(_Probe(key: key));
    final _ProbeState probe = key.currentState!;

    // Seite 2 der deutschen Liste ist unterwegs …
    unawaited(
      probe.loadMore(
        repository,
        (int page) => ArticleListKey(AppLanguage.de, page: page),
      ),
    );
    await tester.pump();
    expect(probe.isLoadingMore, isTrue);

    // … da wechselt die Sprache und der Bestand wird zurückgesetzt.
    probe.resetPaging();
    expect(probe.isLoadingMore, isFalse);

    antwort.complete(
      http.Response(
        jsonEncode(<Object?>[
          <String, Object?>{
            'id': 1,
            'title': <String, Object?>{'rendered': 'Deutsche Seite 2'},
          },
        ]),
        200,
        headers: <String, String>{
          'content-type': 'application/json; charset=utf-8',
          'x-wp-totalpages': '5',
        },
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(probe.loadedExtra, isEmpty);
    expect(probe.hasMore, isTrue);
    expect(probe.isLoadingMore, isFalse);
  });
}

class _Probe extends StatefulWidget {
  const _Probe({super.key});

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with LoadMoreArticles<_Probe> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
