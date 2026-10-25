import 'dart:async';

import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// The grip at the end of a row of an [FbReorderableList]: pressing and
/// dragging it moves the row. It is a drag affordance, not a button: a screen
/// reader user moves a row with the "Move up" and "Move down" actions the
/// list puts on every row, so the grip itself is not announced.
///
/// It is at least 48 dp square and sits at the end of the row in every
/// direction. [index] is the row's position in the list. A false [enabled]
/// (a write is running) makes it inert and dims it.
class FbDragHandle extends StatelessWidget {
  /// Creates the grip of the row at [index].
  const new({required this.index, this.enabled = true, super.key});

  /// The row's position in its list.
  final int index;

  /// Whether a drag may start.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: ReorderableDragStartListener(
        index: index,
        enabled: enabled,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: FbSpace.s7,
            minHeight: FbSpace.s7,
          ),
          child: Icon(
            FbIcons.dragHandle,
            color: enabled ? scheme.onSurfaceVariant : scheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

/// A list whose rows the user reorders by dragging their [FbDragHandle], with
/// a haptic tick when a drag starts. Every row also offers the screen-reader
/// actions "Move up" and "Move down" (and to the start and end), in the
/// device's language, so reordering never needs a drag.
///
/// The list scrolls itself: [header] and [footer] scroll with it and are not
/// reorderable. It does not own the order: [onReorder] gets the row's old
/// position and the position it should end up at (already adjusted for the
/// removed row), and the caller decides what happens; until its [items]
/// change, the list shows the old order again. While [enabled] is false no
/// drag starts and [onReorder] is not called (for a write in flight).
class FbReorderableList<T> extends StatefulWidget {
  /// Creates the list of [items].
  const new({
    required this.items,
    required this.idOf,
    required this.itemBuilder,
    required this.onReorder,
    this.enabled = true,
    this.header,
    this.footer,
    super.key,
  });

  /// The rows' data, in the order shown.
  final List<T> items;

  /// A stable identity for an item (keeps a row's state while it moves).
  final String Function(T item) idOf;

  /// Builds a row. The handle it is given is the row's grip: place it at the
  /// row's end.
  final Widget Function(BuildContext context, T item, Widget handle)
  itemBuilder;

  /// Called with the old and the final position of a moved row.
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Whether rows can be moved.
  final bool enabled;

  /// Shown above the rows, scrolling with them.
  final Widget? header;

  /// Shown below the rows, scrolling with them.
  final Widget? footer;

  @override
  State<FbReorderableList<T>> createState() => _FbReorderableListState<T>();
}

class _FbReorderableListState<T> extends State<FbReorderableList<T>> {
  // Both list modes share a scroll position when a pending write toggles
  // reordering. The key belongs to this instance, not to other lists.
  final _scrollKey = PageStorageKey<UniqueKey>(UniqueKey());

  Widget _row(BuildContext context, int index) {
    final item = widget.items[index];
    return KeyedSubtree(
      key: ValueKey<String>(widget.idOf(item)),
      child: widget.itemBuilder(
        context,
        item,
        FbDragHandle(index: index, enabled: widget.enabled),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Flutter always installs move semantics on reorderable rows. A plain
    // list retains the rows' labels and other actions without advertising
    // moves that a pending write cannot accept.
    if (!widget.enabled) {
      final headerCount = widget.header == null ? 0 : 1;
      return ListView.builder(
        key: _scrollKey,
        itemCount:
            widget.items.length + headerCount + (widget.footer == null ? 0 : 1),
        itemBuilder: (context, index) {
          if (headerCount == 1 && index == 0) return widget.header!;
          final rowIndex = index - headerCount;
          if (rowIndex == widget.items.length) return widget.footer!;
          return _row(context, rowIndex);
        },
      );
    }
    return ReorderableListView.builder(
      key: _scrollKey,
      buildDefaultDragHandles: false,
      header: widget.header,
      footer: widget.footer,
      itemCount: widget.items.length,
      onReorderStart: (_) => unawaited(HapticFeedback.selectionClick()),
      onReorderItem: (oldIndex, newIndex) {
        if (widget.enabled && oldIndex != newIndex) {
          widget.onReorder(oldIndex, newIndex);
        }
      },
      itemBuilder: _row,
    );
  }
}
