import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../../api/mapper/epaper_mapper.dart';
import '../../api/wb_client.dart';
import '../../core/app_language.dart';
import 'epaper_issue.dart';
import 'epaper_year.dart';

final class EpaperRepository {
  const EpaperRepository(this._client);

  final WbClient _client;

  Future<List<EpaperYear>> getYears() async {
    final WbResponse response = await _client.get('articles/years');
    return EpaperMapper.yearsFromJson(response.asMap);
  }

  Future<List<EpaperIssue>> getIssues({required int yearId}) async {
    final WbResponse response = await _client.get(
      'articles',
      query: <String, String>{'year_id': '$yearId'},
    );
    return EpaperMapper.issuesFromJson(response.asMap);
  }
}

final ProviderFamily<EpaperRepository, AppLanguage> epaperRepositoryProvider =
    Provider.family<EpaperRepository, AppLanguage>((
      Ref ref,
      AppLanguage language,
    ) {
      return EpaperRepository(ref.watch(wbClientProvider(language)));
    });
