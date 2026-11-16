import 'subscription_status.dart';

final class PaymentRegistration {
  const PaymentRegistration({
    required this.token,
    required this.paymentId,
    required this.isSandbox,
  });

  final String token;

  /// Kennung der Zahlungszeile. **Unverändert** zurückgeben an
  /// `POST /subscription/confirm` — der Typ (Zahl oder Text) ist nicht
  /// belegt, deshalb wird der JSON-Wert so gehalten, wie er kam.
  final Object paymentId;

  final bool isSandbox;
}

final class PaymentConfirmation {
  const PaymentConfirmation.pending() : accepted = false, subscription = null;

  const PaymentConfirmation.accepted(SubscriptionStatus this.subscription)
    : accepted = true;

  final bool accepted;

  /// Nur bei `accepted` gesetzt.
  final SubscriptionStatus? subscription;
}
