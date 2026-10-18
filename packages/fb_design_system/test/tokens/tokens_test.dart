import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const List<FbPaletteVariant> _variants = FbPaletteVariant.values;

void main() {
  test('UX-042 each variant has four distinct macro colours, the same in '
      'every component theme', () {
    for (final variant in _variants) {
      for (final theme in [FbTheme.light(variant), FbTheme.dark(variant)]) {
        final c = theme.extension<FbColors>()!;
        final palette = FbPalette.of(variant, theme.brightness);
        expect({c.protein, c.carbs, c.fat, c.fiber}, hasLength(4));
        expect(
          [c.protein, c.carbs, c.fat, c.fiber],
          [palette.protein, palette.carbs, palette.fat, palette.fiber],
        );
      }
    }
  });

  test('UX-042 a macro colour never equals the brand of its variant', () {
    for (final variant in _variants) {
      for (final b in Brightness.values) {
        final p = FbPalette.of(variant, b);
        expect({p.protein, p.carbs, p.fat, p.fiber}, isNot(contains(p.brand)));
      }
    }
  });

  test('SF-021 overTarget is a neutral tone: low saturation, distinct from '
      'ColorScheme.error', () {
    for (final variant in _variants) {
      for (final b in Brightness.values) {
        final p = FbPalette.of(variant, b);
        final hsl = HSLColor.fromColor(p.overTarget);
        expect(hsl.saturation, lessThan(0.25), reason: '$variant $b');
        expect(p.overTarget, isNot(p.error));
        // Not in the red range even if it were more saturated.
        expect(hsl.hue > 15 && hsl.hue < 345, isTrue);
        final scheme =
            (b == Brightness.light
                    ? FbTheme.light(variant)
                    : FbTheme.dark(variant))
                .colorScheme;
        expect(p.overTarget, isNot(scheme.error));
      }
    }
  });

  test('SF-021 the error colour is a muted brick, not alarm red', () {
    for (final variant in _variants) {
      for (final b in Brightness.values) {
        final hsv = HSVColor.fromColor(FbPalette.of(variant, b).error);
        // Alarm red is (nearly) fully saturated (#FF0000: 1, #D32F2F: 0.78).
        expect(hsv.saturation, lessThan(0.75));
      }
    }
  });

  test('UX-040 FbTheme light and dark for both variants build, and use '
      'Inter with the Noto Sans Arabic fallback', () {
    for (final variant in _variants) {
      for (final theme in [FbTheme.light(variant), FbTheme.dark(variant)]) {
        for (final style in [
          theme.textTheme.bodyMedium!,
          theme.textTheme.displayLarge!,
          theme.textTheme.labelSmall!,
        ]) {
          expect(style.fontFamily, 'packages/fb_design_system/Inter');
          expect(style.fontFamilyFallback, [
            'packages/fb_design_system/NotoSansArabic',
          ]);
        }
        expect(theme.extension<FbColors>(), isNotNull);
        expect(theme.useMaterial3, isTrue);
      }
    }
    expect(FbTheme.light().brightness, Brightness.light);
    expect(FbTheme.dark().brightness, Brightness.dark);
  });

  test('UX-040 the theme follows the token scale', () {
    final t = FbTheme.light().textTheme;
    expect(t.displayLarge!.fontSize, 48);
    expect(t.displayLarge!.fontFeatures, contains(isNotNull));
    expect(t.bodyMedium!.fontSize, 16);
    expect(t.bodySmall!.fontSize, 14);
    expect(t.labelSmall!.fontSize, 12);
    expect(t.bodyMedium!.height! * 16, closeTo(24, 0.001));
  });

  test('UX-070 FbType.numeric adds tabular figures and keeps the rest', () {
    const plain = FbType.body;
    expect(plain.fontFeatures, isNull);
    final numeric = FbType.numeric(plain);
    expect(numeric.fontFeatures, hasLength(1));
    expect(numeric.fontSize, plain.fontSize);
  });

  for (final disabled in [false, true]) {
    testWidgets('FbMotion returns zero durations when animations are '
        'disabled (disableAnimations: $disabled)', (tester) async {
      late Duration result;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disabled),
          child: Builder(
            builder: (context) {
              result = FbMotion.of(context, FbMotion.slow);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, disabled ? Duration.zero : FbMotion.slow);
    });
  }

  test('the spacing scale is a 4-point grid', () {
    for (final v in [
      FbSpace.s1,
      FbSpace.s2,
      FbSpace.s3,
      FbSpace.s4,
      FbSpace.s5,
      FbSpace.s6,
      FbSpace.s7,
    ]) {
      expect(v % 4, 0);
    }
  });
}
