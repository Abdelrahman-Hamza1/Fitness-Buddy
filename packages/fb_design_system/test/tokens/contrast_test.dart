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
  }
}
