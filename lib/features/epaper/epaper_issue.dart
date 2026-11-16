final class EpaperIssue {
  const EpaperIssue({required this.title, required this.href});

  final String title;

  final Uri? href;

  bool get isAvailable => href != null;

  @override
  String toString() =>
      'EpaperIssue($title, ${href == null ? 'ohne' : 'mit'} href)';
}
