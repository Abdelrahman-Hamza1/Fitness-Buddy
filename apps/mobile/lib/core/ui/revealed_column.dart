import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter/widgets.dart';

/// A column of keyed [children] where a child added after the first build
/// grows in and a removed one shrinks away at its old place over
/// [FbMotion.local] (A57 A21/A22, UX-046). Nothing moves on the first build,
/// and everything is instant under reduced motion. A leaving child takes no
/// taps and is hidden from screen readers.
class RevealedColumn extends StatefulWidget {
  /// Creates the column; every child needs a key unique among them.
  const new({required this.children, super.key});

  /// The rows, each with its own key.
  final List<Widget> children;

  @override
  State<RevealedColumn> createState() => _RevealedColumnState();
}

typedef _Shown = ({Widget child, bool exiting});

class _RevealedColumnState extends State<RevealedColumn> {
  List<_Shown>? _shown;
  final Set<Key> _exiting = {};
  Timer? _drop;

  /// Forgets the children whose exit has finished.
  void _dropExited() {
    if (!mounted) return;
    setState(() {
      _shown = [
        for (final s in _shown ?? const <_Shown>[])
          if (!_exiting.contains(s.child.key)) s,
      ];
      _exiting.clear();
    });
  }

  @override
  void dispose() {
    _drop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = FbMotion.localOf(context);
    final children = widget.children;
    final now = {for (final c in children) c.key!};
    final before = _shown;
    var entering = const <Key>{};
    // A child that comes back while it leaves grows in again in place.
    _exiting.removeAll(now);
    if (duration == Duration.zero) {
      _drop?.cancel();
      _exiting.clear();
    } else if (before != null) {
      final seen = {for (final s in before) s.child.key!};
      entering = now.difference(seen);
      // Only children that were live last time can start leaving; one that
      // already left is never picked up again.
      final gone = {
        for (final s in before)
          if (!s.exiting && !now.contains(s.child.key)) s.child.key!,
      };
      if (gone.isNotEmpty) {
        _exiting.addAll(gone);
        _drop?.cancel();
        _drop = Timer(duration, _dropExited);
      }
    }
    final shown = <_Shown>[
      for (final c in children) (child: c, exiting: false),
    ];
    Key? previous;
    for (final s in before ?? const <_Shown>[]) {
      final key = s.child.key!;
      if (_exiting.contains(key)) {
        final at = previous == null
            ? 0
            : shown.indexWhere((c) => c.child.key == previous) + 1;
        shown.insert(at, (child: s.child, exiting: true));
      } else if (!now.contains(key)) {
        continue;
      }
      previous = key;
    }
    _shown = shown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in shown)
          FbReveal(
            key: s.child.key,
            visible: !s.exiting,
            appearOnMount: entering.contains(s.child.key),
            child: s.child,
          ),
      ],
    );
  }
}
