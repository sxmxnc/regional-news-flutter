import 'dart:convert';

import 'package:http/http.dart' as http;

typedef _Article = ({int id, int categoryId, String title, String body});

/// Provides local examples in the same shape as the public demo API.
final class EditorialDemoClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final Uri uri = request.url;
    final List<String> path = uri.pathSegments;
    final bool german = path.firstOrNull == 'de';
    final int apiIndex = path.indexOf('wp-json');
    if (request.method != 'GET' || apiIndex < 0 || path.length < apiIndex + 4) {
      return _response(404, {'message': 'Unavailable in the local demo'});
    }

    final String namespace = path[apiIndex + 1];
    final String resource = path[apiIndex + 3];
    final String? item = path.length > apiIndex + 4 ? path[apiIndex + 4] : null;

    if (namespace == 'reader') {
      return switch ((resource, item)) {
        ('articles', 'years') => _response(200, {'years': []}),
        ('articles', null) => _response(200, {'links': []}),
        ('notifications', null) => _response(200, {'categories': []}),
        ('subscription', 'plans') => _response(200, {'plans': []}),
        _ => _response(404, {'message': 'Unavailable in the local demo'}),
      };
    }
    if (namespace != 'wp') return _response(404, {'message': 'Not found'});

    final Map<String, String> query = uri.queryParameters;
    switch (resource) {
      case 'posts':
        final List<_Article> articles = _articles(german);
        if (item != null) {
          for (final _Article article in articles) {
            if (article.id.toString() == item) {
              return _response(200, _articleJson(article));
            }
          }
          return _response(404, {'message': 'Article not found'});
        }
        final String search = (query['search'] ?? '').toLowerCase();
        final Set<String> excluded = (query['exclude'] ?? '')
            .split(',')
            .toSet();
        final List<Map<String, Object?>> matches = [
          for (final _Article article in articles)
            if (!excluded.contains(article.id.toString()) &&
                (query['categories'] == null ||
                    query['categories'] == article.categoryId.toString()) &&
                query['slug'] == null &&
                query['tags'] == null &&
                '${article.title} ${article.body}'.toLowerCase().contains(
                  search,
                ))
              _articleJson(article),
        ];
        return _page(matches, query);
      case 'categories':
        final List<Map<String, Object>> terms = [
          _category(
            1,
            german ? 'Nachrichten' : 'Wiadomości',
            german ? 'news-de' : 'wydarzenia',
          ),
          _category(2, german ? 'Kultur' : 'Kultura', 'culture'),
        ];
        if (item != null) {
          for (final Map<String, Object> term in terms) {
            if (term['id'].toString() == item) return _response(200, term);
          }
          return _response(404, {'message': 'Category not found'});
        }
        return _page([
          for (final Map<String, Object> term in terms)
            if (query['slug'] == null || query['slug'] == term['slug']) term,
        ], query);
      case 'pages':
        return _page([
          {
            'id': 1,
            'title': {'rendered': german ? 'Über die Demo' : 'O demonstracji'},
            'content': {
              'rendered': german
                  ? '<p>Diese App enthält ausschließlich fiktive Inhalte.</p>'
                  : '<p>Wszystkie treści tej aplikacji są fikcyjne.</p>',
            },
          },
        ], query);
      default:
        return item == null
            ? _page([], query)
            : _response(404, {'message': 'Not found'});
    }
  }

  static Map<String, Object> _category(int id, String name, String slug) => {
    'id': id,
    'name': name,
    'slug': slug,
    'count': 2,
  };

  static Map<String, Object> _articleJson(_Article a) => {
    'id': a.id,
    'title': {'rendered': a.title},
    'excerpt': {'rendered': '<p>${a.body}</p>'},
    'content': {'rendered': '<p>${a.body}</p>'},
    'categories': [a.categoryId],
    'date_gmt': '2026-11-0${a.id}T10:00:00',
  };

  static http.StreamedResponse _page(
    List<Object> items,
    Map<String, String> query,
  ) {
    final int size = (int.tryParse(query['per_page'] ?? '') ?? 10).clamp(
      1,
      100,
    );
    final int page = (int.tryParse(query['page'] ?? '') ?? 1).clamp(1, 10000);
    final int pages = (items.length / size).ceil();
    return _response(200, items.skip((page - 1) * size).take(size).toList(), {
      'x-wp-total': '${items.length}',
      'x-wp-totalpages': '$pages',
    });
  }

  static http.StreamedResponse _response(
    int status,
    Object payload, [
    Map<String, String> headers = const {},
  ]) => http.StreamedResponse(
    Stream<List<int>>.value(utf8.encode(jsonEncode(payload))),
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'x-payments-enabled': '0',
      ...headers,
    },
  );

  static List<_Article> _articles(bool german) => german
      ? const [
          (
            id: 4,
            categoryId: 1,
            title: 'Lesegarten öffnet am Samstag',
            body: 'Im fiktiven Lindenhof eröffnet ein Lesegarten mit Büchertausch und Sitzplätzen.',
          ),
          (
            id: 3,
            categoryId: 2,
            title: 'Kleine Bühne für große Geschichten',
            body: 'Eine erfundene Theatergruppe lädt zu einem Abend mit kurzen Stücken ein.',
          ),
          (
            id: 2,
            categoryId: 1,
            title: 'Radwerkstatt lädt zum Mitmachen ein',
            body: 'In dieser Beispielmeldung lernen Besucher, einen Fahrradreifen zu flicken.',
          ),
          (
            id: 1,
            categoryId: 2,
            title: 'Konzert im Innenhof',
            body: 'Das fiktive Programm reicht von Kammermusik bis zu Filmmelodien.',
          ),
        ]
      : const [
          (
            id: 4,
            categoryId: 1,
            title: 'Ogród czytelniczy otwiera się w sobotę',
            body: 'W fikcyjnym miasteczku powstaje ogród z miejscem do czytania i wymiany książek.',
          ),
          (
            id: 3,
            categoryId: 2,
            title: 'Mała scena dla wielkich historii',
            body:
                'Fikcyjna grupa teatralna zaprasza na wieczór krótkich sztuk.',
          ),
          (
            id: 2,
            categoryId: 1,
            title: 'Warsztat rowerowy zaprasza',
            body: 'W przykładowym warsztacie uczestnicy uczą się naprawiać dętkę.',
          ),
          (
            id: 1,
            categoryId: 2,
            title: 'Koncert na dziedzińcu',
            body:
                'Fikcyjny program obejmuje muzykę kameralną i melodie filmowe.',
          ),
        ];
}
