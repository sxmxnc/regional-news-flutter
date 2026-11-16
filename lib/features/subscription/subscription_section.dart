import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time_format.dart';
import '../../i18n/translations.dart';
import '../../ui/theme/app_theme.dart';
import '../epaper/epaper_screen.dart';
import 'payments_switch.dart';
import 'plans_screen.dart';
import 'print_order_screen.dart';
import 'subscription_status.dart';

class SubscriptionSection extends ConsumerWidget {
  const SubscriptionSection({required this.status, super.key});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    final ThemeData theme = Theme.of(context);
    final bool paymentsEnabled = ref.watch(paymentsEnabledProvider);
    final DateTime? expiresAt = status.expiresAt;

    final String stateLabel = switch (status.state) {
      SubscriptionState.active => texts['subscription_status_active'],
      SubscriptionState.expired => texts['subscription_status_expired'],
      SubscriptionState.inactive => texts['subscription_status_inactive'],
    };
    final String dateLabel = status.state == SubscriptionState.expired
        ? texts['subscription_expired_label']
        : texts['subscription_expires_label'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          texts['subscription_section_title'],
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _InfoTable(
          rows: <(String, String)>[
            (texts['subscription_status_label'], stateLabel),
            if (expiresAt != null) (dateLabel, formatWarsawDate(expiresAt)),
            if (status.planName case final String planName)
              (texts['subscription_plan_label'], planName),
          ],
        ),
        const SizedBox(height: 12),
        if (paymentsEnabled)
          _SubscriptionActionButton(
            icon: Icons.workspace_premium_outlined,
            label:
                texts[status.isActive
                    ? 'subscription_extend_action'
                    : 'subscription_buy_action'],
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PlansScreen()),
            ),
          )
        else
          Text(
            texts['subscription_payments_disabled'],
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: 8),
        _SubscriptionActionButton(
          icon: Icons.menu_book_outlined,
          label: texts['subscription_epaper_action'],
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const EpaperScreen())),
        ),
        const SizedBox(height: 8),
        _SubscriptionActionButton(
          icon: Icons.local_shipping_outlined,
          label: texts['print_order_action'],
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PrintOrderScreen()),
          ),
        ),
      ],
    );
  }
}

/// Einheitliche Gestalt für die drei Aktionen des Abo-Bereichs (Verlängern/
/// Kaufen, E-Paper, Printbestellung): helle Fläche mit rotem Rand, Symbol
/// und Text in Markenrot — statt einer vollflächig roten, runden
/// Schaltfläche neben zwei unscheinbaren Zeilen. Die Farbe kommt aus
/// `colorScheme.primary` (`app_theme.dart`), nicht als eigener Wert hier
/// (README.md, Konventionen).
class _SubscriptionActionButton extends StatelessWidget {
  const _SubscriptionActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _InfoTable extends StatelessWidget {
  const _InfoTable({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Table(
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <TableRow>[
        for (final (String label, String value) in rows)
          TableRow(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 4),
                child: Text(
                  label,
                  style: text.bodyMedium?.copyWith(color: NwbColors.muted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(value, style: text.bodyMedium),
              ),
            ],
          ),
      ],
    );
  }
}
