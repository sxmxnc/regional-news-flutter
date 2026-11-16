import '../../core/time_format.dart';
import '../../features/subscription/payment.dart';
import '../../features/subscription/subscription_plan.dart';
import '../../features/subscription/subscription_status.dart';
import 'json_fields.dart';

abstract final class SubscriptionMapper {
  static SubscriptionStatus fromUser(Map<String, Object?>? block) {
    if (block == null) return const SubscriptionStatus.none();
    final SubscriptionState state = switch (block['status']) {
      'active' => SubscriptionState.active,
      'expired' => SubscriptionState.expired,
      _ => SubscriptionState.inactive,
    };
    return SubscriptionStatus(
      state: state,
      expiresAt: _instantFromIso(block['expires_at']),
      planId: jsonInt(block['plan_id']),
      planName: jsonString(block['plan_name']),
    );
  }

  static SubscriptionStatus fromConfirm(
    Map<String, Object?>? block, {
    DateTime? now,
  }) {
    if (block == null) return const SubscriptionStatus.none();
    final DateTime? expiresAt = _instantFromDay(block['expires_at']);
    final SubscriptionState state = switch (block['status']) {
      true => SubscriptionState.active,
      _ when expiresAt != null && expiresAt.isBefore(now ?? DateTime.now()) =>
        SubscriptionState.expired,
      _ => SubscriptionState.inactive,
    };
    return SubscriptionStatus(
      state: state,
      expiresAt: expiresAt,
      planId: jsonInt(block['plan_id']),
      planName: jsonString(block['plan_name']),
    );
  }

  /// `plans[] {id, title, duration, price, currency, type}`. Pflicht sind
  /// `id` und `title`; ein Eintrag ohne eines von beiden wird übersprungen.
  static List<SubscriptionPlan> plansFromJson(Map<String, Object?> json) {
    final List<SubscriptionPlan> result = <SubscriptionPlan>[];
    for (final Object? entry in jsonList(json['plans'])) {
      if (entry is! Map<String, Object?>) continue;
      final int? id = jsonInt(entry['id']);
      final String? title = jsonString(entry['title']);
      if (id == null || title == null) continue;
      result.add(
        SubscriptionPlan(
          id: id,
          title: title,
          durationDays: jsonInt(entry['duration']) ?? 0,
          priceMinor: jsonInt(entry['price']) ?? 0,
          currency: jsonString(entry['currency']) ?? 'PLN',
          type: jsonString(entry['type']) ?? 'digital',
        ),
      );
    }
    return result;
  }

  /// `{ token, payment_id, is_sandbox }` — `null`, wenn Token oder
  /// Zahlungskennung fehlen; ohne beide ist keine Einlösung möglich.
  static PaymentRegistration? registrationFromJson(Map<String, Object?> json) {
    final String? token = jsonString(json['token']);
    final Object? paymentId = json['payment_id'];
    if (token == null || paymentId == null) return null;
    return PaymentRegistration(
      token: token,
      paymentId: paymentId,
      // Fehlt das Feld, gilt Echtbetrieb — der sicherere Irrtum: Eine Zahlung
      // im Echtbetrieb an den Sandkasten zu schicken, scheitert sichtbar;
      // umgekehrt könnte Geld fließen, das die App für einen Test hielt.
      isSandbox: json['is_sandbox'] == true,
    );
  }

  /// `{payment_status: "pending"}` oder `{payment_status: "accepted",
  /// subscription{…}}`. Alles außer `accepted` gilt als ausstehend.
  static PaymentConfirmation confirmationFromJson(Map<String, Object?> json) {
    if (json['payment_status'] != 'accepted') {
      return const PaymentConfirmation.pending();
    }
    return PaymentConfirmation.accepted(
      fromConfirm(jsonMapOrNull(json['subscription'])),
    );
  }

  static DateTime? _instantFromIso(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    // `DateTime.parse` liest den Zeitzonenversatz („+02:00") mit und liefert
    // einen UTC-Zeitpunkt; ohne Versatz wäre es Gerätezeit — dann gilt
    // der Rückfall auf die Warschauer Wanduhr.
    final DateTime? parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return null;
    if (parsed.isUtc) return parsed;
    return fromWarsawWallClock(parsed);
  }

  /// `"Y-m-d"` als **Warschauer Kalendertag** — Beginn des Tages als
  /// Zeitpunkt, damit `formatWarsawDate` denselben Tag anzeigt, unabhängig von
  /// der Gerätezeitzone (README.md, Konventionen).
  static DateTime? _instantFromDay(Object? value) {
    if (value is! String) return null;
    final RegExpMatch? match = _dayPattern.firstMatch(value.trim());
    if (match == null) return _instantFromIso(value);
    return warsawDayStart(
      DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      ),
    );
  }

  static final RegExp _dayPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
}
