import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../../api/mapper/notification_mapper.dart';
import '../../api/wb_client.dart';
import '../../core/app_language.dart';
import 'notification.dart';

final class NotificationRepository {
  const NotificationRepository(this._client);

  final WbClient _client;

  Future<List<NotificationCategory>> getCategories() async {
    final WbResponse response = await _client.get('notifications');
    return NotificationMapper.fromJson(response.asMap);
  }

  Future<void> register() => _client.post('notifications');

  Future<void> setCategory({required int id, required bool subscribed}) =>
      _client.post(
        'notifications/$id',
        body: <String, Object?>{'status': subscribed},
      );
}

final ProviderFamily<NotificationRepository, AppLanguage>
notificationRepositoryProvider =
    Provider.family<NotificationRepository, AppLanguage>((
      Ref ref,
      AppLanguage language,
    ) {
      return NotificationRepository(ref.watch(wbClientProvider(language)));
    });
