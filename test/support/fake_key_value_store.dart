import 'package:regional_news_app/core/key_value_store.dart';

/// Ablage im Arbeitsspeicher. Damit laufen die Zustandstests ohne
/// Plattformkanal — und die Startschranke ist im Test derselbe Ablauf wie im
/// Betrieb: Werte liegen vor, bevor gelesen wird.
final class FakeKeyValueStore implements KeyValueStore {
  FakeKeyValueStore([Map<String, String>? initial])
    : _values = <String, String>{...?initial};

  final Map<String, String> _values;

  /// Lässt jedes Schreiben scheitern — eine volle oder gesperrte Ablage.
  bool failWrites = false;

  /// Was nach dem Lauf abgelegt ist — für Prüfungen auf „übersteht den
  /// Neustart".
  Map<String, String> get values => Map<String, String>.unmodifiable(_values);

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    if (failWrites) throw Exception('Ablage nicht beschreibbar');
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    if (failWrites) throw Exception('Ablage nicht beschreibbar');
    _values.remove(key);
  }
}
