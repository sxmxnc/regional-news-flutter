import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../i18n/translations.dart';
import '../../ui/nav/area_navigation_bar.dart';
import '../../ui/theme/app_theme.dart';
import '../account/account_widgets.dart';
import 'payment_controller.dart';
import 'payments_switch.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Nur wenn die Zahlungsseite offen war — sonst prüfte jede Rückkehr aus
    // einer anderen App einen Stand, den es noch nicht gibt.
    if (ref.read(paymentControllerProvider).phase ==
        PaymentPhase.awaitingReturn) {
      ref.read(paymentControllerProvider.notifier).checkStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Translations texts = ref.watch(translationsProvider);
    final PaymentState payment = ref.watch(paymentControllerProvider);
    final bool paymentsEnabled = ref.watch(paymentsEnabledProvider);
    final PaymentController controller = ref.read(
      paymentControllerProvider.notifier,
    );
    final TextTheme text = Theme.of(context).textTheme;

    final List<Widget> children = <Widget>[];
    switch (payment.phase) {
      case PaymentPhase.idle:
        break;
      case PaymentPhase.registering:
        children.addAll(<Widget>[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          Text(
            texts['subscription_payment_registering'],
            textAlign: TextAlign.center,
          ),
        ]);
      case PaymentPhase.awaitingReturn:
        children.add(Text(texts['subscription_payment_waiting']));
      case PaymentPhase.openFailed:
        children.add(
          AccountErrorText(texts['subscription_payment_open_failed']),
        );
      case PaymentPhase.checking:
        children.addAll(<Widget>[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          Text(
            texts['subscription_payment_checking'],
            textAlign: TextAlign.center,
          ),
        ]);
      case PaymentPhase.pending:
        children.add(Text(texts['subscription_payment_pending']));
      case PaymentPhase.accepted:
        children.addAll(<Widget>[
          const Icon(
            Icons.check_circle_outline,
            size: 48,
            color: NwbColors.brand,
          ),
          const SizedBox(height: 16),
          Text(
            texts['subscription_payment_accepted'],
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
        ]);
      case PaymentPhase.failed:
        children.add(
          AccountErrorText(
            paymentsEnabled
                ? texts[failureMessageKey(payment.error ?? Object())]
                : texts['subscription_payments_disabled'],
          ),
        );
    }

    if (payment.canCheck && paymentsEnabled) {
      children.addAll(<Widget>[
        const SizedBox(height: 16),
        AccountSubmitButton(
          label: texts['subscription_payment_check_action'],
          isLoading: false,
          onPressed: controller.checkStatus,
        ),
      ]);
      if (payment.phase == PaymentPhase.openFailed ||
          payment.phase == PaymentPhase.awaitingReturn) {
        children.addAll(<Widget>[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: controller.reopen,
            child: Text(texts['subscription_payment_reopen_action']),
          ),
        ]);
      }
    }
    final bool laeuft =
        payment.phase == PaymentPhase.registering ||
        payment.phase == PaymentPhase.checking;
    if (!laeuft && payment.phase != PaymentPhase.idle) {
      children.addAll(<Widget>[
        const SizedBox(height: 16),
        AccountSubmitButton(
          label: texts['subscription_payment_done_action'],
          isLoading: false,
          onPressed: () {
            controller.reset();
            Navigator.of(context)
                .popUntil((Route<void> route) => route.isFirst);
          },
        ),
      ]);
    }

    return Scaffold(
      bottomNavigationBar: const AreaNavigationBar(),
      appBar: AppBar(title: Text(texts['subscription_payment_title'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
