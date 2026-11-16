import '../../features/content/taxonomy.dart';
import 'json_fields.dart';

abstract final class TaxonomyMapper {
  static TaxonomyTerm? fromJson(Map<String, Object?> json) {
    final int? id = jsonInt(json['id']);
    final String? name = jsonPlainText(json['name']);
    if (id == null || name == null) return null;
    final Map<String, Object?> menu = jsonMap(json['editorial_menu']);
    return TaxonomyTerm(
      id: id,
      name: name,
      // Fehlt der Slug wider Erwarten, bleibt er leer statt den ganzen
      // Begriff zu verwerfen — er passt dann bei keiner sprachübergreifenden
      // Zuordnung, was sicherer ist als eine falsche Zuordnung.
      slug: jsonString(json['slug']) ?? '',
      count: jsonInt(json['count']),
      inMenu: menu['in_menu'] is bool ? menu['in_menu']! as bool : null,
      menuPosition: jsonInt(menu['position']),
      menuLabel: jsonPlainText(menu['label']),
      translations: _translations(json['editorial_translations']),
    );
  }

  static List<TaxonomyTerm> fromList(List<Map<String, Object?>> json) {
    return json.map(fromJson).whereType<TaxonomyTerm>().toList(growable: false);
  }

  static Map<String, int> _translations(Object? value) {
    final Map<String, Object?> entries = jsonMap(
      jsonMap(value)['translations'],
    );
    final Map<String, int> result = <String, int>{};
    entries.forEach((String code, Object? entry) {
      final Map<String, Object?> map = jsonMap(entry);
      if (map['available'] != true) return;
      final int? id = jsonInt(map['id']);
      if (id != null) result[code] = id;
    });
    return Map<String, int>.unmodifiable(result);
  }
}
