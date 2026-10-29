import 'dart:math' as math;

import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

// What a launcher shows (UX4): the inner 72 of the 108-unit adaptive-icon
// canvas, scaled 1.5 into a 108 dp cell, on the plate and under a mask; the
// mark is reversed like the app icon (or one colour, like a themed icon).
Widget _launcher(ShapeBorder mask, {bool monochrome = false}) {
  const mark = FbBrandMark(size: 162, colourway: FbMarkColourway.reversed);
  return SizedBox.square(
    dimension: 108,
    child: ClipPath(
      clipper: ShapeBorderClipper(shape: mask),
      child: ColoredBox(
        color: FbBrandColors.plate,
        child: OverflowBox(
          maxWidth: 162,
          maxHeight: 162,
          child: monochrome
              ? Theme(
                  data: FbTheme.dark().copyWith(
                    colorScheme: FbTheme.dark().colorScheme.copyWith(
                      onSurface: FbBrandColors.reversedA,
                    ),
                  ),
                  child: const FbBrandMark(
                    size: 162,
                    colourway: FbMarkColourway.monochrome,
                  ),
                )
              : mark,
        ),
      ),
    ),
  );
}

// The full 108 canvas at 1 dp per unit with the safe circle (r 33) dashed.
Widget _safeGuide() => const SizedBox.square(
  dimension: 108,
  child: ColoredBox(
    color: FbBrandColors.plate,
    child: CustomPaint(
      foregroundPainter: _DashedCircle(radius: 33),
      child: FbBrandMark(size: 108, colourway: FbMarkColourway.reversed),
    ),
  ),
);

class _DashedCircle extends CustomPainter {
  const new({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = FbBrandColors.mint;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    const dashes = 36;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        rect,
        i * 2 * math.pi / dashes,
        math.pi / dashes,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCircle oldDelegate) => oldDelegate.radius != radius;
}

Widget _cell(Brightness brightness, Widget child) => Theme(
  data: brightness == Brightness.light ? FbTheme.light() : FbTheme.dark(),
  child: Builder(
    builder: (context) => ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(FbSpace.s4),
        child: child,
      ),
    ),
  ),
);

Future<void> main() async {
  await goldenTest(
    'UX-040 A44-D10 brand mark colourways, launcher preview (inner 72 dp) '
    'and safe zone',
    fileName: 'brand_mark',
    builder: () => GoldenTestGroup(
      columns: 4,
      children: [
        for (final brightness in Brightness.values) ...[
          for (final colourway in [
            FbMarkColourway.onSurface,
            FbMarkColourway.monochrome,
          ])
            for (final size in [108.0, 48.0])
              GoldenTestScenario(
                name: '${brightness.name} ${colourway.name} $size',
                child: _cell(
                  brightness,
                  SizedBox.square(
                    dimension: 108,
                    child: Center(
                      child: FbBrandMark(size: size, colourway: colourway),
                    ),
                  ),
                ),
              ),
        ],
        GoldenTestScenario(name: 'safe zone r 33', child: _safeGuide()),
        GoldenTestScenario(
          name: 'launcher circle',
          child: _launcher(const CircleBorder()),
        ),
        GoldenTestScenario(
          name: 'launcher squircle',
          child: _launcher(
            const RoundedSuperellipseBorder(
              borderRadius: BorderRadius.all(Radius.circular(32)),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'launcher monochrome circle',
          child: _launcher(const CircleBorder(), monochrome: true),
        ),
      ],
    ),
  );

  await fbGoldenMatrix(
    'UX-040 FbBuddyAvatar golden matrix',
    fileName: 'buddy_avatar',
    states: {
      '28 and 24': (_) => fbGoldenPad(
        const Row(
          children: [
            FbBuddyAvatar(),
            SizedBox(width: FbSpace.s3),
            FbBuddyAvatar(size: 24),
            SizedBox(width: FbSpace.s3),
            FbBuddyAvatar(size: 56),
          ],
        ),
      ),
    },
  );

  await fbGoldenMatrix(
    'UX-040 UX-070 FbBrandLockup golden matrix',
    fileName: 'brand_lockup',
    states: {
      for (final size in FbLockupSize.values)
        size.name: (_) =>
            fbGoldenPad(FbBrandLockup(name: 'Fitness Buddy', size: size)),
    },
  );
}
