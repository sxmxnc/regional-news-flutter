import 'article.dart';

List<Article> selectHeadline(List<Article> latest, {int count = 3}) {
  return latest
      .where((Article article) => article.imageUrl != null)
      .take(count)
      .toList(growable: false);
}

List<Article> selectList(
  List<Article> latest,
  List<Article> headline, {
  required int count,
}) {
  final int? leadId = headline.isEmpty ? null : headline.first.id;
  return latest
      .where((Article article) => article.id != leadId)
      .take(count)
      .toList(growable: false);
}
