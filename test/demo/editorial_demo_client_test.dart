import 'package:flutter_test/flutter_test.dart';
import 'package:regional_news_app/api/wp_client.dart';
import 'package:regional_news_app/core/app_language.dart';
import 'package:regional_news_app/demo/editorial_demo_client.dart';

void main() {
  test(
    'serves separate language feeds, search and article details offline',
    () async {
      final EditorialDemoClient client = EditorialDemoClient();
      addTearDown(client.close);
      final WpClient german = WpClient(
        httpClient: client,
        language: AppLanguage.de,
      );
      final WpClient polish = WpClient(
        httpClient: client,
        language: AppLanguage.pl,
      );
      final WpListPage results = await german.getList(
        'posts',
        query: {'search': 'Lesegarten'},
      );
      expect(results.total, 1);
      expect((await polish.getList('posts')).total, 4);
      expect((await german.getObject('posts/4'))['title'], {
        'rendered': 'Lesegarten öffnet am Samstag',
      });
      expect((await polish.getObject('posts/4'))['title'], {
        'rendered': 'Ogród czytelniczy otwiera się w sobotę',
      });
    },
  );
}
