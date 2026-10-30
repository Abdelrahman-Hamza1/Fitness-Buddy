import 'dart:async';

import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/config/client_config.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:fb_mobile/core/export/export_providers.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderSubscription;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_bootstrap.g.dart';

/// The work deferred until the first frame is on screen (UX-001, S06 plan
/// D9, D12, A1): independent error reporting, catalog pack install (A05 D9)
/// then the background pack update (A24),
/// public `/v1/config` refresh, API session startup (A20 D9) and, once the
/// catalog is attached and any account transition recovered, Buddy's
/// pending cards read back (A23 D12).
///
/// The app widget (`FitnessBuddyApp`) calls [afterFirstFrame] from a
/// post-frame callback; nothing awaits it, so the UI never waits for the
/// network.
final class AppBootstrap {
  /// Creates the bootstrap; the ref reads the services it starts.
  new(this._ref);

  final Ref _ref;
  bool _started = false;
  Future<void>? _installed;

  /// The catalog install, once (the update and the Buddy restore wait for
  /// it: a restored card verifies its facts against the attached pack).
  Future<void> _installCatalog() => _installed ??= _install();

  Future<void> _install() async {
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

  /// FD-023: check for a newer pack after the bundled one is in place. A
  /// failure (offline, no session yet, corrupt download) keeps the current
  /// pack, is not reported, and gets one retry when the API session becomes
  /// ready during this launch (A24 review #6, fix check #2).
  Future<void> _updateCatalog() async {
    await _installCatalog();
    await _contained(() async {
      if (!_ref.read(catalogPackUpdatesEnabledProvider)) return;
      final retry = OneRetry(
        () => _ref.read(catalogPackUpdaterProvider).checkForUpdate(),
      );
      // Watch readiness before the first attempt, so a session that becomes
      // ready while it is in flight still earns the one retry.
      late final ProviderSubscription<SessionState> sub;
      var closed = false;
      void stopWhenFinished() {
        if (closed || !retry.finished) return;
        closed = true;
        sub.close();
      }

      sub = _ref.listen(sessionStateProvider, (previous, next) {
        if (next.readiness == SessionReadiness.ready &&
            previous?.readiness != SessionReadiness.ready) {
          retry.ready();
        }
        stopWhenFinished();
      });
      await retry.run();
      stopWhenFinished();
    });
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
    unawaited(_updateCatalog());
    unawaited(_contained(() => _ref.read(exportCacheSweeperProvider).sweep()));
    unawaited(
      _contained(() async {
        await _ref.read(clientConfigProvider.notifier).refresh();
      }),
    );
    final recovered = _contained(
      () => _ref.read(accountTransitionsProvider).recover(),
    );
    unawaited(
      _contained(() async {
        // A33 §6: finish or roll back an interrupted account transition
        // before the API session may acquire anything; acquisition stays
        // suspended while a journal remains.
        await recovered;
        await _contained(() => _ref.read(sessionLifecycleProvider).start());
      }),
    );
    // A23 D12: pending Buddy cards come back after the first frame, against
    // the attached catalog and the recovered profile; local reads only.
    unawaited(
      _contained(() async {
        await Future.wait([_installCatalog(), recovered]);
        await _ref
            .read(buddyThreadControllerProvider.notifier)
            .ensureRestored(_ref.read(profileGenerationProvider));
      }),
    );
  }
}

/// The app's [AppBootstrap].
@Riverpod(keepAlive: true)
AppBootstrap appBootstrap(Ref ref) => AppBootstrap(ref);
