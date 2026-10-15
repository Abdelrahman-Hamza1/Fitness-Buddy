import 'package:fb_mobile/core/config/client_config.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_bootstrap.g.dart';

/// The work deferred until the first frame is on screen (UX-001, S06 plan
/// D9, D12, A1): error reporting, then the `/v1/config` refresh.
///
/// The app widget (`FitnessBuddyApp`) calls [afterFirstFrame] from a
/// post-frame callback; nothing awaits it, so the UI never waits for the
/// network.
final class AppBootstrap {
  /// Creates the bootstrap; the ref reads the services it starts.
  new(this._ref);

  final Ref _ref;
  bool _started = false;

  /// Starts error reporting (when the flavor has a DSN), then refreshes the
  /// client config (cache first, then the API). Runs once; failures are
  /// absorbed (the app works without both).
  Future<void> afterFirstFrame() async {
    if (_started) return;
    _started = true;
    try {
      await _ref.read(errorReportingProvider).start();
    } on Object {
      // Reporting is optional; the app must start regardless.
    }
    if (!_ref.mounted) return;
    try {
      await _ref.read(clientConfigProvider.notifier).refresh();
    } on Object {
      // The app runs on the cached or default config without it.
    }
  }
}

/// The app's [AppBootstrap].
@Riverpod(keepAlive: true)
AppBootstrap appBootstrap(Ref ref) => AppBootstrap(ref);
