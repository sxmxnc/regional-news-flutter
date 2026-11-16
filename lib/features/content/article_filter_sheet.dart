import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../core/time_format.dart';
import '../../i18n/translations.dart';
import 'taxonomy.dart';
import 'taxonomy_queries.dart';

final class ArticleFilter {
  const ArticleFilter({
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.authorId,
    this.authorName,
    this.dateFrom,
    this.dateTo,
  });

  static const ArticleFilter empty = ArticleFilter();

  final int? categoryId;

  final String? categoryName;

  final String? categorySlug;
  final int? authorId;
  final String? authorName;

  final DateTime? dateFrom;

  /// Obere Grenze (einschließlich) — das **Ende des Warschauer
  /// Kalendertages** (`warsawDayEnd`), damit der gewählte letzte Tag
  /// vollständig mitzählt.
  final DateTime? dateTo;

  bool get isEmpty =>
      categoryId == null &&
      authorId == null &&
      dateFrom == null &&
      dateTo == null;

  /// Überschrift der Ergebnisliste: die gewählten Merkmale, durch einen
  /// Mittelpunkt getrennt. Leer, wenn nur ein Zeitraum gewählt wurde — dann
  /// entscheidet der Aufrufer über einen Ersatztext.
  String get label => <String>[
    if (categoryName case final String name when name.isNotEmpty) name,
    if (authorName case final String name when name.isNotEmpty) name,
  ].join(' · ');
}

/// Öffnet die Filterfläche als Bogen von unten. Liefert `null`, wenn
/// abgebrochen wurde, sonst die getroffene Auswahl — leer, wenn der Nutzer
/// alles zurückgesetzt hat.
Future<ArticleFilter?> showArticleFilterSheet(
  BuildContext context, {
  required AppLanguage language,
}) {
  return showModalBottomSheet<ArticleFilter>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ArticleFilterSheet(language: language),
  );
}

class _ArticleFilterSheet extends ConsumerStatefulWidget {
  const _ArticleFilterSheet({required this.language});

  final AppLanguage language;

  @override
  ConsumerState<_ArticleFilterSheet> createState() =>
      _ArticleFilterSheetState();
}

class _ArticleFilterSheetState extends ConsumerState<_ArticleFilterSheet> {
  int? _categoryId;
  String? _categoryName;
  String? _categorySlug;
  int? _authorId;
  String? _authorName;

  /// Warschauer Kalendertage (`warsawDayStart`/`warsawDayEnd`), nicht
  /// Gerätezeit — siehe [ArticleFilter.dateFrom].
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  Widget build(BuildContext context) {
    final Translations texts = ref.watch(translationsProvider);
    final AsyncValue<List<TaxonomyTerm>> categories = ref.watch(
      menuCategoryListProvider(MenuCategoryKey(widget.language)),
    );
    final AsyncValue<List<TaxonomyTerm>> authors = ref.watch(
      taxonomyListProvider(
        TaxonomyListKey(widget.language, TaxonomyResource.authors),
      ),
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              texts['filter_title'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _TermDropdown(
              label: texts['filter_category_label'],
              allLabel: texts['filter_all_categories'],
              terms: categories,
              selectedId: _categoryId,
              onChanged: (TaxonomyTerm? term) => setState(() {
                _categoryId = term?.id;
                _categoryName = term?.displayName;
                _categorySlug = term?.slug;
              }),
            ),
            const SizedBox(height: 12),
            _TermDropdown(
              label: texts['filter_author_label'],
              allLabel: texts['filter_all_authors'],
              terms: authors,
              selectedId: _authorId,
              onChanged: (TaxonomyTerm? term) => setState(() {
                _authorId = term?.id;
                _authorName = term?.name;
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _DateField(
                    label: texts['filter_date_from_label'],
                    value: _dateFrom,
                    lastDay: _dateTo,
                    onPick: (DateTime day) =>
                        setState(() => _dateFrom = warsawDayStart(day)),
                    onClear: () => setState(() => _dateFrom = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: texts['filter_date_to_label'],
                    value: _dateTo,
                    firstDay: _dateFrom,
                    onPick: (DateTime day) =>
                        setState(() => _dateTo = warsawDayEnd(day)),
                    onClear: () => setState(() => _dateTo = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(ArticleFilter.empty),
                    child: Text(texts['filter_reset']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      ArticleFilter(
                        categoryId: _categoryId,
                        categoryName: _categoryName,
                        categorySlug: _categorySlug,
                        authorId: _authorId,
                        authorName: _authorName,
                        dateFrom: _dateFrom,
                        dateTo: _dateTo,
                      ),
                    ),
                    child: Text(texts['filter_apply']),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TermDropdown extends StatelessWidget {
  const _TermDropdown({
    required this.label,
    required this.allLabel,
    required this.terms,
    required this.selectedId,
    required this.onChanged,
  });

  final String label;
  final String allLabel;
  final AsyncValue<List<TaxonomyTerm>> terms;
  final int? selectedId;
  final ValueChanged<TaxonomyTerm?> onChanged;

  @override
  Widget build(BuildContext context) {
    final List<TaxonomyTerm> values = terms.value ?? const <TaxonomyTerm>[];

    // Ein zwischenzeitlich verschwundener Begriff darf die Fläche nicht zum
    // Absturz bringen — dann gilt „Alle …" wieder.
    final bool selectionExists = values.any(
      (TaxonomyTerm t) => t.id == selectedId,
    );

    return DropdownButtonFormField<int?>(
      initialValue: selectionExists ? selectedId : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: <DropdownMenuItem<int?>>[
        DropdownMenuItem<int?>(child: Text(allLabel)),
        for (final TaxonomyTerm term in values)
          DropdownMenuItem<int?>(value: term.id, child: Text(term.displayName)),
      ],
      onChanged: values.isEmpty
          ? null
          : (int? id) {
              if (id == null) {
                onChanged(null);
                return;
              }
              for (final TaxonomyTerm term in values) {
                if (term.id == id) {
                  onChanged(term);
                  return;
                }
              }
            },
    );
  }
}

/// Ein Datumsfeld des Zeitraumfilters. Nach außen arbeitet es mit
/// **Zeitpunkten**, die auf einen Warschauer Kalendertag verankert sind; der
/// Datumswähler selbst kennt nur Kalendertage — die Umrechnung liegt an
/// genau einer Stelle (`lib/core/time_format.dart`).
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
    this.firstDay,
    this.lastDay,
  });

  final String label;
  final DateTime? value;

  /// [onPick] bekommt den gewählten **Kalendertag**; ob daraus der Beginn
  /// oder das Ende des Warschauer Tages wird, entscheidet der Aufrufer.
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  /// Untere und obere Grenze der Auswahl, gesetzt vom jeweils anderen Feld.
  final DateTime? firstDay;
  final DateTime? lastDay;

  static final DateTime _archiveStart = DateTime(2016);

  @override
  Widget build(BuildContext context) {
    final DateTime? current = value;
    // Alle Grenzen als Warschauer Kalendertag, damit ein Gerät in einer
    // anderen Zeitzone nicht einen Tag zu viel oder zu wenig anbietet.
    final DateTime today = warsawCalendarDay(DateTime.now());
    final DateTime first = firstDay == null
        ? _archiveStart
        : warsawCalendarDay(firstDay!);
    final DateTime last = lastDay == null ? today : warsawCalendarDay(lastDay!);

    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: current == null ? last : warsawCalendarDay(current),
          firstDate: first,
          lastDate: last,
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: current == null
              ? null
              : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
        ),
        child: Text(current == null ? '—' : formatWarsawDate(current)),
      ),
    );
  }
}
