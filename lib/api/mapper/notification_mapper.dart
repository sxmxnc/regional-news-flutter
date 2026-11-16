import '../../features/settings/notification.dart';
import 'json_fields.dart';

abstract final class NotificationMapper {
  static List<NotificationCategory> fromJson(Map<String, Object?> json) {
    return jsonList(json['categories'])
        .map(_fromEntry)
        .whereType<NotificationCategory>()
        .toList(growable: false);
  }

  static NotificationCategory? _fromEntry(Object? entry) {
    final Map<String, Object?> map = jsonMap(entry);
    final int? id = jsonInt(map['id']);
    final Object? subscribed = map['subscribed'];
    if (id == null || subscribed is! bool) return null;
    return NotificationCategory(
      id: id,
      title: jsonPlainText(map['title']) ?? '',
      subscribed: subscribed,
    );
  }
}
