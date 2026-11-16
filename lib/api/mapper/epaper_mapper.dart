import '../../features/epaper/epaper_issue.dart';
import '../../features/epaper/epaper_year.dart';
import 'json_fields.dart';

abstract final class EpaperMapper {
  static List<EpaperYear> yearsFromJson(Map<String, Object?> json) {
    final List<EpaperYear> result = <EpaperYear>[];
    for (final Object? entry in jsonList(json['years'])) {
      if (entry is! Map<String, Object?>) continue;
      final int? id = jsonInt(entry['id']);
      final String? title = jsonString(entry['title']);
      if (id == null || title == null) continue;
      result.add(EpaperYear(id: id, title: title));
    }
    result.sort((EpaperYear a, EpaperYear b) => b.title.compareTo(a.title));
    return result;
  }

  static String? _saubererTitel(Object? value) {
    if (value is! String) return null;
    final String sauber = value
        .replaceAll('\u00c2\u00a0', ' ')
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return sauber.isEmpty ? null : sauber;
  }

  static List<EpaperIssue> issuesFromJson(Map<String, Object?> json) {
    final List<EpaperIssue> result = <EpaperIssue>[];
    for (final Object? entry in jsonList(json['links'])) {
      if (entry is! Map<String, Object?>) continue;
      final String? title = _saubererTitel(entry['title']);
      if (title == null) continue;
      final String? href = jsonString(entry['href']);
      final Uri? parsed = href == null ? null : Uri.tryParse(href);
      result.add(
        EpaperIssue(
          title: title,
          href: parsed != null && parsed.hasScheme ? parsed : null,
        ),
      );
    }
    return result;
  }
}
