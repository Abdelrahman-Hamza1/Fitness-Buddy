import 'package:drift/drift.dart'
    show
        ApplyInterceptor,
        QueryExecutor,
        QueryInterceptor,
        Variable,
        driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../core/catalog/support/catalog_support.dart' show writeFixturePack;
import '../core/db/support/db_support.dart'
    show FixedPack, memoryDatabase, tempDir;
import '../features/foods/presentation/support/personal_food_support.dart'
    show settle, useWindow;
import '../helpers/pump_app.dart';
import 'support/acceptance_app.dart';

/// Tables that grow with use (a row per entry, weigh-in, set, message…).
/// A full scan of one of them gets slower every week, so every read the
/// screens make must search them through an index. Small, bounded tables
/// (settings, slots, profile, goal phases, targets, templates, the plan,
/// custom exercises, measurement types, saved meals) may be scanned.
const _growing = {
  'diary_entries',
  'dish_groups',
  'day_marks',
  'saved_meal_items',
  'personal_foods',
  'weigh_ins',
  'measurements',
  'workout_sessions',
  'session_exercises',
  'workout_sets',
  'chat_messages',
  'proposals',
  'sync_outbox',
  'sync_parked',
  'sync_deferred',
  'sync_displaced',
};

/// The full reads of a growing table that are accepted, and why: by design
/// (the screen shows or computes over every row) or a known gap logged in
/// the backlog. Each is matched by a pattern of its SQL and of its plan
/// line, and listed in the test output.
final _accepted = <(RegExp sql, RegExp plan, String why)>[
  (
    RegExp('FROM "personal_foods" WHERE "deleted_at" IS NULL'),
    RegExp('SCAN personal_foods'),
    'by design: the personal foods list and its search show every live '
        "food of the user's own (hundreds at most)",
  ),
  (
    RegExp(r'^SELECT 1 FROM .* LIMIT 0$'),
    RegExp('SCAN'),
    'reads no row (LIMIT 0)',
  ),
  (
    RegExp('FROM "weigh_ins" WHERE "deleted_at" IS NULL ORDER BY'),
    RegExp('USING INDEX ix_weigh_ins_live'),
    'by design: the trend (A14) and the weight history use every live '
        'weigh-in, in index order (about one a day)',
  ),
  (
    RegExp('FROM "measurements" WHERE "deleted_at" IS NULL ORDER BY'),
    RegExp('USING INDEX ix_measurements_live'),
    'by design: the measurement history and graphs use every live '
        'measurement, in index order',
  ),
  (
    RegExp(r'FROM "proposals" .*"status" = \?'),
    RegExp('USING INDEX ix_proposals_pending'),
    'bounded: ix_proposals_pending is a partial index holding only the '
        'pending cards',
  ),
  (
    RegExp('FROM "workout_sessions" WHERE "deleted_at" IS NULL ORDER BY'),
    RegExp('USING INDEX ix_workout_sessions_date'),
    "by design for the workout history (every session, A37a); Today's "
        'workout row reusing it is backlog #265',
  ),
  (
    RegExp('SELECT slot_id, COUNT.* FROM diary_entries .*GROUP BY slot_id'),
    RegExp('SCAN diary_entries'),
    'known gap, backlog #266: the meal slot editor counts entries per meal '
        'over all days (one index pass); a partial (slot_id) index waits '
        'for the next schema migration',
  ),
];

/// Records every SELECT the app runs, with its arguments and where in the
/// sweep it ran.
final class _SelectRecorder extends QueryInterceptor {
  final Map<String, (List<Object?>, Set<String>)> selects = {};
  String place = 'start';

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selects.putIfAbsent(statement, () => (args, <String>{})).$2.add(place);
    return super.runSelect(executor, statement, args);
  }
}

/// The `detail` lines of EXPLAIN QUERY PLAN for [sql] with [args].
Future<List<String>> _plan(
  AppDatabase db,
  String sql,
  List<Object?> args,
) async {
  final rows = await runAuthorizedWrite(
    () => db
        .customSelect(
          'EXPLAIN QUERY PLAN $sql',
          variables: [for (final a in args) Variable(a)],
        )
        .get(),
  );
  return [for (final row in rows) row.read<String>('detail')];
}

/// The tables of [sql] by the names its plan may use: each table's own
/// name and its alias (`FROM diary_entries d`, `JOIN weigh_ins AS w`).
Map<String, String> _aliases(String sql) {
  const keywords = {
    'WHERE', 'ON', 'JOIN', 'LEFT', 'INNER', 'CROSS', 'GROUP', 'ORDER', //
    'LIMIT', 'UNION', 'USING', 'AND', 'OR', 'NATURAL', 'OUTER', 'WINDOW',
    'HAVING', 'INDEXED', 'NOT', 'AS',
  };
  final names = <String, String>{};
  final from = RegExp(
    r'\b(?:FROM|JOIN)\s+"?(\w+)"?(?:\s+(?:AS\s+)?"?(\w+)"?)?',
    caseSensitive: false,
  );
  for (final m in from.allMatches(sql)) {
    final table = m.group(1)!;
    names[table] = table;
    final alias = m.group(2);
    if (alias != null && !keywords.contains(alias.toUpperCase())) {
      names[alias] = table;
    }
  }
  return names;
}

/// The growing table a plan line reads in full, if any: every `SCAN` (of
/// the table, or of a whole index of it, covering or not) is a full read;
/// only `SEARCH` narrows it. Plan names are resolved through [sql]'s
/// aliases.
String? _fullScan(String detail, String sql) {
  final scan = RegExp(r'^SCAN (\w+)(?: AS (\w+))?').firstMatch(detail);
  if (scan == null) return null;
  final aliases = _aliases(sql);
  final name = scan.group(1)!;
  final table = aliases[name] ?? name;
  return _growing.contains(table) ? table : null;
}

/// The reason [sql]'s plan line [detail] may read a whole table, if it is
/// an accepted one.
String? _justified(String sql, String detail) {
  for (final (query, plan, why) in _accepted) {
    if (query.hasMatch(sql.trim()) && plan.hasMatch(detail)) return why;
  }
  return null;
}

/// The app's interactions that read on demand: search, period and range
/// changes, other days. Each sets [recorder]'s place first.
Future<void> _interact(
  WidgetTester tester,
  _SelectRecorder recorder,
  ProviderContainer container,
) async {
  Future<void> tapText(String text) async {
    final target = find.text(text);
    expect(target, findsWidgets, reason: text);
    await tester.ensureVisible(target.first);
    await settle(tester);
    await tester.tap(target.first);
    await settle(tester);
  }

  final router = container.read(appRouterProvider);

  recorder.place = 'Today: the days before';
  final pages = find.byType(PageView).first;
  for (var i = 0; i < 3; i++) {
    await tester.fling(pages, const Offset(300, 0), 1500);
    await settle(tester);
  }

  recorder.place = 'Food search: typing';
  router.go(const FoodSearchRoute());
  await settle(tester);
  await tester.enterText(find.byType(TextField).first, 'rice');
  await settle(tester);
  await tester.enterText(find.byType(TextField).first, 'labneh');
  await settle(tester);

  recorder.place = 'Progress: periods';
  router.go(const ProgressRoute());
  await settle(tester);
  await tapText('Month');
  await tapText('Phase');
  await tapText('Week');

  recorder.place = 'Weight graph: ranges';
  router.go(const WeightGraphRoute());
  await settle(tester);
  for (final range in ['3M', '6M', '1Y', '1M']) {
    await tapText(range);
  }

  recorder.place = 'Exercise picker: search';
  router.go(const WorkoutExercisesRoute());
  await settle(tester);
  await tester.enterText(find.byType(TextField).first, 'fly');
  await settle(tester);
}

void main() {
  test('the audit reads real SQLite plans: a scan of a growing table, by '
      'name, alias or whole index, is a full read; a search is not', () async {
    final db = memoryDatabase();
    Future<String?> full(String sql) async {
      for (final detail in await _plan(db, sql, const [])) {
        if (_fullScan(detail, sql) case final table?) return table;
      }
      return null;
    }

    expect(
      await full('SELECT * FROM diary_entries WHERE kcal > 1'),
      'diary_entries',
    );
    expect(
      await full('SELECT d.id FROM diary_entries d WHERE d.kcal > 1'),
      'diary_entries',
    );
    expect(
      await full('SELECT local_date FROM diary_entries ORDER BY local_date'),
      'diary_entries',
      reason: 'a walk of a whole index is still a full read',
    );
    expect(
      await full(
        "SELECT id FROM diary_entries WHERE local_date = '2026-10-17' "
        'AND deleted_at IS NULL',
      ),
      isNull,
    );
    expect(await full('SELECT * FROM meal_slots'), isNull);
  });

  testWidgets('UX-007 every read the screens and their interactions make '
      'searches the growing tables through an index (no full table or '
      'index scan) unless it is a listed, justified full read', (tester) async {
    final recorder = _SelectRecorder();
    late AppDatabase db;
    final pack = writeFixturePack('${tempDir().path}/catalog-1.db');
    useWindow(tester, width: 360, height: 800);
    final container = await pumpApp(
      tester,
      overrides: [
        // The real food search over the fixture pack, not a stub.
        barcodeCameraEnabledProvider.overrideWithValue(false),
        appDatabaseProvider.overrideWith((ref) {
          driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
          db = AppDatabase(
            NativeDatabase.memory().interceptWith(recorder),
            catalog: FixedPack(pack),
          );
          addTearDown(
            () => db.close().timeout(
              const Duration(seconds: 1),
              onTimeout: () {},
            ),
          );
          return db;
        }),
      ],
    );
    final seeded = await seedProfile(tester, container);
    await visitEveryRoute(
      tester,
      container,
      seeded,
      (where) async => recorder.place = where,
    );
    await visitStates(tester, seeded, (where) async => recorder.place = where);
    await _interact(tester, recorder, container);

    final selects = {
      for (final MapEntry(:key, :value) in recorder.selects.entries)
        if (!key.trimLeft().toUpperCase().startsWith('EXPLAIN')) key: value,
    };
    final findings = <String>[];
    final allowed = <String>[];
    for (final MapEntry(key: sql, value: (args, places)) in selects.entries) {
      final place = places.first;
      final plan = (await tester.runAsync(() => _plan(db, sql, args)))!;
      for (final detail in plan) {
        if (_fullScan(detail, sql) case final table?) {
          final line = '[$place] $table: $detail\n  $sql';
          if (_justified(sql, detail) case final why?) {
            allowed.add('$line\n  allowed: $why');
          } else {
            findings.add(line);
          }
        }
      }
    }
    await unmountApp(tester, container);
    // The justified full reads go to the test log for the review.
    // ignore: avoid_print
    print(
      'A42 query audit: ${selects.length} distinct reads; justified '
      'full reads:\n${allowed.join('\n')}',
    );
    expect(selects.length, greaterThan(20), reason: 'the screens read');
    expect(
      selects.values.expand((v) => v.$2),
      containsAll(['Food search: typing', 'Progress: periods']),
      reason: 'the interactions ran their own reads',
    );
    expect(findings, isEmpty, reason: findings.join('\n\n'));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
