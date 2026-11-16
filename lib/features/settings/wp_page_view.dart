import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failure.dart';
import '../../i18n/translations.dart';
import '../../ui/async_view.dart';
import '../../ui/error_view.dart';
import '../../ui/external_link.dart';
import '../../ui/html_style.dart';
import '../../ui/loading_view.dart';
import '../../ui/offline_banner.dart';
import '../content/article_html.dart';
import 'legal_page.dart';

class WpPageView extends ConsumerWidget {
  const WpPageView({
    required this.page,
    required this.onRetry,
    required this.source,
    this.action,
    super.key,
  });

  final AsyncValue<LegalPage?> page;
  final VoidCallback onRetry;

  /// Name für das Protokoll, wenn ein Verweis nicht geöffnet werden kann.
  final String source;

  final Widget? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Translations texts = ref.watch(translationsProvider);
    // Innenbreite hinter dem Rand der SingleChildScrollView unten.
    const double horizontalPadding = 32;
    final double contentWidth =
        MediaQuery.sizeOf(context).width - horizontalPadding;

    return Column(
      children: <Widget>[
        OfflineBanner(isOffline: isOfflineWithContent(page)),
        Expanded(
          child: nwbAsyncView<LegalPage?>(
            page,
            onRetry: onRetry,
            loading: action == null
                ? const LoadingView()
                : _scrollable(_actionAbove(const _PlaceholderRows())),
            error: action == null
                ? null
                : (Object error) => _scrollable(
                    _actionAbove(ErrorView(error: error, onRetry: onRetry)),
                  ),
            data: (LegalPage? value) => switch (value) {
              null => _scrollable(
                _actionAbove(
                  ErrorView(error: const ContentFailure(), onRetry: onRetry),
                ),
              ),
              final LegalPage p => _scrollable(
                _content(context, texts, p, contentWidth),
              ),
            },
          ),
        ),
      ],
    );
  }

  Widget _actionAbove(Widget child) {
    if (action == null) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[action!, const SizedBox(height: 16), child],
    );
  }

  Widget _content(
    BuildContext context,
    Translations texts,
    LegalPage p,
    double contentWidth,
  ) {
    if (p.content.isEmpty) {
      return _actionAbove(
        Text(texts['empty_page'], textAlign: TextAlign.center),
      );
    }

    final String html = sanitizeArticleHtml(p.content, maxWidth: contentWidth);
    if (action == null) return _html(context, html, contentWidth);

    final (:before, :after) = splitBeforeFirstPrice(html);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (before.trim().isNotEmpty) _html(context, before, contentWidth),
        const SizedBox(height: 16),
        action!,
        if (after.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          _html(context, after, contentWidth),
        ],
      ],
    );
  }

  Widget _html(BuildContext context, String html, double contentWidth) {
    return Html(
      data: html,
      style: nwbHtmlStyle(context),
      extensions: <HtmlExtension>[articleImageExtension(contentWidth)],
      onLinkTap: (url, attributes, element) =>
          openExternalHtmlLink(url, source: source),
    );
  }

  Widget _scrollable(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

/// Platzhalter unter der Aktion, solange die Seite lädt — dieselben Zeilen
/// wie in [LoadingView], nur ohne eigene Scrollfläche (Ü-07).
class _PlaceholderRows extends StatelessWidget {
  const _PlaceholderRows();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LoadingPlaceholderRow(),
        SizedBox(height: 20),
        LoadingPlaceholderRow(),
        SizedBox(height: 20),
        LoadingPlaceholderRow(),
      ],
    );
  }
}
