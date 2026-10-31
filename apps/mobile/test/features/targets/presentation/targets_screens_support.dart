import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Scrollable;

import '../../../helpers/pump_app.dart';
import '../../settings/presentation/settings_support.dart' show useTallScreen;
import '../application/targets_app_harness.dart' show setupInput;

/// The whole app on a fresh offline phone at a manual clock (Saturday
/// 2026-10-17 12:00 UTC), set up through `TargetsActions.completeSetup`
/// (male, 1990, 180 cm, 80 kg, moderate, the given goal or lose 0.5 kg a
/// week).
final class TargetsScreenRig {
  new _(this.tester, this.container, this.clock, this._writes);

  /// Starts the app, sets it up and shows [route] (when given).
  static Future<TargetsScreenRig> open(
    WidgetTester tester, {
    GoalInput? goal,
    AppRoute? route,
    bool setUp = true,
    List<Override> overrides = const [],
  }) async {
    useTallScreen(tester);
    final clock = ManualClock(DateTime.utc(2026, 10, 17, 12));
    final writes = _WriteSwitch();
    final container = await pumpApp(
      tester,
      overrides: [
        clockProvider.overrideWithValue(clock),
        // The app's commands, with a switch that makes the single writer
        // fail (a database error: `TargetsFailure.unavailable`).
        targetsActionsProvider.overrideWith(
          (ref) => TargetsActions(
            apply: (changes) async {
              await writes.hold?.future;
              if (writes.failing) throw StateError('write failed (test)');
              return await ref.read(changeSetApplierProvider).apply(changes);
            },
            undoStack: ref.watch(undoStackProvider),
            ids: ref.watch(idGeneratorProvider),
            clock: clock,
            read: ref.watch(targetsRepositoryProvider).read,
            settings: ref.watch(settingsStoreProvider),
            bodyWeightKg: ref.watch(bodyWeightReaderProvider),
          ),
        ),
        // The real below-floor confirmations: pumpApp's Today defaults pin
        // them empty, but these screens write and read them (A53 D4).
        dayFloorAcksProvider.overrideWith(
          (ref) =>
              ref.watch(settingsStoreProvider).watch(AppSettings.dayFloorAcks),
        ),
        ...overrides,
      ],
    );
    final rig = TargetsScreenRig._(tester, container, clock, writes);
    if (setUp) {
      final outcome = await rig.settle(
        rig.actions.completeSetup(setupInput(goal: goal)),
      );
      expect(outcome, isA<TargetsDone>());
      await settleWrites(tester);
    }
    if (route != null) await rig.show(route);
    return rig;
  }

  /// The tester.
  final WidgetTester tester;

  /// The app's container.
  final ProviderContainer container;

  /// The app clock.
  final ManualClock clock;

  final _WriteSwitch _writes;

  /// Whether every write fails (the single writer throws).
  bool get failWrites => _writes.failing;
  set failWrites(bool value) => _writes.failing = value;

  /// Holds every write until the returned completer completes.
  Completer<void> holdWrites() => _writes.hold = Completer<void>();

  /// The app's targets commands.
  TargetsActions get actions => container.read(targetsActionsProvider);

  /// Today on the app clock.
  LocalDate get today => EntryTime.now(clock).localDate;

  /// Moves the clock [days] ahead; the screens read today again.
  void advanceDays(int days) {
    clock.advance(Duration(days: days));
    container.invalidate(targetsTodayProvider);
  }

  /// Shows [route] and settles.
  Future<void> show(AppRoute route) async {
    showRoute(container, route);
    await tester.pumpAndSettle();
  }

  /// Waits for [future], started in the test's (fake async) zone: the
  /// database works on the real event loop, so the frames and the real
  /// loop take turns until it completes (a future started inside
  /// `runAsync` would wait on timers of the fake zone and never finish).
  Future<T> settle<T>(Future<T> future) async {
    late T result;
    Object? error;
    var done = false;
    unawaited(
      future.then(
        (value) {
          result = value;
          done = true;
        },
        onError: (Object e) {
          error = e;
          done = true;
        },
      ),
    );
    for (var i = 0; i < 250 && !done; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    if (!done) fail('timed out waiting for the database');
    if (error case final e?) Error.throwWithStackTrace(e, StackTrace.current);
    return result;
  }

  /// A fresh read of the stored targets.
  Future<TargetsData> data() =>
      settle(container.read(targetsRepositoryProvider).read());

  /// Runs [command] and settles.
  Future<T> run<T>(Future<T> Function(TargetsActions actions) command) async {
    final result = await settle(command(actions));
    await settleWrites(tester);
    return result;
  }

  /// Taps the widget showing [text] (the last one; scrolled into the
  /// lazily built list first when needed) and settles.
  Future<void> tap(String text) async {
    if (find.text(text).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Taps [text] and lets the write it started finish.
  Future<void> tapAndSettle(String text) async {
    await tap(text);
    await settleWrites(tester);
  }

  /// Takes the app down.
  Future<void> close() => unmountApp(tester, container);
}

/// Makes the rig's single writer fail while [failing].
final class _WriteSwitch {
  bool failing = false;
  Completer<void>? hold;
}
