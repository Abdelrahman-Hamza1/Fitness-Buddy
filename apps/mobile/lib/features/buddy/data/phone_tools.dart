import 'dart:convert';

import 'package:fb_api_client/fb_api_client.dart' hide LocalDate;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/data/buddy_phone_reads.dart';
import 'package:fb_mobile/features/buddy/data/personal_slice.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'phone_tools.g.dart';

/// The scopes the phone enforces whatever a call asks for (`06` §4.2,
/// TD-127) and the per-turn disclosure budget.
abstract final class PhoneToolScopes {
  /// `findMyFoods` matches.
  static const myFoods = 20;

  /// `readDiary` days and rows.
  static const diaryDays = 31;

  /// See [diaryDays].
  static const diaryRows = 40;

  /// `readBody` raw values: days and rows.
  static const bodyDays = 31;

  /// See [bodyDays].
  static const bodyRows = 31;

  /// `readBody` trend days.
  static const trendDays = 365;

  /// `readWorkouts` days and sessions.
  static const workoutDays = 90;

  /// See [workoutDays].
  static const workoutSessions = 15;

  /// `readMemory` items.
  static const memory = 30;

  /// Names in results (food, slot, exercise), UTF-16 units (B25 caps).
  static const name = 200;

  /// Workout session names.
  static const sessionName = 120;

  /// Exercise refs.
  static const ref = 64;

  /// Exercises per workout session.
  static const exercises = 30;

  /// Sets per exercise.
  static const sets = 50;

  /// Rows across a turn's phone results.
  static const turnRows = 120;

  /// Bytes across a turn's phone results (48 KiB).
  static const int turnBytes = 48 * 1024;
}

/// Buddy's phone tools (A66 D11, `06` §4.2): each call is answered from
/// local data under its scope, inside the turn's disclosure budget
/// (≤ [PhoneToolScopes.turnRows] rows and [PhoneToolScopes.turnBytes]
/// bytes across all results); past it a call gets `budgetExceeded`. Results
/// carry local IDs (the server swaps them for handles). Read-only; nothing
/// here logs.
final class PhoneTools {
  /// The tools over [_reads].
  const new(this._reads);

  final BuddyPhoneReads _reads;

  /// Answers [calls] (raw JSON) for a turn on [today] that already
  /// disclosed [rows] rows and [bytes] bytes: one raw result per call, in
  /// order, and the new totals.
  Future<({List<Map<String, Object?>> results, int rows, int bytes})> run(
    List<Map<String, Object?>> calls, {
    required LocalDate today,
    required int rows,
    required int bytes,
  }) async {
    var usedRows = rows;
    var usedBytes = bytes;
    final results = <Map<String, Object?>>[];
    for (final raw in calls) {
      final name = raw['name'];
      final callId = raw['callId'];
      if (name is! String || callId is! String) continue;
      BuddyPhoneToolCall call;
      try {
        call = BuddyPhoneToolCall.fromJson(raw);
        // A call that doesn't decode is answered invalidArgs.
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {
        call = const BuddyPhoneToolCall.unrecognized();
      }
      // A tool this version doesn't know (06 §4.2, B25 handoff): the
      // `unsupported` result variant, so the round can go on.
      if (!_known.contains(name)) {
        results.add(
          _json(
            BuddyPhoneToolResult.unsupported(
              name: BuddyUnsupportedResultName.unsupported,
              callId: callId,
              ok: false,
              error: BuddyPhoneToolError.unsupported,
            ),
          ),
        );
        continue;
      }
      final (data, count) = await _answer(call, today);
      final ok = data != null;
      final error = switch (call) {
        BuddyPhoneToolCallUnrecognized() => BuddyPhoneToolError.invalidArgs,
        BuddyPhoneToolCallQueryData() => BuddyPhoneToolError.unsupportedPlan,
        _ => BuddyPhoneToolError.invalidArgs,
      };
      var result = <String, Object?>{
        'name': name,
        'callId': callId,
        'ok': ok,
        'error': ok ? null : error.json,
        'data': data,
      };
      final size = utf8.encode(jsonEncode(result)).length;
      if (ok &&
          (usedRows + count > PhoneToolScopes.turnRows ||
              usedBytes + size > PhoneToolScopes.turnBytes)) {
        result = {
          'name': name,
          'callId': callId,
          'ok': false,
          'error': BuddyPhoneToolError.budgetExceeded.json,
          'data': null,
        };
      } else if (ok) {
        usedRows += count;
        usedBytes += size;
      }
      results.add(result);
    }
    return (results: results, rows: usedRows, bytes: usedBytes);
  }

  static const _known = {
    'findMyFoods',
    'readDiary',
    'readBody',
    'readWorkouts',
    'readMemory',
    'queryData',
  };

  /// The data of [call] as JSON and its row count; `null` data for a call
  /// that can't be answered.
  Future<(Map<String, Object?>?, int)> _answer(
    BuddyPhoneToolCall call,
    LocalDate today,
  ) async {
    switch (call) {
      case BuddyPhoneToolCallFindMyFoods(:final args):
        final kinds = args.kinds;
        final items =
            kinds.isNotEmpty && !kinds.contains(BuddyPersonalKind.personalFood)
            ? const <BuddyPersonalItem>[]
            : PersonalSlice.match(args.query, await _reads.personalFoods());
        return (_json(BuddyFindMyFoodsData(items: items)), items.length);
      case BuddyPhoneToolCallReadDiary(:final args):
        return await _diary(args, today);
      case BuddyPhoneToolCallReadBody(:final args):
        return await _body(args, today);
      case BuddyPhoneToolCallReadWorkouts(:final args):
        return await _workouts(args, today);
      case BuddyPhoneToolCallReadMemory():
        // Memory items come with A67's table.
        return (_json(const BuddyReadMemoryData(items: [])), 0);
      case BuddyPhoneToolCallQueryData():
      // The QueryEngine is A68's.
      case BuddyPhoneToolCallUnrecognized():
        return (null, 0);
    }
  }

  /// [range] clamped to at most [days] days ending no later than [today];
  /// `null` when it can't be read.
  static (LocalDate, LocalDate)? _clamp(
    BuddyDateRange range,
    LocalDate today,
    int days,
  ) {
    final from = LocalDate.tryParse(range.from);
    var to = LocalDate.tryParse(range.to);
    if (from == null || to == null) return null;
    if (to.isAfter(today)) to = today;
    if (from.isAfter(to)) return null;
    final earliest = to.plusDays(-(days - 1));
    return (from.isBefore(earliest) ? earliest : from, to);
  }

  Future<(Map<String, Object?>?, int)> _diary(
    BuddyReadDiaryArgs args,
    LocalDate today,
  ) async {
    final (LocalDate, LocalDate)? span;
    if (args.range case final range?) {
      span = _clamp(range, today, PhoneToolScopes.diaryDays);
    } else if (args.dateHint case final hint?) {
      final day = DayHint.resolve(hint, today);
      span = day == null ? null : (day, day);
    } else {
      span = (today, today);
    }
    if (span == null) return (null, 0);
    final (entries, slots) = await _reads.diary(span.$1, span.$2);
    final slotName = {
      for (final s in slots) s.id: (s.name ?? s.defaultKey ?? s.id).trim(),
    };
    final wantSlot = args.slotHint == null
        ? null
        : PersonalSlice.wordsOf(args.slotHint!);
    final wantFood = args.query == null
        ? null
        : PersonalSlice.wordsOf(args.query!);
    final picked = [
      for (final e in entries)
        if ((wantSlot == null ||
                wantSlot.isEmpty ||
                PersonalSlice.wordsOf('${e.slotId} ${slotName[e.slotId] ?? ''}')
                    .intersection(wantSlot)
                    .isNotEmpty) &&
            (wantFood == null ||
                wantFood.isEmpty ||
                PersonalSlice.wordsOf(e.food.names.en)
                    .intersection(wantFood)
                    .isNotEmpty))
          e,
    ];
    final rows = [
      for (final e in picked.take(PhoneToolScopes.diaryRows))
        BuddyDiaryRow(
          name: _cut(e.food.names.en, PhoneToolScopes.name),
          id: e.id,
          date: e.localDate.toString(),
          slot: _cut(slotName[e.slotId] ?? e.slotId, PhoneToolScopes.name),
          grams: e.amount.basis == NutrientBasis.per100g
              ? e.amount.amount
              : null,
          kcal: e.snapshot.kcal,
        ),
    ];
    return (
      _json(
        BuddyReadDiaryData(
          entries: rows,
          truncated: picked.length > rows.length,
        ),
      ),
      rows.length,
    );
  }

  Future<(Map<String, Object?>?, int)> _body(
    BuddyReadBodyArgs args,
    LocalDate today,
  ) async {
    switch (args.what) {
      case BuddyBodyRead.weight:
        final span = _clamp(args.range, today, PhoneToolScopes.bodyDays);
        if (span == null) return (null, 0);
        final weights = await _reads.weights(span.$1, span.$2);
        final values = [
          for (final (date, kg) in weights.reversed.take(
            PhoneToolScopes.bodyRows,
          ))
            BuddyBodyValue(
              date: date.toString(),
              metric: 'weight',
              value: kg,
              unit: BuddyBodyUnit.kg,
            ),
        ].reversed.toList();
        return (
          _json(BuddyReadBodyData(values: values, trend: null)),
          values.length,
        );
      case BuddyBodyRead.trend:
        final span = _clamp(args.range, today, PhoneToolScopes.trendDays);
        if (span == null) return (null, 0);
        final weights = await _reads.weights(span.$1, span.$2);
        if (weights.isEmpty) {
          return (_json(const BuddyReadBodyData(values: [], trend: null)), 0);
        }
        final (first, start) = weights.first;
        final (last, end) = weights.last;
        final days = first.daysUntil(last);
        return (
          _json(
            BuddyReadBodyData(
              values: const [],
              trend: BuddyWeightTrend(
                from: first.toString(),
                to: last.toString(),
                startKg: start,
                endKg: end,
                changeKg: end - start,
                weeklyChangeKg: days >= 7 ? (end - start) / days * 7 : null,
                weighIns: weights.length,
              ),
            ),
          ),
          1,
        );
      case BuddyBodyRead.measurements:
      case BuddyBodyRead.$unknown:
        // Measurements join with A69's card; nothing is disclosed yet.
        return (_json(const BuddyReadBodyData(values: [], trend: null)), 0);
    }
  }

  Future<(Map<String, Object?>?, int)> _workouts(
    BuddyReadWorkoutsArgs args,
    LocalDate today,
  ) async {
    final span = _clamp(args.range, today, PhoneToolScopes.workoutDays);
    if (span == null) return (null, 0);
    final sessions = await _reads.sessions(
      span.$1,
      span.$2,
      limit: PhoneToolScopes.workoutSessions,
      exerciseId: args.exerciseRef,
    );
    final rows = [
      for (final s in sessions)
        BuddyWorkoutSessionRow(
          name: s.name == null
              ? null
              : _cut(s.name!, PhoneToolScopes.sessionName),
          id: s.id,
          date: s.date.toString(),
          exercises: [
            for (final e in s.exercises.take(PhoneToolScopes.exercises))
              BuddyWorkoutExerciseRow(
                name: _cut(e.name, PhoneToolScopes.name),
                exerciseRef: _cut(e.exerciseId, PhoneToolScopes.ref),
                sets: [
                  for (final set in e.sets.take(PhoneToolScopes.sets))
                    BuddySetRow(
                      reps: set.reps,
                      kg: set.kg,
                      durationSeconds: set.durationSeconds,
                      distanceMeters: set.distanceMeters,
                    ),
                ],
              ),
          ],
        ),
    ];
    // PRs are A68's (the QueryEngine computes them).
    return (
      _json(BuddyReadWorkoutsData(sessions: rows, prs: const [])),
      rows.length,
    );
  }

  /// [value] cut to [limit] UTF-16 units, never inside a surrogate pair.
  static String _cut(String value, int limit) {
    if (value.length <= limit) return value;
    var end = limit;
    final unit = value.codeUnitAt(end - 1);
    if (unit >= 0xD800 && unit <= 0xDBFF) end--;
    return value.substring(0, end);
  }

  /// A generated model as plain nested JSON.
  static Map<String, Object?> _json(Object model) =>
      jsonDecode(jsonEncode(model)) as Map<String, Object?>;

  @override
  String toString() => 'PhoneTools';
}

/// The app's phone tools.
@Riverpod(keepAlive: true)
PhoneTools phoneTools(Ref ref) =>
    PhoneTools(ref.watch(buddyPhoneReadsProvider));
