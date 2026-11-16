enum SubscriptionState {
  active,

  /// Es gab ein Abo, das Ende liegt zurück.
  expired,

  /// Nie ein Abo, oder der Server nannte keinen Zustand.
  inactive,
}

final class SubscriptionStatus {
  const SubscriptionStatus({
    required this.state,
    this.expiresAt,
    this.planId,
    this.planName,
  });

  /// Der Zustand ohne jeden `subscription`-Block — kein Fehler, sondern
  /// „kein Abo".
  const SubscriptionStatus.none() : this(state: SubscriptionState.inactive);

  final SubscriptionState state;

  /// Ablaufzeitpunkt als Zeitpunkt (nicht als Text), damit die Anzeige in
  /// Warschauer Zeit erfolgt (README.md, Konventionen;
  /// `lib/core/time_format.dart`).
  final DateTime? expiresAt;

  final int? planId;

  final String? planName;

  bool get isActive => state == SubscriptionState.active;

  @override
  String toString() =>
      'SubscriptionStatus($state, expiresAt: $expiresAt, plan: $planId)';
}
