import 'package:fb_design_system/src/tokens/motion.dart';
import 'package:material_ui/material_ui.dart';

/// Shows or hides [child] by growing or shrinking it downward with a fade
/// (UX-046, TD-113, A57 D17): what sits above stays put, what sits below
/// slides with the edge. Uses [FbMotion.localOf], so it is instant when
/// the system asks for no animations. While hidden the child is not
/// hit-tested and not in the semantics tree.
///
/// [FbReveal.entering] animates in once when it first mounts (a row added
/// to a list); a plain [FbReveal] starts in its [visible] state unless
/// [appearOnMount] is set.
class FbReveal extends StatefulWidget {
  /// Creates the reveal.
  const new({
    required this.visible,
    required this.child,
    this.appearOnMount = false,
    super.key,
  });

  /// A child that grows in when it first mounts.
  const new entering({required this.child, super.key})
    : visible = true,
      appearOnMount = true;

  /// Whether the child is shown.
  final bool visible;

  /// The content.
  final Widget child;

  /// Whether a child that starts visible grows in when it mounts.
  final bool appearOnMount;

  @override
  State<FbReveal> createState() => _FbRevealState();
}

class _FbRevealState extends State<FbReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.visible && !widget.appearOnMount ? 1 : 0,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: FbMotion.standard,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = FbMotion.localOf(context);
    if (!_started) {
      _started = true;
      if (widget.visible && widget.appearOnMount) _run(forward: true);
    }
  }

  @override
  void didUpdateWidget(FbReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) _run(forward: widget.visible);
  }

  void _run({required bool forward}) {
    if (_controller.duration == Duration.zero) {
      _controller.value = forward ? 1 : 0;
    } else if (forward) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final hidden = _controller.value == 0 && !widget.visible;
      return FbInert(
        inert: !widget.visible,
        child: ClipRect(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: _curve.value,
            child: Opacity(
              opacity: _curve.value,
              child: hidden ? const SizedBox.shrink() : child,
            ),
          ),
        ),
      );
    },
    child: widget.child,
  );
}

/// Swaps the states of one region with a fade while the region resizes
/// smoothly (UX-046, A57 D17): a notice appearing, a proposal resolving,
/// an export finishing. Give each state's child its own key so the swap is
/// seen. Uses [FbMotion.structuralOf], so it is instant under reduced
/// motion. The region grows and shrinks from the top, so what is above it
/// never moves.
class FbSizeFade extends StatelessWidget {
  /// Creates the region.
  const new({required this.child, super.key});

  /// The current state's content (keyed per state).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = FbMotion.structuralOf(context);
    // AnimatedSize can't run with a zero duration: under reduced motion
    // the new state simply replaces the old one.
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: FbMotion.standard,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: FbMotion.standard,
        switchOutCurve: FbMotion.standard,
        layoutBuilder: (current, previous) => Stack(
          children: [
            // The leaving state fades without holding the region's size;
            // it keeps its own height (a taller one is clipped by the
            // region, never squeezed into it).
            // It takes no taps, focus or screen-reader attention.
            for (final child in previous)
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                child: FbInert(child: child),
              ),
            ?current,
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Makes [child] inert while [inert] is set: no taps, no focus (a focused
/// field inside loses it) and nothing for screen readers. For content that
/// is still painted while it leaves (A57): a state fading out, a row
/// shrinking away.
class FbInert extends StatelessWidget {
  /// Creates the wrapper; [inert] defaults to `true`.
  const new({required this.child, this.inert = true, super.key});

  /// Whether [child] is inert.
  final bool inert;

  /// The content.
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: inert,
    child: ExcludeFocus(
      excluding: inert,
      child: ExcludeSemantics(excluding: inert, child: child),
    ),
  );

  /// An [AnimatedSwitcher.layoutBuilder] like the default one, with every
  /// leaving child made inert, so only the incoming state can be used.
  static Widget switcherLayout(Widget? current, List<Widget> previous) => Stack(
    alignment: Alignment.center,
    children: [
      for (final child in previous) FbInert(child: child),
      ?current,
    ],
  );
}
