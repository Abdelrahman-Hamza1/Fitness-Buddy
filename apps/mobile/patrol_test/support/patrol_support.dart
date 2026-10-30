import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/app_scope.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/quick_add/quick_add.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol/patrol.dart';

// What the device journeys share (A08 lessons): bounded waits in real time,
// taps that prove they land, a summary of the screen for a timeout, and the
// app started on a throw-away profile. The CI emulator is 320 x 640 dp, so a
// control can be under a sheet, a snackbar or the keyboard.

/// Pumps in real time until [done] holds; fails with [reason] and what is on
/// screen after [timeout]. Local work only (database, pack), so the bounds
/// are generous for a slow emulator but nothing waits on a network.
Future<void> waitUntil(
  WidgetTester tester,
  bool Function() done,
  String reason, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final watch = Stopwatch()..start();
  while (!done()) {
    if (watch.elapsed > timeout) {
      fail('Timed out waiting for $reason; on screen: ${screenSummary()}');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  // One more frame so the widgets reflect the state that satisfied [done].
  await tester.pump(const Duration(milliseconds: 100));
}

/// The same, for a condition that needs an `await` (the database).
Future<void> waitUntilAsync(
  WidgetTester tester,
  Future<bool> Function() done,
  String reason, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final watch = Stopwatch()..start();
  while (!await done().timeout(
    timeout,
    onTimeout: () => throw TestFailure('Timed out awaiting $reason'),
  )) {
    if (watch.elapsed > timeout) fail('Timed out waiting for $reason');
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Lets animations and queued frames finish, in real time.
Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  final watch = Stopwatch()..start();
  while (watch.elapsed < duration) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Whether a tap at [point] would reach [target] (or something inside it).
bool hitsTarget(WidgetTester tester, Finder target, Offset point) {
  final box = tester.renderObject<RenderBox>(target);
  return tester
      .hitTestOnBinding(point)
      .path
      .any(
        (entry) =>
            entry.target is RenderObject &&
            _isDescendant(entry.target as RenderObject, box),
      );
}

/// Taps [target] after proving the tap point really hits it; otherwise fails
/// with what is there instead (a tap that misses is otherwise silent).
///
/// A layout that is still moving (a sheet sliding in, the quick-add row
/// growing in above the input bar, A09b) can cover the target for a moment, so
/// a miss is looked at again, up to [attempts] times, before it fails.
Future<void> tapExactly(
  WidgetTester tester,
  Finder target,
  String what, {
  int attempts = 3,
}) async {
  for (var attempt = 1; attempt <= attempts; attempt++) {
    await tester.ensureVisible(target);
    await pumpFor(tester, const Duration(milliseconds: 300));
    if (hitsTarget(tester, target, tester.getCenter(target))) {
      await tester.tap(target);
      return;
    }
    if (attempt < attempts) await pumpFor(tester, const Duration(seconds: 1));
  }
  final box = tester.renderObject<RenderBox>(target);
  final center = tester.getCenter(target);
  final result = tester.hitTestOnBinding(center);
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  String describe(Iterable<Object> targets) =>
      targets.take(40).map((t) => t.runtimeType.toString()).join(' > ');
  final route = ModalRoute.of(tester.element(target));
  final sheets = find.byType(BottomSheet);
  final sheetRect = sheets.evaluate().isEmpty
      ? 'none'
      : '${tester.getRect(sheets.last)}';
  final first = describe(result.path.map((e) => e.target));
  // Is it transient (an animation) or structural? Look again after 2 s.
  await pumpFor(tester, const Duration(seconds: 2));
  final hitsLater =
      target.evaluate().isNotEmpty &&
      hitsTarget(tester, target, tester.getCenter(target));
  fail(
    'Tap on $what would miss after $attempts attempts: center=$center, '
    'rect=${tester.getRect(target)}, screen=$size, sheet=$sheetRect, '
    'route current=${route?.isCurrent} active=${route?.isActive} '
    'animation=${route?.animation?.status} '
    'secondary=${route?.secondaryAnimation?.status}; '
    'hits after 2 s=$hitsLater; path=[$first]; '
    'target box=${box.runtimeType}; '
    'on screen: ${screenSummary()}',
  );
}

bool _isDescendant(RenderObject child, RenderObject ancestor) {
  RenderObject? node = child;
  while (node != null) {
    if (identical(node, ancestor)) return true;
    node = node.parent;
  }
  return false;
}

/// What a failed wait saw: open sheets and the texts in sheets and
/// snackbars (synthetic test data only), so CI annotations explain a timeout.
String screenSummary() {
  String texts(Finder of) => find
      .descendant(of: of, matching: find.byType(Text))
      .evaluate()
      .map((e) => (e.widget as Text).data ?? '')
      .where((t) => t.isNotEmpty)
      .take(40)
      .join(' | ');
  final sheets = find.byType(BottomSheet);
  final snacks = find.byType(SnackBar);
  final buttons = find
      .byType(FbButton)
      .evaluate()
      .map((e) => e.widget as FbButton)
      .map((b) => '${b.label}:${b.onPressed == null ? 'off' : 'on'}')
      .join(' ');
  // The quick-add chip row can cover the bottom of the day's list (A09b), so a
  // missed tap on Today needs its chips and the pager's and bar's rects.
  final chips = find
      .byType(FbQuickAddChip)
      .evaluate()
      .map((e) => (e.widget as FbQuickAddChip).label)
      .join(' | ');
  String rectOf(Finder finder) {
    final found = finder.evaluate();
    if (found.length != 1) return 'x${found.length}';
    final box = found.single.renderObject;
    if (box is! RenderBox || !box.attached || !box.hasSize) return 'unlaid';
    final top = box.localToGlobal(Offset.zero);
    return '${top.dy.toStringAsFixed(0)}-'
        '${(top.dy + box.size.height).toStringAsFixed(0)}';
  }

  return 'sheets=${sheets.evaluate().length} [${texts(sheets)}]; '
      'snackbars=${snacks.evaluate().length} [${texts(snacks)}]; '
      'buttons [$buttons]; '
      'quick-add chips [$chips]; '
      'y-ranges pager ${rectOf(find.byType(PageView))} '
      'chip row ${rectOf(find.byType(QuickAddBar))}';
}

/// drift opens the database in a background isolate and sends the location's
/// resolvers there, so they must capture only the path (a closure written in
/// the test body would capture the WidgetTester and can't be sent).
DatabaseLocation isolatedLocation(String profileKey, String path) =>
    DatabaseLocation(
      profileKey: profileKey,
      root: () async => path,
      temporary: () async => path,
    );

/// Starts the real app on a throw-away profile database in the cache
/// directory (a phone's real diary is never touched), waits for the pack,
/// and returns the container. No API is reachable.
Future<ProviderContainer> bootApp(
  PatrolIntegrationTester $,
  String profileKey, {
  String rootName = 'fb_it',
  List<Override> overrides = const [],
}) async {
  final config = AppConfig.fromEnvironment();
  final cache = await getTemporaryDirectory();
  final root = await cache.createTemp(rootName);
  addTearDown(() {
    try {
      root.deleteSync(recursive: true);
    } on FileSystemException {
      // The cache directory is cleaned by the system anyway.
    }
  });
  final container = ProviderContainer(
    overrides: [
      ...appOverrides(config),
      databaseLocationProvider.overrideWithValue(
        isolatedLocation(profileKey, root.path),
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  final tester = $.tester;

  // Loading skeletons pulse continuously; wait for data below, not settle.
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const FitnessBuddyApp(),
    ),
  );
  expect($(TodayScreen), findsOneWidget);

  // The pack installs in the background after the first frame; wait for it
  // before searching.
  final db = container.read(appDatabaseProvider);
  await waitUntilAsync(
    tester,
    db.isCatalogAttached,
    'the catalog pack to attach',
    timeout: const Duration(seconds: 60),
  );
  return container;
}
