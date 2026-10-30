import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('UX-042 four distinct macro colours, the same in every component '
      'theme', () {
    for (final theme in [FbTheme.light(), FbTheme.dark()]) {
      final c = theme.extension<FbColors>()!;
      final palette = FbPalette.of(theme.brightness);
      expect({c.protein, c.carbs, c.fat, c.fiber}, hasLength(4));
      expect(
        [c.protein, c.carbs, c.fat, c.fiber],
        [palette.protein, palette.carbs, palette.fat, palette.fiber],
      );
    }
  });

  test('UX-042 a macro colour never equals the brand', () {
    for (final b in Brightness.values) {
      final p = FbPalette.of(b);
      expect({p.protein, p.carbs, p.fat, p.fiber}, isNot(contains(p.brand)));
    }
  });

  test('SF-021 overTarget is a neutral tone: low saturation, distinct from '
      'ColorScheme.error', () {
    for (final b in Brightness.values) {
      final p = FbPalette.of(b);
      final hsl = HSLColor.fromColor(p.overTarget);
      expect(hsl.saturation, lessThan(0.25), reason: '$b');
      expect(p.overTarget, isNot(p.error));
      // Not in the red range even if it were more saturated.
      expect(hsl.hue > 15 && hsl.hue < 345, isTrue);
      final scheme = (b == Brightness.light ? FbTheme.light() : FbTheme.dark())
          .colorScheme;
      expect(p.overTarget, isNot(scheme.error));
    }
  });

  test('SF-021 the error colour is a muted brick, not alarm red', () {
    for (final b in Brightness.values) {
      final hsv = HSVColor.fromColor(FbPalette.of(b).error);
      // Alarm red is (nearly) fully saturated (#FF0000: 1, #D32F2F: 0.78).
      expect(hsv.saturation, lessThan(0.75));
    }
  });

  test('UX-042 protein is blue and every macro colour differs from the brand '
      'and from each other', () {
    for (final b in Brightness.values) {
      final p = FbPalette.of(b);
      final hue = HSLColor.fromColor(p.protein).hue;
      expect(hue, inInclusiveRange(200, 250), reason: '$b protein hue $hue');
      final macros = [p.protein, p.carbs, p.fat, p.fiber];
      expect(macros.toSet(), hasLength(4), reason: '$b');
      expect(macros, isNot(contains(p.brand)), reason: '$b');
      expect(macros, isNot(contains(p.mint)), reason: '$b');
    }
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
}
