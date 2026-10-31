import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/targets/application/targets_screens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Moves the targets screens to the next day one second after midnight
/// while [child] stays mounted (#197). The timer belongs to the widget, so
/// it ends with the screen, never outliving the widget tree.
class TargetsDayRollover extends ConsumerStatefulWidget {
  /// Wraps [child].
  const new({required this.child, super.key});

  /// The screen.
  final Widget child;

  @override
  ConsumerState<TargetsDayRollover> createState() => _TargetsDayRolloverState();
}

class _TargetsDayRolloverState extends ConsumerState<TargetsDayRollover> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    final clock = ref.read(clockProvider);
    final today = EntryTime.now(clock).localDate;
    _timer = Timer(
      nextDayStartUtc(
        today,
        clock,
      ).add(const Duration(seconds: 1)).difference(clock.nowUtc()),
      () {
        if (!mounted) return;
        ref.invalidate(targetsTodayProvider);
        _schedule();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
