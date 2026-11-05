import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// The reserved line under a field (UX-045, TD-113, A57 D12): always
/// [lines] lines tall at the current text scale, whether it shows the
/// [text] (a hint), the [errorText] or nothing, so the field and everything
/// below it never move when a message appears, changes or wraps. Text that
/// doesn't fit is cut with an ellipsis. An error shows in the error colour
/// in the same place and is announced (live region). A [counter] ("12/40")
/// sits at the end of the same line.
///
/// With [lines] 0 nothing is reserved and nothing shows (dense inline
/// fields, which mark an error by their outline only).
///
/// Part of the design system's fields; not exported.
class FbSupportingLine extends StatelessWidget {
  /// Creates the line.
  const new({
    this.text,
    this.errorText,
    this.counter,
    this.lines = 1,
    this.horizontalPadding = FbSpace.s4,
    super.key,
  }) : assert(lines >= 0, 'lines is not negative');

  /// The hint shown while there is no error.
  final String? text;

  /// The error, shown instead of [text].
  final String? errorText;

  /// The length counter, shown at the end.
  final String? counter;

  /// How many lines are reserved.
  final int lines;

  /// Start and end inset, matching the field's content padding.
  final double horizontalPadding;

  // Measures one line's height; never shown.
  static const String _probe = 'Ag';

  /// The text style of the line.
  static const TextStyle style = FbType.bodySmall;

  /// The height of [lines] lines of [style] at [scaler].
  static double heightFor(
    int lines,
    TextScaler scaler,
    TextDirection direction,
  ) {
    if (lines == 0) return 0;
    final painter = TextPainter(
      text: const TextSpan(text: _probe, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height * lines;
  }

  @override
  Widget build(BuildContext context) {
    if (lines == 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final height = heightFor(
      lines,
      MediaQuery.textScalerOf(context),
      Directionality.of(context),
    );
    final error = errorText;
    final message = error ?? text;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: horizontalPadding,
        end: horizontalPadding,
        top: FbSpace.s1,
      ),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: message == null
                  ? const SizedBox.shrink()
                  : Semantics(
                      liveRegion: error != null,
                      child: Text(
                        message,
                        maxLines: lines,
                        overflow: TextOverflow.ellipsis,
                        style: style.copyWith(
                          color: error != null
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
            if (counter case final counter?) ...[
              const SizedBox(width: FbSpace.s2),
              ExcludeSemantics(
                child: Text(
                  counter,
                  maxLines: 1,
                  style: FbType.numeric(style)
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
