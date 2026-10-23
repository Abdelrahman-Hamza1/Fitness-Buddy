import 'dart:async';

import 'package:fb_design_system/src/tokens/motion.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// How far a swipe must go, as a share of the row's width, before it counts
/// (DY-022).
const double fbSwipeThreshold = 0.4;

/// One thing a swipe does: a [label] (also the screen-reader action), an
/// [icon] drawn behind the row and the [onTriggered] callback.
@immutable
final class FbSwipeAction {
  /// Creates an action.
  const new({
    required this.label,
    required this.icon,
    required this.onTriggered,
  });

  /// The (already translated) name, shown next to the icon and announced as a
  /// custom action.
  final String label;

  /// Drawn behind the row while it is dragged.
  final IconData icon;

  /// Called when the swipe passes the threshold, or when a screen-reader user
  /// picks the action.
  final VoidCallback onTriggered;
}

/// Swipe actions for a list row (DY-022): drag toward the start edge to
/// [dismissAction] (the row leaves the list), drag toward the end edge to
/// [confirmAction] (the row snaps back and the callback decides what
/// happens, e.g. opens a picker). "Start" and "end" follow the text
/// direction, so everything mirrors in right-to-left layouts.
///
/// Passing the 40% threshold gives a haptic tick. Each action is also a
/// custom semantics action, so a screen-reader user needs no gesture. With
/// "remove animations" the row leaves at once.
///
/// The caller removes the row on dismissal. If it restores the row immediately
/// (e.g. a rejected command), a fresh swipe identity keeps it usable.
class FbSwipeActions extends StatefulWidget {
  /// Creates swipe actions around [child]. With neither action the child is
  /// shown as it is.
  const new({
    required this.child,
    this.dismissAction,
    this.confirmAction,
    super.key,
  });

  /// The row.
  final Widget child;

  /// Drag toward the start edge, past the threshold: the row is dismissed.
  /// Destructive tone.
  final FbSwipeAction? dismissAction;

  /// Drag toward the end edge, past the threshold: the row snaps back.
  final FbSwipeAction? confirmAction;

  @override
  State<FbSwipeActions> createState() => _FbSwipeActionsState();
}

class _FbSwipeActionsState extends State<FbSwipeActions> {
  Key _dismissKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final dismiss = widget.dismissAction;
    final confirm = widget.confirmAction;
    if (dismiss == null && confirm == null) return widget.child;
    final scheme = Theme.of(context).colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final dismissBackground = dismiss == null
        ? null
        : _SwipeBackground(
            action: dismiss,
            color: scheme.errorContainer,
            onColor: scheme.onErrorContainer,
            alignment: AlignmentDirectional.centerEnd,
          );
    return Semantics(
      customSemanticsActions: {
        if (dismiss != null)
          CustomSemanticsAction(label: dismiss.label): dismiss.onTriggered,
        if (confirm != null)
          CustomSemanticsAction(label: confirm.label): confirm.onTriggered,
      },
      child: Dismissible(
        key: _dismissKey,
        direction: switch ((dismiss, confirm)) {
          (_?, _?) => DismissDirection.horizontal,
          (_?, null) => DismissDirection.endToStart,
          _ => DismissDirection.startToEnd,
        },
        dismissThresholds: const {
          DismissDirection.endToStart: fbSwipeThreshold,
          DismissDirection.startToEnd: fbSwipeThreshold,
        },
        movementDuration: FbMotion.of(context),
        resizeDuration: reduced ? null : FbMotion.of(context, FbMotion.slow),
        onUpdate: (details) {
          if (details.reached && !details.previousReached) {
            unawaited(HapticFeedback.selectionClick());
          }
        },
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            confirm?.onTriggered();
            return false;
          }
          return true;
        },
        onDismissed: (_) {
          // A synchronous rejection can restore the row before removal paints.
          // Never reuse the completed resize animation in that case (DY-022).
          setState(() => _dismissKey = UniqueKey());
          dismiss?.onTriggered();
        },
        // `background` shows when dragging toward the end edge and also
        // stands in for a missing `secondaryBackground`.
        background: confirm == null
            ? dismissBackground
            : _SwipeBackground(
                action: confirm,
                color: scheme.primaryContainer,
                onColor: scheme.onPrimaryContainer,
                alignment: AlignmentDirectional.centerStart,
              ),
        secondaryBackground: confirm == null ? null : dismissBackground,
        // Opaque, so the backgrounds don't show through a transparent row.
        child: Material(color: scheme.surface, child: widget.child),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const new({
    required this.action,
    required this.color,
    required this.onColor,
    required this.alignment,
  });

  final FbSwipeAction action;
  final Color color;
  final Color onColor;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ColoredBox(
      color: color,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: FbSpace.s4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, color: onColor),
              const SizedBox(width: FbSpace.s2),
              Flexible(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FbType.label.copyWith(color: onColor),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
