import 'package:flutter/material.dart';

import '../../core/time_format.dart';
import '../../ui/network_image.dart';
import 'article.dart';

/// Eine Zeile der Beitragsliste: Bild, Overline, Titel, Datum
/// (Layoutmuster (b) der Design-Referenz — Overline immer in Großbuchstaben
/// über dem Titel). Wiederverwendet in Startseite und Rubrikenliste.
class ArticleTile extends StatelessWidget {
  const ArticleTile({required this.article, required this.onTap, super.key});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 96,
                height: 72,
                child: NwbNetworkImage(url: article.imageUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (article.overline case final String overline
                      when overline.isNotEmpty)
                    Text(
                      overline.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge,
                    ),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  if (article.publishedAt case final DateTime published)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formatWarsawDate(published),
                        style: textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
