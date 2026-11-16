import '../../config/app_config.dart';
import '../../core/app_language.dart';

({AppLanguage language, String slug})? internalArticleLink(String url) {
  final Uri? target = Uri.tryParse(url);
  if (target == null || target.host.isEmpty) return null;

  final Uri host = Uri.parse(AppConfig.host);
  if (target.host != host.host) return null;

  final List<String> segments = target.pathSegments
      .where((String segment) => segment.isNotEmpty)
      .toList(growable: false);
  if (segments.isEmpty) return null;

  // `AppLanguage.de.pathPrefix` ist `/de` (Regel 3) — ohne den führenden
  // Schrägstrich ist das genau das erste Pfadglied deutscher Adressen.
  final String germanPrefix = AppLanguage.de.pathPrefix.substring(1);
  final bool german = segments.first == germanPrefix;
  final List<String> rest = german ? segments.skip(1).toList() : segments;
  if (rest.isEmpty) return null;

  return (language: german ? AppLanguage.de : AppLanguage.pl, slug: rest.first);
}
