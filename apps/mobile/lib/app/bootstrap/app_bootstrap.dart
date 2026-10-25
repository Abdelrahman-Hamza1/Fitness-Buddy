import 'dart:async';

import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/config/client_config.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:fb_mobile/core/export/export_providers.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_bootstrap.g.dart';

/// The work deferred until the first frame is on screen (UX-001, S06 plan
/// D9, D12, A1): independent error reporting, catalog pack install (A05 D9),
/// public `/v1/config` refresh and API session startup (A20 D9).
///
/// The app widget (`FitnessBuddyApp`) calls [afterFirstFrame] from a
/// post-frame callback; nothing awaits it, so the UI never waits for the
/// network.
final class AppBootstrap {
  /// Creates the bootstrap; the ref reads the services it starts.
  new(this._ref);

  final Ref _ref;
  bool _started = false;

  Future<void> _installCatalog() async {
    try {
      await installAndAttachCatalog(
        _ref.read(catalogPackInstallerProvider),
        _ref.read(appDatabaseProvider),
        onError: (error, _) =>
            _ref.read(errorReportingProvider).reportKind(error),
      );
    } on Object {
      // No catalog is not fatal: the app runs on personal foods and history.
    }
  }

  Future<void> _contained(FutureOr<void> Function() work) async {
    try {
      if (_ref.mounted) await work();
    } on Object {
      // Optional work must never escape to Flutter/global reporting sinks.
    }
  }

  /// Launches independent optional tasks once, after the first visible frame.
  /// A hung SDK, storage or network operation cannot hold up another task.
  Future<void> afterFirstFrame() async {
    if (_started || !_ref.mounted) return;
    _started = true;
    unawaited(
      _contained(() async {
        await _ref.read(errorReportingProvider).start();
      }),
    );
    unawaited(_installCatalog());
    unawaited(_contained(() => _ref.read(exportCacheSweeperProvider).sweep()));
    unawaited(
      _contained(() async {
        await _ref.read(clientConfigProvider.notifier).refresh();
      }),
    );
    unawaited(_contained(() => _ref.read(sessionLifecycleProvider).start()));
  }
}

/// The app's [AppBootstrap].
@Riverpod(keepAlive: true)
AppBootstrap appBootstrap(Ref ref) => AppBootstrap(ref);
