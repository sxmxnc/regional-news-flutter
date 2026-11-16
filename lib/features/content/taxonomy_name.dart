import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import 'taxonomy.dart';
import 'taxonomy_queries.dart';

class TaxonomyName extends ConsumerWidget {
  const TaxonomyName({
    required this.language,
    required this.resource,
    required this.id,
    required this.builder,
    super.key,
  });

  final AppLanguage language;
  final String resource;
  final int id;
  final Widget Function(BuildContext context, TaxonomyTerm term) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TaxonomyTerm?> term = ref.watch(
      taxonomyTermProvider(TaxonomyTermKey(language, resource, id)),
    );
    return term.maybeWhen(
      data: (TaxonomyTerm? value) =>
          value == null ? const SizedBox.shrink() : builder(context, value),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
