import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tab_reselect.g.dart';

/// The app's tabs (UX-010), in tab order: the same order as the router's
/// tab list. Lives in `core/` so screens can react to a tab re-tap without
/// importing `app/` (A45 D13).
///
/// Workouts is a placeholder with nothing to scroll; the step that builds
/// its screen (A37) wraps it in [ScrollToTopOnTabReselect].
enum AppTab {
  /// Today.
  today,

  /// Progress.
  progress,

  /// Workouts.
  workouts,

  /// Me.
  me,
}

/// One re-tap of the current tab while it shows its root screen. [serial]
/// makes every re-tap a new value, so two re-taps in a row both fire.
@immutable
final class TabReselect {
  /// A re-tap of [tab].
  const new(this.tab, this.serial);

  /// The re-tapped tab.
  final AppTab tab;

  /// Counts the re-taps.
  final int serial;

  @override
  bool operator ==(Object other) =>
      other is TabReselect && other.tab == tab && other.serial == serial;

  @override
  int get hashCode => Object.hash(tab, serial);

  @override
  String toString() => 'TabReselect(${tab.name}, $serial)';
}

/// The latest tab re-tap (A45 D11, D13): the router fires it, and
/// [ScrollToTopOnTabReselect] scrolls the tab's main list to the top.
@Riverpod(keepAlive: true)
class TabReselectNotifier extends _$TabReselectNotifier {
  @override
  TabReselect? build() => null;

  /// Reports a re-tap of [tab].
  void fire(AppTab tab) => state = TabReselect(tab, (state?.serial ?? 0) + 1);
}

/// Scrolls a tab's main list to the top when its tab is tapped again while
/// it shows its root screen (UX-010, A45 D13).
///
/// The default form scrolls the [PrimaryScrollController] above it (a
/// `ListView` or `CustomScrollView` without a controller is primary on
/// Android). [ScrollToTopOnTabReselect.builder] owns a controller for a
/// scroll view that can't be primary (e.g. the pages of a pager). The
/// scroll takes [FbMotion.slow], or jumps with reduced motion; without a
/// scroll view attached it does nothing.
class ScrollToTopOnTabReselect extends ConsumerStatefulWidget {
  /// Scrolls the primary scroll controller of [child]'s scroll view.
  const new({required this.tab, required Widget this.child, super.key})
    : builder = null;

  /// Builds the scroll view with a controller this widget owns.
  const new builder({
    required this.tab,
    required Widget Function(BuildContext context, ScrollController controller)
    this.builder,
    super.key,
  }) : child = null;

  /// The tab whose re-tap scrolls.
  final AppTab tab;

  /// The subtree holding a primary scroll view.
  final Widget? child;

  /// Builds the scroll view with the owned controller.
  final Widget Function(BuildContext context, ScrollController controller)?
  builder;

  @override
  ConsumerState<ScrollToTopOnTabReselect> createState() =>
      _ScrollToTopOnTabReselectState();
}

class _ScrollToTopOnTabReselectState
    extends ConsumerState<ScrollToTopOnTabReselect> {
  ScrollController? _owned;

  ScrollController? get _controller =>
      _owned ?? PrimaryScrollController.maybeOf(context);

  @override
  void initState() {
    super.initState();
    if (widget.builder != null) _owned = ScrollController();
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  void _toTop() {
    final controller = _controller;
    if (controller == null || !controller.hasClients) return;
    final duration = FbMotion.of(context, FbMotion.slow);
    // A copy: animating a position can detach it from the controller.
    for (final position in [...controller.positions]) {
      if (duration == Duration.zero) {
        position.jumpTo(0);
      } else {
        unawaited(
          position.animateTo(0, duration: duration, curve: FbMotion.curve),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tabReselectProvider, (_, next) {
      if (next?.tab == widget.tab) _toTop();
    });
    return widget.builder?.call(context, _owned!) ?? widget.child!;
  }
}
