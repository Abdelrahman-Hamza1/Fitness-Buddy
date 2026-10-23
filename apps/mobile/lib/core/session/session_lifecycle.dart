import 'package:fb_mobile/core/session/session_retry_scheduler.dart';
import 'package:flutter/widgets.dart';

/// Flutter lifecycle boundary, installed only by post-frame bootstrap.
final class SessionLifecycle with WidgetsBindingObserver {
  /// Registers without starting storage/network work.
  new(this._scheduler, this._binding) {
    _binding.addObserver(this);
  }

  final SessionRetryScheduler _scheduler;
  final WidgetsBinding _binding;

  /// A missing initial lifecycle message means the first visible app frame.
  void start() => _scheduler.start(
    foreground:
        _binding.lifecycleState == null ||
        _binding.lifecycleState == AppLifecycleState.resumed,
  );

  /// A real same-origin response wakes the existing foreground scheduler.
  void transportSucceeded() => _scheduler.wake();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _scheduler.setForeground(foreground: state == AppLifecycleState.resumed);

  /// Removes the observer and cancels retry timers on provider disposal.
  void dispose() {
    _binding.removeObserver(this);
    _scheduler.dispose();
  }
}
