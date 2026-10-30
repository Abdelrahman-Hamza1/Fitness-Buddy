import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unsaved_edits.g.dart';

typedef _Entry = ({
  Object token,
  NavigatorState navigator,
  Future<bool> Function() confirm,
});

/// Which navigators hold a screen with unsaved edits (A45 D12, PA2), so a
/// tab tap never throws such a screen away: switching to its tab keeps its
/// stack, and re-tapping its tab asks first ([confirm]).
///
/// Screens register through [UnsavedEditsGuard], never directly.
final class UnsavedEdits {
  final List<_Entry> _entries = [];

  /// Whether a screen in [navigator] holds unsaved edits.
  bool holds(NavigatorState? navigator) =>
      navigator != null && _entries.any((e) => e.navigator == navigator);

  /// Asks the screen with unsaved edits in [navigator] (the latest one) to
  /// confirm discarding them: true when the user discards (or nothing is
  /// held), false when they keep editing. It doesn't close the screen.
  Future<bool> confirm(NavigatorState navigator) async {
    final entry = _entries.lastWhereOrNull((e) => e.navigator == navigator);
    return entry == null || await entry.confirm();
  }

  void _register(
    Object token,
    NavigatorState navigator,
    Future<bool> Function() confirm,
  ) {
    _unregister(token);
    _entries.add((token: token, navigator: navigator, confirm: confirm));
  }

  void _unregister(Object token) =>
      _entries.removeWhere((e) => identical(e.token, token));
}

extension<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (final element in reversed) {
      if (test(element)) return element;
    }
    return null;
  }
}

/// The app's one [UnsavedEdits] registry.
@Riverpod(keepAlive: true)
UnsavedEdits unsavedEdits(Ref ref) => UnsavedEdits();

/// Keeps a screen's unsaved edits from being lost (A45 D12): while [dirty],
/// the system back asks [confirmDiscard] and closes the screen only on a
/// confirmed discard, and a tab tap keeps the screen or asks first (see
/// [UnsavedEdits]). [confirmDiscard] only asks; it never closes anything.
class UnsavedEditsGuard extends ConsumerStatefulWidget {
  /// Guards [child] while [dirty].
  const new({
    required this.dirty,
    required this.confirmDiscard,
    required this.child,
    super.key,
  });

  /// Whether the screen holds unsaved edits.
  final bool dirty;

  /// Asks the user to discard the edits: true to discard.
  final Future<bool> Function() confirmDiscard;

  /// The screen.
  final Widget child;

  @override
  ConsumerState<UnsavedEditsGuard> createState() => _UnsavedEditsGuardState();
}

class _UnsavedEditsGuardState extends ConsumerState<UnsavedEditsGuard> {
  final Object _token = Object();
  late final UnsavedEdits _registry = ref.read(unsavedEditsProvider);
  NavigatorState? _navigator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.maybeOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(UnsavedEditsGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dirty != widget.dirty) _sync();
  }

  @override
  void dispose() {
    _registry._unregister(_token);
    super.dispose();
  }

  /// Registered exactly while dirty, under this screen's navigator.
  void _sync() {
    final navigator = _navigator;
    if (widget.dirty && navigator != null) {
      _registry._register(_token, navigator, () => widget.confirmDiscard());
    } else {
      _registry._unregister(_token);
    }
  }

  Future<void> _back() async {
    final discard = await widget.confirmDiscard();
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.dirty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_back());
    },
    child: widget.child,
  );
}
