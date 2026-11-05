import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter/widgets.dart';

/// Moves between the steps of a flow (setup, sign-in) on a shared axis
/// (A57 A26, UX-046): the old step goes at once and the new one fades in
/// from 8 % toward the end over [FbMotion.structural], so two steps (and
/// their fields) are never on screen together. Give each step's [child] its
/// own key (a new key also starts its scroll at the top). Instant under
/// reduced motion.
class StepTransition extends StatefulWidget {
  /// Creates the transition around the current step's [child].
  const new({required this.child, super.key});

  /// The current step, keyed per step.
  final Widget child;

  @override
  State<StepTransition> createState() => _StepTransitionState();
}

class _StepTransitionState extends State<StepTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    value: 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _in,
    curve: FbMotion.emphasizedDecelerate,
  );

  @override
  void didUpdateWidget(StepTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child.key == widget.child.key) return;
    final duration = FbMotion.structuralOf(context);
    if (duration == Duration.zero) {
      _in.value = 1;
    } else {
      _in
        ..duration = duration
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(rtl ? -0.08 : 0.08, 0),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
