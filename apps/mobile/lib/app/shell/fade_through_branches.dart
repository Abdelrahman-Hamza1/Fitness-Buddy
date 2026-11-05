import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter/widgets.dart';

/// The tabs' branches (A57 A27, D19): every branch stays mounted, keeping
/// its stack and scroll positions, like go_router's indexed stack; hidden
/// branches are offstage with tickers off. The newly selected branch fades
/// in over [FbMotion.local] (instant under reduced motion), so a tab switch
/// is a fade-through instead of a cut.
class FadeThroughBranches extends StatefulWidget {
  /// Creates the container showing branch [currentIndex] of [children].
  const new({required this.currentIndex, required this.children, super.key});

  /// The selected branch.
  final int currentIndex;

  /// One navigator per branch, in tab order.
  final List<Widget> children;

  @override
  State<FadeThroughBranches> createState() => _FadeThroughBranchesState();
}

class _FadeThroughBranchesState extends State<FadeThroughBranches>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    value: 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _fade,
    curve: FbMotion.standard,
  );

  @override
  void didUpdateWidget(FadeThroughBranches oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    final duration = FbMotion.localOf(context);
    if (duration == Duration.zero) {
      _fade.value = 1;
    } else {
      _fade
        ..duration = duration
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: widget.currentIndex,
    children: [
      for (final (index, child) in widget.children.indexed)
        Offstage(
          offstage: index != widget.currentIndex,
          child: TickerMode(
            enabled: index == widget.currentIndex,
            child: FadeTransition(
              opacity: index == widget.currentIndex
                  ? _curve
                  : kAlwaysCompleteAnimation,
              child: child,
            ),
          ),
        ),
    ],
  );
}
