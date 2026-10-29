import 'dart:math' as math;

import 'package:fb_design_system/src/tokens/palette.dart';
import 'package:material_ui/material_ui.dart';

/// What a colour pair is used for, which sets the WCAG 2.2 minimum.
enum FbContrastKind {
  /// Text and icons that carry information: 4.5:1 (SC 1.4.3).
  text(4.5),

  /// Non-text UI that carries information (control borders, bar fills,
  /// focus): 3:1 (SC 1.4.11).
  ui(3);

  new(this.minimum);

  /// The lowest passing ratio.
  final double minimum;
}

/// WCAG 2.x contrast ratio of [a] and [b], from 1 (same) to 21.
double wcagContrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

double _luminance(Color c) =>
    0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);

double _linear(double channel) => channel <= 0.04045
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

/// One foreground drawn on one background, with the minimum it must reach.
final class FbContrastPair {
  /// Creates a pair.
  new(this.name, this.foreground, this.background, this.kind);

  /// A readable name for failure messages and the tokens page.
  final String name;

  /// The colour drawn.
  final Color foreground;

  /// The colour it is drawn on.
  final Color background;

  /// Text or non-text UI.
  final FbContrastKind kind;

  /// The contrast ratio.
  late final double ratio = wcagContrast(foreground, background);

  /// Whether [ratio] reaches the minimum of [kind].
  bool get passes => ratio >= kind.minimum;

  @override
  String toString() =>
      '$name: ${ratio.toStringAsFixed(2)}:1 (needs ${kind.minimum}:1)';
}

/// Every foreground/background pair the design system uses in [palette]
/// (UX-071). All text, large or not, is held to 4.5:1.
///
/// Not pairs, on purpose: `outlineVariant` and `mint` on the surfaces are
/// decoration and carry no information. The Embrace brand mark and the
/// "Fitness Buddy" lockup are a logo, which WCAG 2.2 SC 1.4.11 exempts: on
/// light, the mark's mint figure on cream is about 1.4:1 by design (TD-098,
/// A44 PA8). The Buddy avatar's figures are checked against its disc.
List<FbContrastPair> fbContrastPairs(FbPalette palette) {
  final p = palette;
  final surfaces = <String, Color>{
    'surface': p.surface,
    'surfaceContainer': p.surfaceContainer,
    'surfaceContainerHigh': p.surfaceContainerHigh,
  };
  final texts = <String, Color>{
    'onSurface': p.onSurface,
    'onSurfaceVariant': p.onSurfaceVariant,
    'overTarget': p.overTarget,
    'brand': p.brand,
    'info': p.info,
    'success': p.success,
    'error': p.error,
  };
  // Fills and outlines judged against the surfaces they sit on and, for bars,
  // against their own track.
  final fills = <String, Color>{
    'protein': p.protein,
    'carbs': p.carbs,
    'fat': p.fat,
    'fiber': p.fiber,
    'overTarget': p.overTarget,
  };
  final controls = <String, Color>{
    'outline': p.outline,
    'badge outline': p.onSurfaceVariant,
    'focus ring': p.brand,
  };
  return [
    for (final MapEntry(key: bg, value: background) in surfaces.entries)
      for (final MapEntry(key: fg, value: foreground) in texts.entries)
        FbContrastPair(
          '$fg text on $bg',
          foreground,
          background,
          FbContrastKind.text,
        ),
    FbContrastPair('onBrand on brand', p.onBrand, p.brand, FbContrastKind.text),
    FbContrastPair(
      'onBrandContainer on brandContainer',
      p.onBrandContainer,
      p.brandContainer,
      FbContrastKind.text,
    ),
    FbContrastPair(
      'onSurface on brandContainer',
      p.onSurface,
      p.brandContainer,
      FbContrastKind.text,
    ),
    FbContrastPair(
      'onSurface on errorContainer',
      p.onSurface,
      p.errorContainer,
      FbContrastKind.text,
    ),
    FbContrastPair(
      'error on errorContainer',
      p.error,
      p.errorContainer,
      FbContrastKind.text,
    ),
    FbContrastPair(
      'brand on errorContainer',
      p.brand,
      p.errorContainer,
      FbContrastKind.text,
    ),
    FbContrastPair(
      'brand on brandContainer',
      p.brand,
      p.brandContainer,
      FbContrastKind.text,
    ),
    FbContrastPair(
      'wordmark (onBrandContainer) on surface',
      p.onBrandContainer,
      p.surface,
      FbContrastKind.text,
    ),
    FbContrastPair(
      'avatarForeground on avatarBackground',
      p.avatarForeground,
      p.avatarBackground,
      FbContrastKind.ui,
    ),
    FbContrastPair(
      'mint on avatarBackground',
      p.mint,
      p.avatarBackground,
      FbContrastKind.ui,
    ),
    FbContrastPair(
      'snackbar text',
      p.inverseOnSurface,
      p.inverseSurface,
      FbContrastKind.text,
    ),
    FbContrastPair(
      'snackbar action',
      p.inversePrimary,
      p.inverseSurface,
      FbContrastKind.text,
    ),
    for (final MapEntry(key: bg, value: background) in surfaces.entries)
      for (final MapEntry(key: fg, value: foreground) in {
        ...fills,
        ...controls,
      }.entries)
        FbContrastPair('$fg on $bg', foreground, background, FbContrastKind.ui),
  ];
}
