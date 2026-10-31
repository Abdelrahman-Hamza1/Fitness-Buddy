// UX-001 end to end on the device (A42 D1, review fix 5). Not run in CI.
//
// One sample per app process: the time from the process's own start (read
// from /proc, so it includes the engine and Dart start, the first frame and
// the database open) to the first frame where Today is ready to use: the
// day's numbers drawn from loaded data (diary totals and targets, no
// skeleton) and the input bar on screen and hit-testable. After the sample,
// the input bar is tapped and Buddy's sheet must take typed text.
//
// Run it with `make perf-startup` (phone over adb): one `seed` run writes a
// realistic month into a profile in the app's support folder, then RUNS
// (default 10) `sample` runs each start a fresh process and print one
// `UX-001 sample` line; the script prints p50/p90 (target p90 ≤ 2,000 ms).
// By hand, from apps/mobile:
//   flutter test integration_test/startup_benchmark_test.dart --profile \
//     --flavor dev --dart-define-from-file=config/dev.json -d <device-id> \
//     --dart-define=A42_STARTUP=seed     (once; then =sample, many times)
// `flutter test` attaches its VM service, a little start overhead that a
// launcher start doesn't have, so the sample errs on the slow side.
// `diagnostic` instead remounts the app 10 times in one warm process
// (the in-app share only); it isn't UX-001.
import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/app_scope.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/buddy/presentation/buddy_sheet.dart';
import 'package:fb_mobile/features/targets/application/targets_providers.dart';
import 'package:fb_mobile/features/today/presentation/today_numbers.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../test/acceptance/support/acceptance_app.dart'
    show SeededProfile, profileSeed;

const String _mode = String.fromEnvironment('A42_STARTUP');

/// Milliseconds since this process started: /proc/uptime minus the
/// process's start time (field 22 of /proc/self/stat, in clock ticks of
/// 1/100 s on Android).
int _processAgeMs() {
  final uptime = double.parse(
    File('/proc/uptime').readAsStringSync().split(' ').first,
  );
  final stat = File('/proc/self/stat').readAsStringSync();
  // The command name (field 2) may hold spaces: count after its ')'.
  final fields = stat.substring(stat.lastIndexOf(')') + 2).split(' ');
  final startTicks = int.parse(fields[19]); // field 22 overall
  return ((uptime - startTicks / 100) * 1000).round();
}

Future<String> _profileRoot() async =>
    '${(await getApplicationSupportDirectory()).path}/fb_perf_startup';

ProviderContainer _container(AppConfig config, String root) =>
    ProviderContainer(
      overrides: [
        ...appOverrides(config),
        databaseLocationProvider.overrideWithValue(
          DatabaseLocation(
            profileKey: 'perf-startup',
            root: () async => root,
            temporary: () async => root,
          ),
        ),
      ],
    );

/// Whether Today is ready to use: its numbers drawn from loaded data (the
/// seeded day's totals, the targets read without error, no skeleton) and
/// the input bar on screen where a tap reaches it.
bool _ready(WidgetTester tester, ProviderContainer container, LocalDate day) {
  final today = find.byType(TodayScreen);
  if (today.evaluate().isEmpty) return false;
  if (find
      .descendant(of: today, matching: find.byType(FbSkeleton))
      .evaluate()
      .isNotEmpty) {
    return false;
  }
  final numbers = tester
      .widgetList<TodayNumbers>(find.byType(TodayNumbers))
      .where((n) => n.date == day && n.totals.kcal > 0);
  if (numbers.isEmpty) return false;
  final targets = container.read(dayTargetsProvider(day));
  if (!targets.hasValue || targets.hasError) return false;
  final input = find.textContaining('Tell Buddy');
  if (input.evaluate().isEmpty) return false;
  final center = tester.getCenter(input.first);
  final box = tester.renderObject<RenderBox>(input.first);
  return tester.hitTestOnBinding(center).path.any((e) => e.target == box);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // covers: UX-001
  testWidgets('UX-001 process start to Today ready (one sample per run)', (
    tester,
  ) async {
    final startAge = _processAgeMs();
    expect(kProfileMode, isTrue, reason: 'Run this benchmark with --profile');
    expect(
      ['seed', 'sample', 'diagnostic'],
      contains(_mode),
      reason: 'Pass --dart-define=A42_STARTUP=seed|sample|diagnostic',
    );
    final config = AppConfig.fromEnvironment();
    final root = await _profileRoot();
    final marker = File('$root/seeded');

    if (_mode == 'seed') {
      if (Directory(root).existsSync()) {
        Directory(root).deleteSync(recursive: true);
      }
      Directory(root).createSync(recursive: true);
      final seeder = _container(config, root);
      final seeded = SeededProfile(
        EntryTime.now(seeder.read(clockProvider)).localDate,
      );
      for (final ops in profileSeed(seeded)) {
        final result = await seeder
            .read(changeSetApplierProvider)
            .apply(ChangeSet(ops, origin: Origin.direct));
        expect(result.toString(), startsWith('Applied'));
      }
      seeder.dispose();
      await Future<void>.delayed(const Duration(seconds: 1));
      marker.writeAsStringSync('${seeded.today}');
      stdout.writeln('UX-001 seeded ${seeded.today}: now run the samples');
      return;
    }
    expect(
      marker.existsSync(),
      isTrue,
      reason: 'No seeded profile (the app data was cleared): run seed first',
    );

    if (_mode == 'sample') {
      final container = _container(config, root);
      addTearDown(container.dispose);
      final day = EntryTime.now(container.read(clockProvider)).localDate;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FitnessBuddyApp(),
        ),
      );
      final firstFrame = _processAgeMs();
      final watch = Stopwatch()..start();
      while (!_ready(tester, container, day)) {
        if (watch.elapsed > const Duration(seconds: 20)) {
          fail(
            'Today was not ready within 20 s (seeded on '
            '${marker.readAsStringSync()}; a seed from another day has no '
            'entries today: run seed again)',
          );
        }
        await tester.pump();
      }
      final ready = _processAgeMs();

      // And it takes input: the bar opens Buddy's sheet, which takes text.
      await tester.tap(find.textContaining('Tell Buddy').first);
      for (
        var i = 0;
        i < 40 && find.byType(BuddySheet).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final field = find.descendant(
        of: find.byType(BuddySheet),
        matching: find.byType(EditableText),
      );
      expect(field, findsOneWidget);
      await tester.enterText(field, 'tea');
      await tester.pump();
      expect(find.text('tea'), findsOneWidget);
      // Printed only once the input works: a failed check gives no sample.
      stdout.writeln(
        'UX-001 sample: $ready ms (process start → Today ready; first '
        'frame at $firstFrame ms; test body began at $startAge ms)',
      );
      return;
    }

    // diagnostic: the in-app share, remounted in this warm process.
    final times = <int>[];
    for (var run = 0; run <= 10; run++) {
      final container = _container(config, root);
      final day = EntryTime.now(container.read(clockProvider)).localDate;
      final watch = Stopwatch()..start();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FitnessBuddyApp(),
        ),
      );
      while (!_ready(tester, container, day)) {
        if (watch.elapsed > const Duration(seconds: 20)) fail('not ready');
        await tester.pump();
      }
      if (run > 0) times.add(watch.elapsedMilliseconds);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    times.sort();
    stdout.writeln(
      'UX-001 diagnostic (warm process, pumpWidget → Today ready): '
      'p50 ${times[times.length ~/ 2]} ms, max ${times.last} ms',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}
