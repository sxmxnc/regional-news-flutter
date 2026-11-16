import '../../features/settings/legal_page.dart';
import 'json_fields.dart';

abstract final class LegalPageMapper {
  static LegalPage? fromJson(Map<String, Object?> json) {
    final String? title = jsonRendered(json['title']);
    if (title == null || title.isEmpty) return null;

    return LegalPage(
      title: title,
      content: jsonRendered(json['content']) ?? '',
      link: jsonString(json['link']),
    );
  }
}
