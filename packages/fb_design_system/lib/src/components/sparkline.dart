import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A quiet, unlabelled series; the surrounding text supplies its semantics.
class FbSparkline extends StatelessWidget {
  /// Creates the component with localized labels and session state.
  const new({required this.values, this.height = 36, super.key});

  /// Canonical values in chronological order.
  final List<double> values;

  /// Content height before text scaling.
  final double height;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _Sparkline(values, Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}

class _Sparkline extends CustomPainter {
  new(this.values, this.color);

  /// Canonical values in chronological order.
  final List<double> values;

  /// The displayed summary value.
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    Offset point(int i) => Offset(
      3 + i * (size.width - 6) / (values.length - 1),
      high == low
          ? size.height / 2
          : 3 + (high - values[i]) / (high - low) * (size.height - 6),
    );
    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p = point(i);
      path.lineTo(p.dx, p.dy);
    }
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      )
      ..drawCircle(point(values.length - 1), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Sparkline oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
