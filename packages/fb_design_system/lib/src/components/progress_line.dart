import 'package:fb_design_system/src/tokens/motion.dart';
import 'package:material_ui/material_ui.dart';

/// A thin progress line in a slot that is always reserved (A57 D23,
/// UX-045): [height] tall whether [active] or not, so nothing below it moves
/// when work starts or ends. The line fades in and out over
/// [FbMotion.local] (instant under reduced motion), so work that ends within
/// a frame or two never flashes.
class FbProgressLine extends StatelessWidget {
  /// Creates the slot.
  const new({required this.active, this.semanticsLabel, super.key});

  /// Slot height in dp.
  static const double height = 2;

  /// Whether work is running.
  final bool active;

  /// Read by screen readers while [active]; never announced as a live
  /// region (no announcement per keystroke).
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration: FbMotion.localOf(context),
      curve: FbMotion.standard,
      child: active
          ? LinearProgressIndicator(
              minHeight: height,
              semanticsLabel: semanticsLabel,
            )
          : const SizedBox.expand(),
    ),
  );
}
