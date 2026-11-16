import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../core/failure.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../ui/async_view.dart';
import '../../ui/nav/area_navigation_bar.dart';
import '../../ui/offline_banner.dart';
import '../../ui/theme/app_theme.dart';
import '../account/account_queries.dart';
import '../account/user_profile.dart';
import '../subscription/payments_switch.dart';
import '../subscription/plans_screen.dart';
import 'epaper_download_controller.dart';
import 'epaper_issue.dart';
import 'epaper_queries.dart';
import 'epaper_viewer_screen.dart';
import 'epaper_year.dart';

class EpaperScreen extends ConsumerStatefulWidget {
  const EpaperScreen({super.key});

  @override
  ConsumerState<EpaperScreen> createState() => _EpaperScreenState();
}

class _EpaperScreenState extends ConsumerState<EpaperScreen> {
  /// Vom Nutzer gewählter Jahrgang; `null` heißt „der neueste".
  int? _selectedYearId;

  @override
  Widget build(BuildContext context) {
    final Translations texts = ref.watch(translationsProvider);
    final AppLanguage language = ref.watch(languageProvider);
    final EpaperYearsKey yearsKey = EpaperYearsKey(language);
    final AsyncValue<List<EpaperYear>> years = ref.watch(
      epaperYearsProvider(yearsKey),
    );
    final AsyncValue<UserProfile?> profile = ref.watch(
      currentUserProvider(CurrentUserKey(language)),
    );
    final bool hasSubscription = profile.value?.subscription.isActive ?? true;

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(title: Text(texts['epaper_title'])),
      body: Column(
        children: <Widget>[
          OfflineBanner(isOffline: isOfflineWithContent(years)),
          if (!hasSubscription) const _NoSubscriptionBanner(),
          Expanded(
            child: nwbAsyncView<List<EpaperYear>>(
              years,
              onRetry: () => ref.invalidate(epaperYearsProvider(yearsKey)),
              data: (List<EpaperYear> list) {
                if (list.isEmpty) {
                  return Center(child: Text(texts['epaper_years_empty']));
                }
                final EpaperYear selected = list.firstWhere(
                  (EpaperYear y) => y.id == _selectedYearId,
                  orElse: () => list.first,
                );
                return Column(
                  children: <Widget>[
                    _YearChips(
                      years: list,
                      selected: selected,
                      onSelected: (EpaperYear year) =>
                          setState(() => _selectedYearId = year.id),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _IssueList(language: language, year: selected),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSubscriptionBanner extends ConsumerWidget {
  const _NoSubscriptionBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    final bool paymentsEnabled = ref.watch(paymentsEnabledProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colors.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(texts['epaper_no_subscription_hint']),
          if (paymentsEnabled) ...<Widget>[
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PlansScreen()),
              ),
              child: Text(texts['subscription_buy_action']),
            ),
          ],
        ],
      ),
    );
  }
}

class _YearChips extends StatelessWidget {
  const _YearChips({
    required this.years,
    required this.selected,
    required this.onSelected,
  });

  final List<EpaperYear> years;
  final EpaperYear selected;
  final void Function(EpaperYear year) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kMinTouchTarget + 16,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: years.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final EpaperYear year = years[index];
          return ChoiceChip(
            label: Text(year.title),
            selected: year.id == selected.id,
            onSelected: (_) => onSelected(year),
          );
        },
      ),
    );
  }
}

class _IssueList extends ConsumerWidget {
  const _IssueList({required this.language, required this.year});

  final AppLanguage language;
  final EpaperYear year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    final EpaperIssuesKey key = EpaperIssuesKey(language, year.id);
    final AsyncValue<List<EpaperIssue>> issues = ref.watch(
      epaperIssuesProvider(key),
    );
    return nwbAsyncView<List<EpaperIssue>>(
      issues,
      onRetry: () => ref.invalidate(epaperIssuesProvider(key)),
      data: (List<EpaperIssue> list) {
        if (list.isEmpty) {
          return Center(child: Text(texts['epaper_issues_empty']));
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            final EpaperIssue issue = list[index];
            final Uri? href = issue.href;
            if (href == null) return _LockedIssueTile(issue: issue);
            return _IssueTile(issue: issue, yearId: year.id, href: href);
          },
        );
      },
    );
  }
}

/// `href: null` — kein Abo. Antippen zeigt den Kaufhinweis statt der Ausgabe.
class _LockedIssueTile extends ConsumerWidget {
  const _LockedIssueTile({required this.issue});

  final EpaperIssue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    return ListTile(
      leading: const Icon(Icons.lock_outline),
      title: Text(issue.title),
      onTap: () => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(texts['epaper_locked_hint']))),
    );
  }
}

class _IssueTile extends ConsumerWidget {
  const _IssueTile({
    required this.issue,
    required this.yearId,
    required this.href,
  });

  final EpaperIssue issue;
  final int yearId;
  final Uri href;

  static String _megabytes(int bytes) =>
      (bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    final EpaperDownloadKey key = (yearId: yearId, href: href);
    final EpaperDownloadState state = ref.watch(epaperDownloadProvider(key));
    final EpaperDownloadController controller = ref.read(
      epaperDownloadProvider(key).notifier,
    );

    return switch (state) {
      EpaperNotDownloaded() => ListTile(
        leading: const Icon(Icons.picture_as_pdf_outlined),
        title: Text(issue.title),
        trailing: IconButton(
          tooltip: texts['epaper_download_action'],
          icon: const Icon(Icons.download_outlined),
          onPressed: controller.download,
        ),
        onTap: controller.download,
      ),
      final EpaperDownloading progress => ListTile(
        leading: const Icon(Icons.picture_as_pdf_outlined),
        title: Text(issue.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 4),
            LinearProgressIndicator(value: progress.fraction),
            const SizedBox(height: 4),
            Text(
              progress.total == null
                  ? texts.format(
                      'epaper_downloading_unknown_hint',
                      <String, Object?>{
                        'received': _megabytes(progress.received),
                      },
                    )
                  : texts.format('epaper_downloading_hint', <String, Object?>{
                      'received': _megabytes(progress.received),
                      'total': _megabytes(progress.total!),
                    }),
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: texts['epaper_cancel_action'],
          icon: const Icon(Icons.close),
          onPressed: controller.cancel,
        ),
      ),
      final EpaperDownloaded downloaded => ListTile(
        leading: const Icon(Icons.picture_as_pdf),
        title: Text(issue.title),
        subtitle: Text(texts['epaper_on_device_hint']),
        trailing: IconButton(
          tooltip: texts['epaper_delete_action'],
          icon: const Icon(Icons.delete_outline),
          onPressed: controller.delete,
        ),
        // Der Betrachter bekommt die Datei — nie die Adresse.
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                EpaperViewerScreen(file: downloaded.file, title: issue.title),
          ),
        ),
      ),
      final EpaperDownloadFailed failed => ListTile(
        leading: const Icon(Icons.picture_as_pdf_outlined),
        title: Text(issue.title),
        subtitle: Text(
          texts[failureMessageKey(failed.error)],
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        trailing: IconButton(
          tooltip: texts['retry'],
          icon: const Icon(Icons.refresh),
          onPressed: controller.download,
        ),
        onTap: controller.download,
      ),
    };
  }
}
