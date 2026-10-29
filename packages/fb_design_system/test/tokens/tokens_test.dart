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

  test('UX-040 display, headline and title use Nunito; body, label and '
      'caption use Inter; all fall back to Noto Sans Arabic', () {
    const nunito = 'packages/fb_design_system/Nunito';
    const inter = 'packages/fb_design_system/Inter';
    for (final theme in [FbTheme.light(), FbTheme.dark()]) {
      final t = theme.textTheme;
      final families = {
        t.displayLarge!: nunito,
        t.headlineMedium!: nunito,
        t.titleLarge!: nunito,
        t.bodyMedium!: inter,
        t.bodySmall!: inter,
        t.labelLarge!: inter,
        t.labelSmall!: inter,
      };
      for (final MapEntry(key: style, value: family) in families.entries) {
        expect(style.fontFamily, family);
        expect(style.fontFamilyFallback, [
          'packages/fb_design_system/NotoSansArabic',
        ]);
      }
      expect(theme.extension<FbColors>(), isNotNull);
      expect(theme.useMaterial3, isTrue);
    }
    for (final style in [FbType.button, FbType.chip, FbType.wordmark(32)]) {
      expect(style.fontFamilyFallback, [
        'packages/fb_design_system/NotoSansArabic',
      ]);
    }
    expect(FbType.wordmark(32).fontFamily, nunito);
    expect(FbType.wordmark(32).fontWeight, FontWeight.w900);
    expect(FbType.button.fontFamily, inter);
    expect(FbType.button.fontWeight, FontWeight.w600);
    expect(FbType.headline.fontWeight, FontWeight.w800);
    expect(FbType.title.fontWeight, FontWeight.w700);
    expect(FbTheme.light().brightness, Brightness.light);
    expect(FbTheme.dark().brightness, Brightness.dark);
  });

  test('UX-040 the palette is Embrace: values match the identity doc, '
      'except the listed AA deviations', () {
    // technical-planning/design/embrace/README.md; deviations (light):
    // outline #87938E -> #808C87, overTarget #8C918E -> #686E6B (WCAG AA).
    // success/info/inverse roles and the avatar roles are derived (A44 D1/D2).
    const expected = <Brightness, Map<String, int>>{
      Brightness.light: {
        'surface': 0xFFFAF9F4,
        'surfaceContainer': 0xFFFFFFFF,
        'surfaceContainerHigh': 0xFFEFF2EC,
        'onSurface': 0xFF13201D,
        'onSurfaceVariant': 0xFF53625D,
        'outline': 0xFF808C87,
        'outlineVariant': 0xFFE2E7E1,
        'brand': 0xFF0B6E5F,
        'onBrand': 0xFFFFFFFF,
        'brandContainer': 0xFFD3F0E3,
        'onBrandContainer': 0xFF0A3B33,
        'mint': 0xFFA8E3CB,
        'protein': 0xFF3D5FD9,
        'carbs': 0xFFB9760F,
        'fat': 0xFFC2457A,
        'fiber': 0xFF5E8A12,
        'overTarget': 0xFF686E6B,
        'error': 0xFFA2402F,
        'errorContainer': 0xFFFBEAE6,
        'success': 0xFF14773A,
        'info': 0xFF0369A1,
        'inverseSurface': 0xFF13201D,
        'inverseOnSurface': 0xFFFAF9F4,
        'inversePrimary': 0xFF6FD6B6,
        'avatarBackground': 0xFF0B6E5F,
        'avatarForeground': 0xFFFFFFFF,
      },
      Brightness.dark: {
        'surface': 0xFF0C1412,
        'surfaceContainer': 0xFF141E1B,
        'surfaceContainerHigh': 0xFF1D2925,
        'onSurface': 0xFFE8EFEC,
        'onSurfaceVariant': 0xFF9DAEA8,
        'outline': 0xFF6C7C77,
        'outlineVariant': 0xFF24322E,
        'brand': 0xFF6FD6B6,
        'onBrand': 0xFF04241D,
        'brandContainer': 0xFF123F36,
        'onBrandContainer': 0xFFBFEEDD,
        'mint': 0xFFA8E3CB,
        'protein': 0xFF8EA8FF,
        'carbs': 0xFFF2BE5C,
        'fat': 0xFFF29AC0,
        'fiber': 0xFFB5D86A,
        'overTarget': 0xFF8F9A96,
        'error': 0xFFF0B4A8,
        'errorContainer': 0xFF3A1E19,
        'success': 0xFF86EFAC,
        'info': 0xFF7DD3FC,
        'inverseSurface': 0xFFE8EFEC,
        'inverseOnSurface': 0xFF0C1412,
        'inversePrimary': 0xFF0B6E5F,
        'avatarBackground': 0xFF123F36,
        'avatarForeground': 0xFF6FD6B6,
      },
    };
    for (final MapEntry(key: brightness, value: roles) in expected.entries) {
      final p = FbPalette.of(brightness);
      final actual = <String, Color>{
        'surface': p.surface,
        'surfaceContainer': p.surfaceContainer,
        'surfaceContainerHigh': p.surfaceContainerHigh,
        'onSurface': p.onSurface,
        'onSurfaceVariant': p.onSurfaceVariant,
        'outline': p.outline,
        'outlineVariant': p.outlineVariant,
        'brand': p.brand,
        'onBrand': p.onBrand,
        'brandContainer': p.brandContainer,
        'onBrandContainer': p.onBrandContainer,
        'mint': p.mint,
        'protein': p.protein,
        'carbs': p.carbs,
        'fat': p.fat,
        'fiber': p.fiber,
        'overTarget': p.overTarget,
        'error': p.error,
        'errorContainer': p.errorContainer,
        'success': p.success,
        'info': p.info,
        'inverseSurface': p.inverseSurface,
        'inverseOnSurface': p.inverseOnSurface,
        'inversePrimary': p.inversePrimary,
        'avatarBackground': p.avatarBackground,
        'avatarForeground': p.avatarForeground,
      };
      for (final MapEntry(key: role, value: hex) in roles.entries) {
        expect(actual[role], Color(hex), reason: '$brightness $role');
      }
      expect(actual.keys.toSet(), roles.keys.toSet());
    }
    expect(FbTheme.light().colorScheme.primary, const Color(0xFF0B6E5F));
    expect(FbTheme.dark().colorScheme.primary, const Color(0xFF6FD6B6));
    final dark = FbTheme.dark().extension<FbColors>()!;
    expect(dark.mint, const Color(0xFFA8E3CB));
    expect(dark.avatarBackground, const Color(0xFF123F36));
    expect(dark.avatarForeground, const Color(0xFF6FD6B6));
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

  test('UX-041 FbDensity compact values: card padding 12, gap 8, rows 44, '
      'display 40', () {
    expect(FbDensity.cardPadding, 12);
    expect(FbDensity.cardGap, 8);
    expect(FbDensity.rowMinHeight, 44);
    expect(FbDensity.displaySize, 40);
    expect(FbDensity.macroColumns, isTrue);
    expect(FbDensity.macroBarHeight, 6);
    expect(FbDensity.blockGap, 8);
    expect(FbDensity.sectionGap, 12);
    expect(
      const FbCard(child: SizedBox()).padding,
      const EdgeInsetsDirectional.all(12),
    );
  });

  test('UX-041 UX-040 the theme follows the token scale', () {
    final light = FbTheme.light();
    final dark = FbTheme.dark();
    final t = light.textTheme;
    expect(t.displayLarge!.fontSize, 40);
    expect(t.displayLarge!.height! * 40, closeTo(48, 0.001));
    expect(t.displayLarge!.fontFeatures, contains(isNotNull));
    expect(t.headlineMedium!.fontSize, 24);
    expect(t.titleLarge!.fontSize, 18);
    expect(t.bodyMedium!.fontSize, 16);
    expect(t.bodySmall!.fontSize, 14);
    expect(t.labelSmall!.fontSize, 12);
    expect(t.bodyMedium!.height! * 16, closeTo(24, 0.001));

    // Radii: cards 20, chips/inputs 12, sheets 28, pill buttons.
    expect(FbRadius.lg, 20);
    expect(FbRadius.md, 12);
    expect(FbRadius.sheet, 28);
    final card = light.cardTheme.shape! as RoundedRectangleBorder;
    expect(card.borderRadius, FbRadius.lgAll);
    expect(card.side.color, light.colorScheme.outlineVariant);
    // Dark cards: no border, no shadow.
    final darkCard = dark.cardTheme.shape! as RoundedRectangleBorder;
    expect(darkCard.side, BorderSide.none);
    expect(dark.cardTheme.elevation, 0);
    final chip = light.chipTheme.shape! as RoundedRectangleBorder;
    expect(chip.borderRadius, FbRadius.mdAll);
    expect(
      light.chipTheme.backgroundColor,
      light.colorScheme.surfaceContainerHigh,
    );
    expect(light.chipTheme.showCheckmark, isTrue);
    final input = light.inputDecorationTheme.border! as OutlineInputBorder;
    expect(input.borderRadius, FbRadius.mdAll);
    final sheet = light.bottomSheetTheme.shape! as RoundedRectangleBorder;
    expect(sheet.borderRadius, FbRadius.sheetTop);
    for (final style in [
      light.filledButtonTheme.style!,
      light.outlinedButtonTheme.style!,
      light.textButtonTheme.style!,
    ]) {
      // A pill at its 48 dp height.
      expect(
        (style.shape!.resolve({})! as RoundedRectangleBorder).borderRadius,
        const BorderRadius.all(Radius.circular(24)),
      );
      expect(style.minimumSize!.resolve({})!.height, 48);
      expect(style.textStyle!.resolve({}), FbType.button);
    }
    expect(light.navigationBarTheme.height, 72);
    expect(light.listTileTheme.minTileHeight, 44);
    expect(
      (light.dialogTheme.shape! as RoundedRectangleBorder).borderRadius,
      FbRadius.lgAll,
    );
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
