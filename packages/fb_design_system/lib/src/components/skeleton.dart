import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:fb_design_system/src/tokens/density.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:material_ui/material_ui.dart';

/// A calm placeholder while local data loads (UX-051): a slow pulse, frozen
/// when the system asks for no animations.
class FbSkeleton extends StatefulWidget {
  /// A line of text. Full width unless [width] is given.
  const new line({this.width, this.height = 14, super.key})
    : radius = FbRadius.sm;

  /// A box of a given size (an image, an avatar).
  const new box({
    required this.width,
    required this.height,
    this.radius = FbRadius.md,
    super.key,
  });

  /// A card-sized block.
  const new card({this.height = 96, super.key})
    : width = null,
      radius = FbRadius.lg;

  /// A list row's placeholder (A57): a title and a subtitle line, as tall
  /// as a two-line `FbListRow` at the current text scale, so the real row
  /// replaces it without moving anything (UX-045).
  static Widget row({Key? key}) => _FbSkeletonRow(key: key);

  /// Width in dp, or null to fill the available width.
  final double? width;

  /// Height in dp.
  final double height;

  /// Corner radius in dp.
  final double radius;

  @override
  State<FbSkeleton> createState() => _FbSkeletonState();
}

class _FbSkeletonState extends State<FbSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.45,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: FbLocalizations.of(context).fbLoading,
    excludeSemantics: true,
    child: FadeTransition(
      opacity: _opacity,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.fbColors.skeleton,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    ),
  );
}

class _FbSkeletonRow extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    // A two-line row: 16 sp title, 14 sp subtitle, row padding.
    final height = (scaler.scale(16) * 1.5 + scaler.scale(14) * 1.43 + 16)
        .clamp(FbDensity.rowMinHeight + 16, double.infinity);
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: FbSpace.s4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: FbSpace.s2,
          children: [
            FbSkeleton.line(height: scaler.scale(14)),
            FbSkeleton.line(width: 120, height: scaler.scale(12)),
          ],
        ),
      ),
    );
  }
}
