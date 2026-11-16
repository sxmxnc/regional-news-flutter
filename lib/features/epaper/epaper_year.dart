final class EpaperYear {
  const EpaperYear({required this.id, required this.title});

  final int id;

  /// Live die Jahreszahl als Text („2026"). Sortiert wird am Text, nicht an
  /// einer herausgelesenen Zahl — Titel sind Redaktionssache.
  final String title;

  @override
  String toString() => 'EpaperYear($id, $title)';
}
