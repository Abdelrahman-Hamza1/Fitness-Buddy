import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A number in a column of fixed width (UX-045, TD-113, A57 D14): as wide
/// as [sample] in tabular figures at the current text scale, whatever
/// [text] holds, so "85 kcal" and "1,240 kcal" leave the same room for what
/// sits beside them. The text is aligned by [align] (end by default) and
/// cut with an ellipsis if it is ever wider than the sample.
class FbNumberSlot extends StatelessWidget {
  /// Creates the slot.
  const new({
    required this.text,
    required this.style,
    this.sample = '8,888',
    this.align = TextAlign.end,
    this.semanticsLabel,
    super.key,
  });

  /// The number as shown.
  final String text;

  /// Its style; tabular figures are applied.
  final TextStyle style;

  /// The widest text the slot is sized for.
  final String sample;

  /// How [text] sits inside the slot.
  final TextAlign align;

  /// What a screen reader reads instead of [text].
  final String? semanticsLabel;

  /// The slot's width for [sample] in [style] at [scaler].
  static double widthFor(
    String sample,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: sample, style: FbType.numeric(style)),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    // A hair more, so a text exactly as wide as the sample isn't cut by
    // rounding.
    return width.ceilToDouble() + 1;
  }

  @override
  Widget build(BuildContext context) {
    final numeric = FbType.numeric(style);
    final width = widthFor(
      sample,
      numeric,
      MediaQuery.textScalerOf(context),
      Directionality.of(context),
    );
    return SizedBox(
      width: width,
      child: Text(
        text,
        semanticsLabel: semanticsLabel,
        textAlign: align,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: numeric,
      ),
    );
  }
}
