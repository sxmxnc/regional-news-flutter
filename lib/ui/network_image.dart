import 'dart:math' as math;

import 'package:flutter/material.dart';

class NwbNetworkImage extends StatelessWidget {
  const NwbNetworkImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholderColor,
    super.key,
  });

  final String? url;
  final BoxFit fit;

  /// Farbe der Ausweichfläche. Ohne Angabe die Trennlinienfarbe des Themes;
  /// auf dunklem Grund — etwa hinter der weißen Schlagzeilenschrift — gibt
  /// der Aufrufer die dunkle Fläche vor, damit der Text lesbar bleibt.
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    final String? source = url;
    if (source == null) return _placeholder(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double ratio = MediaQuery.devicePixelRatioOf(context);
        final double width = constraints.maxWidth;
        // Unbeschränkte Breite (etwa in einer Zeile ohne feste Größe) lässt
        // sich nicht umrechnen — dann bleibt es bei der vollen Auflösung.
        final int? cacheWidth = width.isFinite && width > 0
            ? math.max(1, (width * ratio).round())
            : null;

        return Image.network(
          source,
          fit: fit,
          cacheWidth: cacheWidth,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stack,
          ) => _placeholder(context),
          loadingBuilder: (
            BuildContext context,
            Widget child,
            ImageChunkEvent? progress,
          ) => progress == null ? child : _placeholder(context),
        );
      },
    );
  }

  Widget _placeholder(BuildContext context) =>
      ColoredBox(color: placeholderColor ?? Theme.of(context).dividerColor);
}
