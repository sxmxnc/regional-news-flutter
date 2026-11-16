import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parseFragment;

import '../../ui/network_image.dart';
import '../../ui/theme/app_theme.dart';
import 'related_articles.dart' show nodeHtml;

final RegExp _imgTag = RegExp(r'<img\b[^>]*>', caseSensitive: false);
final RegExp _widthAttr = RegExp(
  r'''\bwidth\s*=\s*["'](\d+)["']''',
  caseSensitive: false,
);
final RegExp _heightAttr = RegExp(
  r'''\bheight\s*=\s*["'](\d+)["']''',
  caseSensitive: false,
);
final RegExp _dimensionAttribute = RegExp(
  r'''\s+(?:width|height)\s*=\s*(?:"[^"]*"|'[^']*')''',
  caseSensitive: false,
);
final RegExp _styleAttr = RegExp(
  r'''style\s*=\s*"([^"]*)"''',
  caseSensitive: false,
);

final RegExp _widthDeclaration = RegExp(
  r'''(?<![-\w])width\s*:\s*[\d.]+[a-z%]*\s*;?\s*''',
  caseSensitive: false,
);

String sanitizeArticleHtml(String html, {required double maxWidth}) {
  if (!html.contains('<img') && !html.contains('style=')) return html;

  String result = html;
  if (result.contains('<img')) {
    result = result.replaceAllMapped(
      _imgTag,
      (Match match) => _rescaleImageTag(match.group(0)!, maxWidth),
    );
  }
  if (result.contains('style=')) {
    result = result.replaceAllMapped(_styleAttr, _stripWidthFromStyle);
  }
  return result;
}

String _rescaleImageTag(String tag, double maxWidth) {
  final int? width = _attrValue(_widthAttr, tag);
  final int? height = _attrValue(_heightAttr, tag);
  if (width == null || height == null || width <= maxWidth) return tag;

  final int scaledWidth = maxWidth.floor();
  final int scaledHeight = (height * maxWidth / width).round();
  return tag
      .replaceAll(_dimensionAttribute, '')
      .replaceFirst('<img', '<img width="$scaledWidth" height="$scaledHeight"');
}

int? _attrValue(RegExp pattern, String tag) {
  final String? raw = pattern.firstMatch(tag)?.group(1);
  final int? value = raw == null ? null : int.tryParse(raw);
  return value != null && value > 0 ? value : null;
}

String _stripWidthFromStyle(Match match) {
  final String declarations = match.group(1)!;
  if (!_widthDeclaration.hasMatch(declarations)) return match.group(0)!;

  final String cleaned = declarations.replaceAll(_widthDeclaration, '').trim();
  return cleaned.isEmpty ? '' : 'style="$cleaned"';
}

ImageExtension articleImageExtension(double contentWidth) {
  return ImageExtension(
    builder: (ExtensionContext context) {
      final String? src = context.attributes['src'];
      if (src == null) return const SizedBox.shrink();
      final double? width = double.tryParse(context.attributes['width'] ?? '');
      final double? height = double.tryParse(
        context.attributes['height'] ?? '',
      );
      final double aspectRatio = (width != null && height != null && height > 0)
          ? width / height
          : 16 / 9;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: contentWidth,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: NwbNetworkImage(url: src),
            ),
          ),
        ),
      );
    },
  );
}

final RegExp _priceLike = RegExp(
  r'\d[\d.,]*\s*(?:EUR|EURO|PLN|ZŁ)',
  caseSensitive: false,
);

({String before, String after}) splitBeforeFirstPrice(String html) {
  final dom.DocumentFragment fragment = parseFragment(html);
  final List<dom.Node> nodes = fragment.nodes.toList(growable: false);

  int splitIndex = nodes.length;
  for (int i = 0; i < nodes.length; i++) {
    if (_priceLike.hasMatch(nodes[i].text ?? '')) {
      splitIndex = i;
      break;
    }
  }

  String render(Iterable<dom.Node> slice) => slice.map(nodeHtml).join();

  return (
    before: render(nodes.take(splitIndex)),
    after: render(nodes.skip(splitIndex)),
  );
}

TagWrapExtension blockquoteExtension(double contentWidth) {
  final Widget line = SizedBox(
    width: contentWidth * 0.4,
    child: const Divider(
      height: 1,
      thickness: 1,
      color: NwbColors.quoteDivider,
    ),
  );
  return TagWrapExtension(
    tagsToWrap: <String>{'blockquote'},
    builder: (Widget child) {
      return Column(
        children: <Widget>[
          line,
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 8),
          line,
        ],
      );
    },
  );
}
