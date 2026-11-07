import 'dart:async';
import 'dart:ui' show Locale;

import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/home_widget/home_widget_store.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/buddy/buddy.dart' show closeBuddySheetIfIdle;
import 'package:fb_mobile/features/home_widgets/application/home_widget_actions.dart';
import 'package:fb_mobile/features/home_widgets/application/home_widget_inputs.dart';
import 'package:fb_mobile/features/home_widgets/application/widget_snapshot.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderSubscription;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget_coordinator.g.dart';

/// Whether this build feeds the home-screen widgets. On in the app; widget
/// tests of other features keep it off.
@Riverpod(keepAlive: true)
bool homeWidgetsEnabled(Ref ref) => true;

/// Opens a router location for a widget tap. The app wires it to the
/// router (`lib/app/app_scope.dart`); features can't import the router.
@Riverpod(keepAlive: true)
Future<void> Function(String location) homeWidgetLinkOpener(Ref ref) =>
    (_) => throw UnimplementedError(
      'homeWidgetLinkOpenerProvider must be overridden (app_scope.dart).',
    );

/// Keeps the home-screen widgets equal to Today (A71 D5, UX-084, UX-085):
/// started by the bootstrap after account recovery, it writes a snapshot
/// on every change of its inputs and on resume, one write in flight at a
/// time (the latest wins). A profile switch clears the widgets at once, then
/// the new profile's snapshot follows; inputs of an older generation are
/// never written. Widget taps open their place (UX-083). Local only;
/// nothing is logged.
final class HomeWidgetCoordinator {
  /// Over [_ref].
  new(this._ref);

  final Ref _ref;
  bool _started = false;
  bool _disposed = false;
  bool _writing = false;
  int _generation = 0;

  /// A clear is due (a profile switch), before [_next].
  bool _clear = false;

  /// The next snapshot to write and the store epoch its inputs were read
  /// in; the latest wins.
  WidgetSnapshot? _next;
  int _nextEpoch = 0;
  AppLifecycleListener? _lifecycle;
  ProviderSubscription<AsyncValue<HomeWidgetInputs>>? _inputsSub;
  ProviderSubscription<int>? _profileSub;
  ProviderSubscription<bool>? _busySub;
  Completer<void>? _idle;

  /// English (R1, D-080): the snapshot is built outside the widget tree.
  static final AppLocalizations _l10n = lookupAppLocalizations(
    const Locale('en'),
  );

  HomeWidgetStore get _store => _ref.read(homeWidgetStoreProvider);

  /// Starts once: follows the inputs and the profile, then opens a launch
  /// tap's place. Never throws.
  Future<void> start() async {
    if (_started || _disposed) return;
    if (!_ref.read(homeWidgetsEnabledProvider)) return;
    _started = true;
    _generation = _ref.read(profileGenerationProvider);
    // Subscribed before any await, so a profile switch meanwhile is seen
    // (A71 review: a missed switch would drop every later snapshot).
    _lifecycle = AppLifecycleListener(
      onResume: () {
        // A new day or time zone while away.
        _ref
          ..invalidate(todayProvider)
          ..invalidate(homeWidgetInputsProvider);
      },
    );
    _profileSub = _ref.listen(profileGenerationProvider, (_, generation) {
      _generation = generation;
      _clear = true;
      _next = null;
      _kick();
    });
    // The account transitions hold the widgets cleared while they run;
    // once done, the current state is read and written again.
    _busySub = _ref.listen(accountBusyProvider, (_, busy) {
      // Anything computed before or during the transition is stale (the
      // store's epoch moved too); only freshly read inputs are written.
      _next = null;
      if (!busy) {
        _ref
          ..invalidate(accountStatusProvider)
          ..invalidate(homeWidgetInputsProvider);
      }
    });
    _inputsSub = _ref.listen(homeWidgetInputsProvider, (_, next) {
      // Only freshly resolved inputs: never a previous value kept while
      // refreshing or next to an error (A71 fix-check), and never one read
      // for another profile or before an account transition.
      if (next case AsyncData(isLoading: false, value: final inputs)
          when inputs.generation == _generation &&
              inputs.epoch == _store.epoch) {
        _nextEpoch = inputs.epoch;
        _next = WidgetSnapshot.of(
          l10n: _l10n,
          profileTag: inputs.profileTag,
          signedOut: inputs.signedOut,
          hidden: inputs.hidden,
          days: inputs.days,
        );
        _kick();
      }
    }, fireImmediately: true);
    _store.listen(() => unawaited(_openPending()));
    await _openPending();
  }

  /// Opens the place of the widget tap waiting on the platform, if it is
  /// one of the allow-list's; anything else leaves the app where it is.
  Future<void> _openPending() async {
    try {
      final action = HomeWidgetAction.of(await _store.takeLaunchAction());
      if (action == null || _disposed) return;
      // The numbers show Today: an open Buddy sheet goes when nothing in it
      // would be lost (otherwise it stays, A71 fix-check). Ask and Speak
      // reuse an open sheet (BuddyEntry); Weigh opens over it.
      if (action == HomeWidgetAction.today) closeBuddySheetIfIdle();
      await _ref.read(homeWidgetLinkOpenerProvider)(homeWidgetLocation(action));
      // The numbers are today's: back on today's page, also when Today
      // already shows (the router keeps an open location as it is).
      if (action == HomeWidgetAction.today && !_disposed) {
        _ref.read(todayControllerProvider.notifier).followToday();
      }
    } on Object {
      // A tap that can't be opened leaves the app where it is.
    }
  }

  /// Completes when no write is in flight or queued (tests).
  Future<void> get idle =>
      _writing ? (_idle ??= Completer()).future : Future.value();

  void _kick() {
    if (_disposed || _writing) return;
    unawaited(_run());
  }

  Future<void> _run() async {
    _writing = true;
    try {
      while (!_disposed && (_clear || _next != null)) {
        try {
          if (_clear) {
            // A switch clears before anything else is written.
            _clear = false;
            await _store.clear();
            continue;
          }
          final snapshot = _next!;
          _next = null;
          await _store.save(snapshot.toData(), epoch: _nextEpoch);
        } on Object {
          // The widgets keep the last snapshot; the next change retries.
        }
      }
    } finally {
      _writing = false;
      _idle?.complete();
      _idle = null;
    }
  }

  /// Stops following the inputs.
  void dispose() {
    _disposed = true;
    _lifecycle?.dispose();
    _inputsSub?.close();
    _profileSub?.close();
    _busySub?.close();
  }
}

/// The app's [HomeWidgetCoordinator]: one for the app's life.
@Riverpod(keepAlive: true)
HomeWidgetCoordinator homeWidgetCoordinator(Ref ref) {
  final coordinator = HomeWidgetCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  return coordinator;
}
