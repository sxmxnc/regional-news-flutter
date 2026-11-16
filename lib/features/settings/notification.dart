final class NotificationCategory {
  const NotificationCategory({
    required this.id,
    required this.title,
    required this.subscribed,
  });

  final int id;
  final String title;
  final bool subscribed;

  bool get isEpaper => id == -1;

  NotificationCategory copyWith({bool? subscribed}) => NotificationCategory(
    id: id,
    title: title,
    subscribed: subscribed ?? this.subscribed,
  );
}
