final class LegalPage {
  const LegalPage({required this.title, required this.content, this.link});

  final String title;

  /// Bereits aufgelöstes HTML, wie `content.rendered` es liefert.
  final String content;

  final String? link;
}
