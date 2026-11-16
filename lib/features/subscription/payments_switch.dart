import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<PaymentsSwitchController, bool> paymentsEnabledProvider =
    NotifierProvider<PaymentsSwitchController, bool>(
      PaymentsSwitchController.new,
    );

final class PaymentsSwitchController extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool enabled) {
    if (state != enabled) state = enabled;
  }
}
