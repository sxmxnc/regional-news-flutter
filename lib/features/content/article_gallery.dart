import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_language.dart';
import '../../i18n/translations.dart';
import '../../ui/network_image.dart';
import '../../ui/theme/app_theme.dart';
import 'gallery.dart';
import 'gallery_queries.dart';
import 'related_articles.dart';

class ArticleGalleryView extends ConsumerStatefulWidget {
  const ArticleGalleryView({
    required this.block,
    required this.language,
    required this.contentWidth,
    super.key,
  });

  final DriveGalleryBlock block;
  final AppLanguage language;
  final double contentWidth;

  /// Höhe des Streifens im Verhältnis zur Textbreite — 3:4 liegend, also
  /// etwas höher als das 16:9 des Titelbildes, damit auch die quadratischen
  /// Aufnahmen des Bestands (1080×1080) nicht zum Briefschlitz werden.
  static const double _heightRatio = 0.75;

  /// Längste Kante der Fassung, die der Streifen lädt (`GalleryImage.sized`).
  /// 800 Bildpunkte decken die rund 270 dp Höhe auch auf einem Gerät mit
  /// dreifacher Punktdichte ab und wiegen rund 150 kB statt 4,7 MB.
  static const int _stripEdge = 800;

  @override
  ConsumerState<ArticleGalleryView> createState() => _ArticleGalleryViewState();
}

class _ArticleGalleryViewState extends ConsumerState<ArticleGalleryView> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Translations texts = ref.watch(translationsProvider);
    final GalleryKey key = GalleryKey(
      widget.language,
      accountId: widget.block.accountId,
      listToken: widget.block.listToken,
      sort: widget.block.sort,
    );
    final AsyncValue<List<GalleryImage>> state = ref.watch(
      galleryProvider(key),
    );
    final double height = widget.contentWidth * ArticleGalleryView._heightRatio;

    if (state.value case final List<GalleryImage> images) {
      // Eine Galerie ohne Bilder — der Ordner ist leer oder die Freigabe
      // wurde zurückgenommen — hinterlässt keine Lücke im Beitrag.
      if (images.isEmpty) return const SizedBox.shrink();
      return _carousel(context, texts, images, height);
    }
    if (state.hasError) return _error(context, texts, key);
    return SizedBox(
      height: height,
      child: const ColoredBox(color: NwbColors.surfaceMuted),
    );
  }

  Widget _carousel(
    BuildContext context,
    Translations texts,
    List<GalleryImage> images,
    double height,
  ) {
    final GalleryImage current = images[_index.clamp(0, images.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (int index) => setState(() => _index = index),
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                // Der Zwischenraum der Website zwischen zwei Bildern
                // (`data-gutter="10"`), hier je Seite zur Hälfte.
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: GestureDetector(
                  onTap: () => _openViewer(context, images, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: ColoredBox(
                      color: NwbColors.surfaceMuted,
                      child: NwbNetworkImage(
                        url: images[index].sized(ArticleGalleryView._stripEdge),
                        fit: BoxFit.contain,
                        placeholderColor: NwbColors.surfaceMuted,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.center,
          child: Text(
            texts.format('gallery_counter', <String, Object?>{
              'index': _index + 1,
              'total': images.length,
            }),
            style: nwbCaption(context),
          ),
        ),
        if (current.description case final String caption) ...<Widget>[
          const SizedBox(height: 4),
          Text(caption, style: nwbCaption(context)),
        ],
      ],
    );
  }

  Widget _error(BuildContext context, Translations texts, GalleryKey key) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            texts['gallery_error'],
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        TextButton(
          onPressed: () => ref.invalidate(galleryProvider(key)),
          child: Text(texts['retry']),
        ),
      ],
    );
  }

  void _openViewer(BuildContext context, List<GalleryImage> images, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            GalleryViewerScreen(images: images, initialIndex: index),
        fullscreenDialog: true,
      ),
    );
  }
}

class GalleryViewerScreen extends ConsumerStatefulWidget {
  const GalleryViewerScreen({
    required this.images,
    required this.initialIndex,
    super.key,
  });

  final List<GalleryImage> images;
  final int initialIndex;

  static const int _viewerEdge = 1024;

  @override
  ConsumerState<GalleryViewerScreen> createState() =>
      _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends ConsumerState<GalleryViewerScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Translations texts = ref.watch(translationsProvider);

    return Scaffold(
      backgroundColor: NwbColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: NwbColors.surfaceDark,
        foregroundColor: NwbColors.onBrand,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: texts['gallery_close'],
        ),
        title: Text(
          texts.format('gallery_counter', <String, Object?>{
            'index': _index + 1,
            'total': widget.images.length,
          }),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (int index) => setState(() => _index = index),
        itemBuilder: (BuildContext context, int index) {
          final GalleryImage image = widget.images[index];
          return Center(child: _ZoomableImage(image: image));
        },
      ),
      bottomNavigationBar: switch (widget.images[_index].description) {
        final String caption => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              caption,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: NwbColors.onBrand),
            ),
          ),
        ),
        _ => null,
      },
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.image});

  final GalleryImage image;

  /// Maßstab nach dem Doppeltipp. Genug, um die kleine Schrift der
  /// Programmplakate zu lesen; bis zum Vierfachen geht es von dort mit zwei
  /// Fingern weiter.
  static const double _zoomScale = 2.5;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _transformation = TransformationController();
  TapDownDetails? _tapDown;
  bool _zoomed = false;

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  /// Vergrößert um die angetippte Stelle herum, damit man dorthin kommt,
  /// wohin man getippt hat, und nicht in die Bildmitte.
  void _zoomIn() {
    const double scale = _ZoomableImage._zoomScale;
    final Offset point = _tapDown?.localPosition ?? Offset.zero;
    _transformation.value = Matrix4.identity()
      ..translateByDouble(
        -point.dx * (scale - 1),
        -point.dy * (scale - 1),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
    setState(() => _zoomed = true);
  }

  void _reset() {
    _transformation.value = Matrix4.identity();
    setState(() => _zoomed = false);
  }

  @override
  Widget build(BuildContext context) {
    final Widget image = AspectRatio(
      aspectRatio: widget.image.aspectRatio ?? 4 / 3,
      child: NwbNetworkImage(
        url: widget.image.sized(GalleryViewerScreen._viewerEdge),
        fit: BoxFit.contain,
        placeholderColor: NwbColors.surfaceDark,
      ),
    );

    if (!_zoomed) {
      return GestureDetector(
        onDoubleTapDown: (TapDownDetails details) => _tapDown = details,
        onDoubleTap: _zoomIn,
        child: image,
      );
    }

    return InteractiveViewer(
      transformationController: _transformation,
      maxScale: 4,
      child: GestureDetector(onDoubleTap: _reset, child: image),
    );
  }
}
