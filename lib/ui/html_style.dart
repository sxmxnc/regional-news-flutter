import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'theme/app_theme.dart';

Map<String, Style> nwbHtmlStyle(BuildContext context) {
  final TextStyle body = Theme.of(context).textTheme.bodyMedium!;
  final TextStyle caption = nwbCaption(context);
  return <String, Style>{
    'body': Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      fontFamily: NwbTypography.family,
      fontSize: FontSize(body.fontSize!),
      lineHeight: LineHeight(NwbTypography.bodyHeight),
      color: NwbColors.ink,
    ),
    'a': Style(
      color: NwbColors.brand,
      textDecoration: TextDecoration.underline,
    ),
    '.wp-caption-text': Style(
      fontSize: FontSize(caption.fontSize!),
      fontStyle: FontStyle.italic,
      color: caption.color,
    ),
    'figcaption': Style(
      fontSize: FontSize(caption.fontSize!),
      fontStyle: FontStyle.italic,
      color: caption.color,
    ),
    'blockquote': Style(
      fontSize: FontSize(body.fontSize! * NwbTypography.quoteScale),
      fontWeight: FontWeight.bold,
      color: NwbColors.brand,
      textAlign: TextAlign.center,
      margin: Margins.zero,
      lineHeight: LineHeight(NwbTypography.bodyHeight),
    ),
    'blockquote p': Style(margin: Margins.zero),
  };
}
