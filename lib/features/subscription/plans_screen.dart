import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../i18n/translations.dart';
import '../../state/language.dart';
import '../../ui/async_view.dart';
import '../../ui/nav/area_navigation_bar.dart';
import '../../ui/offline_banner.dart';
import 'payment_controller.dart';
import 'payment_screen.dart';
import 'payments_switch.dart';
import 'subscription_plan.dart';
import 'subscription_queries.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    Translations texts,
    AppLanguage language,
    SubscriptionPlan plan,
  ) async {
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(texts['subscription_payment_hint_title']),
        content: Text(texts['subscription_payment_hint_message']),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(texts['account_cancel_action']),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(texts['subscription_payment_hint_continue']),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;
    ref
        .read(paymentControllerProvider.notifier)
        .start(language: language, plan: plan);
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const PaymentScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    final AppLanguage language = ref.watch(languageProvider);
    final bool paymentsEnabled = ref.watch(paymentsEnabledProvider);
    final SubscriptionPlansKey key = SubscriptionPlansKey(language);
    final AsyncValue<List<SubscriptionPlan>> plans = ref.watch(
      subscriptionPlansProvider(key),
    );

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(title: Text(texts['subscription_plans_title'])),
      body: !paymentsEnabled
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  texts['subscription_payments_disabled'],
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: <Widget>[
                OfflineBanner(isOffline: isOfflineWithContent(plans)),
                Expanded(
                  child: nwbAsyncView<List<SubscriptionPlan>>(
                    plans,
                    onRetry: () =>
                        ref.invalidate(subscriptionPlansProvider(key)),
                    data: (List<SubscriptionPlan> list) => ListView(
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        Text(texts['subscription_plans_intro']),
                        const SizedBox(height: 16),
                        if (list.isEmpty)
                          Text(texts['subscription_plans_empty'])
                        else
                          for (final SubscriptionPlan plan in list)
                            Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(plan.displayTitle),
                                subtitle: Text(
                                  texts.format(
                                    'subscription_plan_duration',
                                    <String, Object?>{
                                      'days': plan.durationDays,
                                    },
                                  ),
                                ),
                                trailing: Text(
                                  plan.priceLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                onTap: () => _choose(
                                  context,
                                  ref,
                                  texts,
                                  language,
                                  plan,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
