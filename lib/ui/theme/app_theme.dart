import 'package:flutter/material.dart';

abstract final class NwbColors {
  /// Kopfzeile, Linien, Links, Autor- und Rubrikangabe.
  static const Color brand = Color(0xFF9B2335);

  static const Color brandOverlay = Color(0xE69B2335);

  /// Fließtext.
  static const Color ink = Color(0xFF212529);

  /// Überschriften.
  static const Color heading = Color(0xFF222222);

  /// Datum, Rubrik, Sekundärtext, Bildunterschrift.
  static const Color muted = Color(0xFF767676);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF222222);
  static const Color divider = Color(0xFFDDDDDD);
  static const Color dividerStrong = Color(0xFFCCCCCC);
  static const Color onBrand = Color(0xFFFFFFFF);

  static const Color themeOfMonthBackground = Color(0xFFEBD3D7);

  static const Color authorBoxBackground = Color(0xFFF5F5F5);

  static const Color quoteDivider = Color(0xFFA8A8A8);

  /// Leichter Ton des Markenrots (12 Prozent Deckung) — Auswahlmarkierung
  /// der Symbolleiste und gewählte Auswahlchips. Wie [brandOverlay] nur
  /// eine Deckung des gemessenen Rots, keine eigene Farbe.
  static const Color brandTint = Color(0x1F9B2335);

  /// Die **einzige abgeleitete** Fläche: die Mitte zwischen [surface] und
  /// [divider], für Flächen, die Material leicht absetzt (Hinweiskasten,
  /// Laufbalken, ausgeschalteter Schalter). Die Website kennt dafür keinen
  /// eigenen Wert; ein Grau zwischen zwei gemessenen ist näher an ihr als
  /// das Rosa, das Material sonst aus dem roten Seed ableitet.
  static const Color surfaceMuted = Color(0xFFEEEEEE);

  /// Gedämpftes Weiß auf dunklem Grund — die nicht gewählten Punkte unter
  /// dem Schlagzeilenmodul.
  static const Color onBrandMuted = Color(0x62FFFFFF);

  /// Platzhaltertext im Suchfeld der Kopfzeile: [onBrand] mit 70 Prozent
  /// Deckung, damit er sich von der Eingabe absetzt. Stand vorher als
  /// Deckungsfaktor im Widget (README.md, Konventionen).
  static const Color onBrandHint = Color(0xB3FFFFFF);

  /// Abdunkelung am unteren Rand des Schlagzeilenbilds, damit der weiße
  /// Titel darauf lesbar bleibt (Layoutmuster (a) der Design-Referenz):
  /// Verlauf von durchsichtig nach 87 Prozent Schwarz.
  static const Color headlineScrimTop = Color(0x00000000);
  static const Color headlineScrimBottom = Color(0xDD000000);
}

enum NwbTextScale {
  klein(0.875, 'klein'),
  normal(1.0, 'normal'),
  gross(1.25, 'gross');

  const NwbTextScale(this.factor, this.code);

  final double factor;

  final String code;

  static NwbTextScale? tryFromCode(String? code) {
    for (final NwbTextScale scale in values) {
      if (scale.code == code) return scale;
    }
    return null;
  }
}

abstract final class NwbTypography {
  static const String family = 'Open Sans';
  static const List<String> fallback = <String>['sans-serif'];

  /// Basisgrößen beim Faktor 1,0, auf der Website gemessen.
  static const double body = 16;
  static const double bodyHeight = 24 / 16;
  static const double sectionHeading = 18;
  static const double teaserTitle = 14;
  static const double overline = 13;
  static const double caption = 12;

  static const double quoteScale = 1.15;

  /// Auf dem Telefon ist der Artikeltitel kleiner als die 32 px der
  /// Desktop-Darstellung (Design-Referenz Abschnitt 8).
  static const double articleTitle = 24;

  /// Die Flaggen-Schaltfläche zeigt ein Emoji als Symbol — in Symbolgröße,
  /// nicht in Textgröße, deshalb ohne Schriftstufe.
  static const double flagIcon = 22;
}

const double kMinTouchTarget = 48;

/// Baut das Theme für eine Schriftstufe.
ThemeData buildNwbTheme(NwbTextScale scale) {
  final double f = scale.factor;

  TextStyle style(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = NwbColors.ink,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: NwbTypography.family,
      fontFamilyFallback: NwbTypography.fallback,
      fontSize: size * f,
      fontWeight: weight,
      // Die veränderliche Schrift trägt alle Strichstärken in einer Datei. Ohne
      // die Achse `wght` bliebe es bei 400, und das System würde die fetten
      // Stufen nachahmen statt die echten Schnitte zu zeichnen.
      fontVariations: <FontVariation>[
        FontVariation('wght', weight.value.toDouble()),
      ],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  final ColorScheme colors = ColorScheme.fromSeed(
    seedColor: NwbColors.brand,
    primary: NwbColors.brand,
    onPrimary: NwbColors.onBrand,
    // Hervorgehobene Schaltfläche (Filter) in Markenrot, Auswahlmarkierung
    // (Symbolleiste, Chips) in dessen leichtem Ton.
    primaryContainer: NwbColors.brand,
    onPrimaryContainer: NwbColors.onBrand,
    secondaryContainer: NwbColors.brandTint,
    onSecondaryContainer: NwbColors.brand,
    surface: NwbColors.surface,
    onSurface: NwbColors.ink,
    onSurfaceVariant: NwbColors.muted,
    // Alle abgestuften Flächen sind auf der Website weiß; die Abstufung
    // übernimmt die Trennlinie, nicht eine Tönung.
    surfaceContainerLowest: NwbColors.surface,
    surfaceContainerLow: NwbColors.surface,
    surfaceContainer: NwbColors.surface,
    surfaceContainerHigh: NwbColors.surface,
    surfaceContainerHighest: NwbColors.surfaceMuted,
    outline: NwbColors.dividerStrong,
    outlineVariant: NwbColors.divider,
  );

  const Size minTouchSize = Size(kMinTouchTarget, kMinTouchTarget);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: NwbColors.surface,
    dividerColor: NwbColors.divider,
    // Material 3 liest für `Divider` nicht `dividerColor`, sondern
    // `outlineVariant` bzw. dieses Theme — ohne diese Zeile wären die
    // Trennlinien rosa.
    dividerTheme: const DividerThemeData(color: NwbColors.divider),
    fontFamily: NwbTypography.family,
    fontFamilyFallback: NwbTypography.fallback,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: minTouchSize),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: minTouchSize),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: minTouchSize),
    ),
    listTileTheme: const ListTileThemeData(minTileHeight: kMinTouchTarget),
    appBarTheme: AppBarTheme(
      backgroundColor: NwbColors.brand,
      foregroundColor: NwbColors.onBrand,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: style(
        NwbTypography.sectionHeading,
        weight: FontWeight.w700,
        color: NwbColors.onBrand,
        letterSpacing: 0.5,
      ),
    ),
    textTheme: TextTheme(
      // Artikeltitel.
      headlineMedium: style(
        NwbTypography.articleTitle,
        weight: FontWeight.w700,
        color: NwbColors.heading,
        height: 1.2,
      ),
      // Abschnittsüberschrift, auf der Website in Großbuchstaben mit roter
      // Linie darunter — Layoutmuster (d).
      titleMedium: style(
        NwbTypography.sectionHeading,
        weight: FontWeight.w700,
        color: NwbColors.heading,
        height: 1.2,
        letterSpacing: 0.5,
      ),
      // Teaser-Titel.
      titleSmall: style(
        NwbTypography.teaserTitle,
        weight: FontWeight.w700,
        color: NwbColors.heading,
        height: 1.4,
      ),
      // Fließtext.
      bodyMedium: style(NwbTypography.body, height: NwbTypography.bodyHeight),
      // Overline (ACF-Feld Podtytul), immer in Großbuchstaben. Schwarz, nicht
      // grau — er ist Teil der Schlagzeile, nicht der Meta-Angaben
      // (Design-Referenz Abschnitt 7).
      labelLarge: style(
        NwbTypography.overline,
        weight: FontWeight.w600,
        color: NwbColors.heading,
        letterSpacing: 0.5,
      ),
      // Datum und Brotkrume.
      bodySmall: style(NwbTypography.caption, color: NwbColors.muted),
    ),
  );
}

class NwbScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

/// Autor und Rubrik stehen in Markenrot, Datum und Brotkrume in Grau — der rote
/// Akzent trägt die Meta-Zeile (Design-Referenz Abschnitt 7, Punkt 2).
TextStyle nwbMetaAccent(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall!.copyWith(
    color: NwbColors.brand,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );
}

TextStyle nwbCaption(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall!
      .copyWith(fontStyle: FontStyle.italic);
}

TextStyle nwbThemeOfMonthKicker(BuildContext context) {
  return Theme.of(context).textTheme.labelLarge!
      .copyWith(color: NwbColors.brand, fontWeight: FontWeight.w600);
}

TextStyle nwbThemeOfMonthTitle(BuildContext context) {
  final TextStyle headline = Theme.of(context).textTheme.headlineMedium!;
  return headline.copyWith(fontSize: headline.fontSize! * 20 / 24);
}

TextStyle nwbAuthorBoxHeading(BuildContext context) {
  return Theme.of(context).textTheme.titleSmall!;
}

TextStyle nwbAuthorBoxText(BuildContext context) {
  final TextStyle body = Theme.of(context).textTheme.bodyMedium!;
  return body.copyWith(fontSize: body.fontSize! * 14 / 16, height: 1.6);
}
