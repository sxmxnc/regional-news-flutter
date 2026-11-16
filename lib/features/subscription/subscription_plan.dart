final class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.durationDays,
    required this.priceMinor,
    required this.currency,
    required this.type,
  });

  final int id;
  final String title;

  /// Laufzeit in Tagen (`duration`).
  final int durationDays;

  final int priceMinor;

  /// Währungskürzel, live `"PLN"`.
  final String currency;

  final String type;

  static const String physicalType = 'physical';

  bool get isPurchasableInApp => type != physicalType;

  String get displayTitle {
    final RegExpMatch? match = _priceSuffix.firstMatch(title);
    final String? stem = match?.group(1)?.trim();
    return stem == null || stem.isEmpty ? title : stem;
  }

  static final RegExp _priceSuffix = RegExp(
    r'^(.*?)\s*[-–—]\s*[0-9]+(?:[.,][0-9]{1,2})?\s*(?:PLN|z\u0142)?\s*$',
    caseSensitive: false,
  );

  /// `10,00 PLN` — Groschen durch 100, zwei Nachkommastellen, Komma. Die
  /// Schreibweise ist in beiden Sprachen gleich (Website: „60,00 PLN").
  String get priceLabel {
    final int whole = priceMinor ~/ 100;
    final int fraction = priceMinor % 100;
    return '$whole,${fraction.toString().padLeft(2, '0')} $currency';
  }

  @override
  String toString() => 'SubscriptionPlan($id, $title, $priceLabel)';
}
