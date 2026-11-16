import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../../api/mapper/legal_page_mapper.dart';
import '../../api/wp_client.dart';
import '../../core/app_language.dart';
import 'legal_page.dart';

final class LegalPageRepository {
  const LegalPageRepository(this._client);

  final WpClient _client;

  Future<LegalPage?> getPage(String slug) async {
    final WpListPage page = await _client.getList(
      'pages',
      query: <String, String>{'slug': slug, '_fields': 'title,content,link'},
    );
    if (page.items.isEmpty) return null;
    return LegalPageMapper.fromJson(page.items.first);
  }
}

final ProviderFamily<LegalPageRepository, AppLanguage>
legalPageRepositoryProvider = Provider.family<LegalPageRepository, AppLanguage>(
  (Ref ref, AppLanguage language) {
    return LegalPageRepository(ref.watch(wpClientProvider(language)));
  },
);
