import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _palettes = <(String, Brightness)>[
  ('light', Brightness.light),
  ('dark', Brightness.dark),
];

void main() {
  test('UX-071 wcagContrast matches known values (black/white 21:1, '
      '#777 on white 4.48:1)', () {
    expect(
      wcagContrast(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.001),
    );
    expect(
      wcagContrast(const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)),
      closeTo(1, 0.001),
    );
    expect(
      wcagContrast(const Color(0xFF777777), const Color(0xFFFFFFFF)),
      closeTo(4.48, 0.01),
    );
  });

  for (final (name, brightness) in _palettes) {
    final pairs = fbContrastPairs(FbPalette.of(brightness));

    test('UX-071 every text/background token pair meets WCAG AA ($name)', () {
      final failing = [
        for (final pair in pairs)
          if (pair.kind == FbContrastKind.text && !pair.passes) '$pair',
      ];
      expect(failing, isEmpty, reason: failing.join('\n'));
      expect(pairs.where((p) => p.kind == FbContrastKind.text), isNotEmpty);
    });

    test('UX-071 non-text UI tokens (macro fills, over-target, outlines, '
        'focus) reach 3:1 against their background ($name)', () {
      final failing = [
        for (final pair in pairs)
          if (pair.kind == FbContrastKind.ui && !pair.passes) '$pair',
      ];
      expect(failing, isEmpty, reason: failing.join('\n'));
      expect(pairs.where((p) => p.kind == FbContrastKind.ui), isNotEmpty);
    });

    test('UX-071 the selected chip border contrasts at least 3:1 with the '
        'chip fill and the surface ($name)', () {
      final border = [
        for (final pair in pairs)
          if (pair.name.startsWith('selected chip border')) pair,
      ];
      expect(border, hasLength(2));
      for (final pair in border) {
        expect(pair.ratio, greaterThanOrEqualTo(3), reason: '$pair');
      }
    });

    test('UX-071 mint is never a text role: no contrast pair uses mint as '
        'text ($name)', () {
      final mint = FbPalette.of(brightness).mint;
      expect([
        for (final pair in pairs)
          if (pair.kind == FbContrastKind.text && pair.foreground == mint)
            pair.name,
      ], isEmpty);
      // The avatar's mint figure is checked as non-text UI on its disc.
      expect(
        pairs.where((p) => p.name == 'mint on avatarBackground').single.kind,
        FbContrastKind.ui,
      );
    });
  }

  // A42: the themes Material widgets actually read. A role mapped to the
  // wrong token in FbTheme would bypass the token pairs above.
  for (final (name, theme) in [
    ('light', FbTheme.light()),
    ('dark', FbTheme.dark()),
  ]) {
    test('UX-071 every ColorScheme text role meets WCAG AA on its '
        'background, and outlines reach 3:1 ($name theme)', () {
      final c = theme.colorScheme;
      final surfaces = {
        'surface': c.surface,
        'surfaceContainerLowest': c.surfaceContainerLowest,
        'surfaceContainerLow': c.surfaceContainerLow,
        'surfaceContainer': c.surfaceContainer,
        'surfaceContainerHigh': c.surfaceContainerHigh,
        'surfaceContainerHighest': c.surfaceContainerHighest,
        'surfaceBright': c.surfaceBright,
        'surfaceDim': c.surfaceDim,
      };
      final text = <(String, Color, Color)>[
        ('onPrimary/primary', c.onPrimary, c.primary),
        (
          'onPrimaryContainer/primaryContainer',
          c.onPrimaryContainer,
          c.primaryContainer,
        ),
        ('onSecondary/secondary', c.onSecondary, c.secondary),
        (
          'onSecondaryContainer/secondaryContainer',
          c.onSecondaryContainer,
          c.secondaryContainer,
        ),
        ('onTertiary/tertiary', c.onTertiary, c.tertiary),
        (
          'onTertiaryContainer/tertiaryContainer',
          c.onTertiaryContainer,
          c.tertiaryContainer,
        ),
        ('onPrimaryFixed/primaryFixed', c.onPrimaryFixed, c.primaryFixed),
        (
          'onPrimaryFixedVariant/primaryFixedDim',
          c.onPrimaryFixedVariant,
          c.primaryFixedDim,
        ),
        (
          'onSecondaryFixed/secondaryFixed',
          c.onSecondaryFixed,
          c.secondaryFixed,
        ),
        ('onTertiaryFixed/tertiaryFixed', c.onTertiaryFixed, c.tertiaryFixed),
        ('onError/error', c.onError, c.error),
        (
          'onErrorContainer/errorContainer',
          c.onErrorContainer,
          c.errorContainer,
        ),
        (
          'onInverseSurface/inverseSurface',
          c.onInverseSurface,
          c.inverseSurface,
        ),
        ('inversePrimary/inverseSurface', c.inversePrimary, c.inverseSurface),
        for (final MapEntry(:key, :value) in surfaces.entries) ...[
          ('onSurface/$key', c.onSurface, value),
          ('onSurfaceVariant/$key', c.onSurfaceVariant, value),
          ('primary/$key', c.primary, value),
          ('error/$key', c.error, value),
        ],
      ];
      final ui = <(String, Color, Color)>[
        for (final MapEntry(:key, :value) in surfaces.entries)
          ('outline/$key', c.outline, value),
      ];
      final failing = [
        for (final (pair, fg, bg) in text)
          if (wcagContrast(fg, bg) < 4.5)
            '$pair ${wcagContrast(fg, bg).toStringAsFixed(2)}:1',
        for (final (pair, fg, bg) in ui)
          if (wcagContrast(fg, bg) < 3)
            '$pair ${wcagContrast(fg, bg).toStringAsFixed(2)}:1',
      ];
      expect(failing, isEmpty, reason: failing.join('\n'));
    });
  }
}
