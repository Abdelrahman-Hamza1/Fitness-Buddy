import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

// Saturday-start weeks (D-070): Sat 31 Oct – Fri 6 Nov 2026; today is
// Saturday 7 Nov, the first day of the next week.
final LocalDate _today = LocalDate(2026, 11, 7);

LocalDate _ago(int days) => _today.plusDays(-days);

final DailyMacros _macros = MacroPlan.calculate(
  baseKcal: 2000,
  weightKg: 80,
).forDay(2000);

ProgressDay _day(
  LocalDate date, {
  double kcal = 2000,
  double protein = 150,
  DayStatus? status,
  IntakeTotals? intake,
  double? target = 2000,
}) => ProgressDay(
  date: date,
  intake:
      intake ??
      IntakeTotals.known(
        Nutrients(kcal: kcal, protein: protein, carbs: 200, fat: 60, fiber: 25),
      ),
  entryCount: 3,
  status: status ?? (date == _today ? DayStatus.inProgress : DayStatus.logged),
  targetKcal: target,
  targetMacros: target == null ? null : _macros,
);

QueryPlan _plan(
  QueryMetric metric,
  QueryOp op, [
  QueryPeriod period = const QueryPeriod(QueryPeriodKind.today),
  QueryFilters filters = const QueryFilters(),
  String? measurementType,
]) => QueryPlan(
  metric: metric,
  op: op,
  period: period,
  filters: filters,
  measurementType: measurementType,
);

QueryAnswer _answer(QueryPlan plan, QueryData data) {
  final window = QueryEngine.window(plan.period, today: _today)!;
  return QueryEngine.answer(plan, window: window, data: data)!;
}

double? _value(QueryAnswer a) => a.claims.single.value;

const _lastWeek = QueryPeriod(QueryPeriodKind.lastWeek);
const _last7 = QueryPeriod(QueryPeriodKind.lastNDays, days: 7);

QueryExercise _ex(
  String ref,
  List<SetValues> sets, {
  ExerciseType? type = ExerciseType.weightReps,
  Muscle? primary = Muscle.chest,
}) => (ref: ref, type: type, primary: primary, sets: sets);

SetValues _set(double kg, int reps) => SetValues(kg: kg, reps: reps);

void main() {
  group('AQ-09 grammar (06 §6.3)', () {
    test('valid combinations only', () {
      const today = QueryPeriod(QueryPeriodKind.today);
      bool ok(QueryMetric m, QueryOp op, {QueryPeriod period = today}) =>
          QueryEngine.supports(_plan(m, op, period));
      expect(ok(QueryMetric.protein, QueryOp.remaining), isTrue);
      expect(
        ok(QueryMetric.protein, QueryOp.remaining, period: _last7),
        isFalse,
      );
      expect(ok(QueryMetric.weight, QueryOp.remaining), isFalse);
      expect(ok(QueryMetric.kcal, QueryOp.average), isTrue);
      expect(ok(QueryMetric.volume, QueryOp.max), isTrue);
      expect(ok(QueryMetric.weight, QueryOp.average), isFalse);
      expect(ok(QueryMetric.weightTrend, QueryOp.change), isTrue);
      expect(ok(QueryMetric.kcal, QueryOp.latest), isFalse);
      expect(ok(QueryMetric.loggedDays, QueryOp.count), isTrue);
      expect(ok(QueryMetric.kcal, QueryOp.count), isFalse);
      expect(ok(QueryMetric.exerciseLastDate, QueryOp.last), isFalse);
      expect(ok(QueryMetric.workouts, QueryOp.last), isFalse);
      expect(ok(QueryMetric.measurement, QueryOp.latest), isFalse);
      expect(
        QueryEngine.supports(
          _plan(
            QueryMetric.measurement,
            QueryOp.latest,
            today,
            const QueryFilters(),
            'waist',
          ),
        ),
        isTrue,
      );
    });

    test('filters must apply to the metric', () {
      expect(
        QueryEngine.supports(
          _plan(
            QueryMetric.exerciseLastDate,
            QueryOp.last,
            _last7,
            const QueryFilters(muscleGroup: 'Legs'),
          ),
        ),
        isTrue,
      );
      for (final filters in [
        const QueryFilters(muscleGroup: 'wings'),
        const QueryFilters(weekdays: {8}),
        const QueryFilters(exerciseRef: 'bench'),
      ]) {
        expect(
          QueryEngine.supports(
            _plan(QueryMetric.kcal, QueryOp.total, _last7, filters),
          ),
          isFalse,
        );
      }
      expect(
        QueryEngine.supports(
          _plan(
            QueryMetric.kcal,
            QueryOp.remaining,
            const QueryPeriod(QueryPeriodKind.today),
            const QueryFilters(slot: 'lunch'),
          ),
        ),
        isFalse,
      );
      expect(
        QueryEngine.supports(
          _plan(
            QueryMetric.workouts,
            QueryOp.count,
            _last7,
            const QueryFilters(slot: 'lunch'),
          ),
        ),
        isFalse,
      );
      // A PR needs one exercise, not a group.
      expect(
        QueryEngine.supports(
          _plan(
            QueryMetric.exercisePr,
            QueryOp.latest,
            _last7,
            const QueryFilters(muscleGroup: 'chest'),
          ),
        ),
        isFalse,
      );
      expect(
        QueryEngine.answer(
          _plan(QueryMetric.weight, QueryOp.total),
          window: (from: _today, to: _today),
          data: const QueryData(),
        ),
        isNull,
      );
    });

    test('each plan reads only what it needs', () {
      expect(QueryEngine.needs(_plan(QueryMetric.fiber, QueryOp.total)), {
        QueryInput.days,
      });
      expect(
        QueryEngine.needs(
          _plan(
            QueryMetric.kcal,
            QueryOp.total,
            _last7,
            const QueryFilters(slot: 'lunch'),
          ),
        ),
        {QueryInput.days, QueryInput.slotIntake},
      );
      expect(QueryEngine.needs(_plan(QueryMetric.loggedDays, QueryOp.count)), {
        QueryInput.days,
      });
      expect(QueryEngine.needs(_plan(QueryMetric.weighIns, QueryOp.count)), {
        QueryInput.weights,
      });
      expect(
        QueryEngine.needs(_plan(QueryMetric.weightTrend, QueryOp.latest)),
        {QueryInput.trend},
      );
      expect(
        QueryEngine.needs(_plan(QueryMetric.measurement, QueryOp.latest)),
        {QueryInput.measurements},
      );
      for (final m in [
        QueryMetric.workouts,
        QueryMetric.sets,
        QueryMetric.volume,
        QueryMetric.exerciseLastDate,
        QueryMetric.exercisePr,
      ]) {
        expect(QueryEngine.needs(_plan(m, QueryOp.count)), {
          QueryInput.sessions,
        });
      }
    });

    test('a weightTrend has no weekday filter', () {
      expect(
        QueryEngine.supports(
          _plan(
            QueryMetric.weightTrend,
            QueryOp.change,
            _last7,
            const QueryFilters(weekdays: {1}),
          ),
        ),
        isFalse,
      );
    });

    test('muscle names', () {
      expect(musclesNamed('legs'), contains(Muscle.quadriceps));
      expect(musclesNamed('Upper back'), {Muscle.upperBack});
      expect(musclesNamed('quads'), {Muscle.quadriceps});
      expect(musclesNamed('arms'), hasLength(3));
      expect(musclesNamed('feet'), isNull);
    });
  });

  group('AQ-09 windows (D-070 week start, ≤ 400 days)', () {
    QueryWindow? w(QueryPeriod p, {LocalDate? ramadan, LocalDate? phase}) =>
        QueryEngine.window(
          p,
          today: _today,
          ramadanStart: ramadan,
          phaseStart: phase,
        );

    test('named periods', () {
      expect(w(const QueryPeriod(QueryPeriodKind.yesterday)), (
        from: _ago(1),
        to: _ago(1),
      ));
      // Today is Saturday: this week is today only, last week the 7 days
      // before.
      expect(w(const QueryPeriod(QueryPeriodKind.thisWeek)), (
        from: _today,
        to: _today,
      ));
      expect(w(_lastWeek), (from: _ago(7), to: _ago(1)));
      expect(
        QueryEngine.window(
          _lastWeek,
          today: _today,
          calendar: const WeekCalendar(weekStart: DayOfWeek.monday),
        ),
        (from: LocalDate(2026, 10, 26), to: LocalDate(2026, 11, 1)),
      );
      expect(w(const QueryPeriod(QueryPeriodKind.thisMonth)), (
        from: LocalDate(2026, 11, 1),
        to: _today,
      ));
      expect(w(const QueryPeriod(QueryPeriodKind.lastMonth)), (
        from: LocalDate(2026, 10, 1),
        to: LocalDate(2026, 10, 31),
      ));
      expect(
        QueryEngine.window(
          const QueryPeriod(QueryPeriodKind.lastMonth),
          today: LocalDate(2027, 1, 15),
        ),
        (from: LocalDate(2026, 12, 1), to: LocalDate(2026, 12, 31)),
      );
      expect(w(_last7), (from: _ago(6), to: _today));
    });

    test('since, range, and the limits', () {
      const ramadan = QueryPeriod(
        QueryPeriodKind.since,
        since: QuerySince.ramadanStart,
      );
      expect(w(ramadan), isNull, reason: 'no Ramadan known');
      expect(w(ramadan, ramadan: LocalDate(2026, 2, 18)), (
        from: LocalDate(2026, 2, 18),
        to: _today,
      ));
      expect(
        w(
          const QueryPeriod(
            QueryPeriodKind.since,
            since: QuerySince.phaseStart,
          ),
          phase: _ago(30),
        ),
        (from: _ago(30), to: _today),
      );
      expect(
        w(
          QueryPeriod(
            QueryPeriodKind.since,
            since: QuerySince.date,
            from: _ago(3),
          ),
        ),
        (from: _ago(3), to: _today),
      );
      // A range ending in the future ends today.
      expect(
        w(
          QueryPeriod(
            QueryPeriodKind.range,
            from: _ago(2),
            to: _today.plusDays(5),
          ),
        ),
        (from: _ago(2), to: _today),
      );
      expect(
        w(QueryPeriod(QueryPeriodKind.range, from: _ago(400), to: _today)),
        isNull,
      );
      expect(
        w(QueryPeriod(QueryPeriodKind.range, from: _ago(399), to: _today)),
        isNotNull,
      );
      expect(
        w(
          QueryPeriod(
            QueryPeriodKind.range,
            from: _today.plusDays(1),
            to: _today.plusDays(2),
          ),
        ),
        isNull,
      );
      expect(
        w(const QueryPeriod(QueryPeriodKind.lastNDays, days: 401)),
        isNull,
      );
      expect(w(const QueryPeriod(QueryPeriodKind.range)), isNull);
      expect(w(const QueryPeriod(QueryPeriodKind.since)), isNull);
    });
  });

  group('AQ-09 AI-110 nutrients', () {
    test('protein left today = target − eaten; no target → no claim', () {
      final plan = _plan(QueryMetric.protein, QueryOp.remaining);
      final a = _answer(plan, QueryData(days: [_day(_today, protein: 90)]));
      expect(_value(a), closeTo(_macros.proteinGrams - 90, 0.05));
      expect(a.claims.single.unit, QueryUnit.g);
      expect(a.link, QueryLink(QueryLinkScreen.diary, date: _today));
      final none = _answer(plan, QueryData(days: [_day(_today, target: null)]));
      expect(none.claims, isEmpty);
      // Over target stays negative.
      final over = _answer(
        _plan(QueryMetric.kcal, QueryOp.remaining),
        QueryData(days: [_day(_today, kcal: 2250.4)]),
      );
      expect(_value(over), -250);
      final day = QueryData(days: [_day(_today)]);
      for (final (metric, target) in [
        (QueryMetric.carbs, _macros.carbsGrams),
        (QueryMetric.fat, _macros.fatGrams),
        (QueryMetric.fiber, _macros.fiberGrams),
      ]) {
        final left = _answer(_plan(metric, QueryOp.remaining), day);
        expect(
          left.claims.singleOrNull?.value,
          target == null
              ? isNull
              : closeTo(
                  target -
                      (metric == QueryMetric.fiber
                          ? 25
                          : metric == QueryMetric.fat
                          ? 60
                          : 200),
                  0.05,
                ),
        );
      }
    });

    test('average kcal last week: counted days only (not today, not '
        'incomplete, never unknown days)', () {
      final days = [
        _day(_ago(7), kcal: 1800),
        _day(_ago(6), kcal: 2200),
        _day(_ago(5), kcal: 900, status: DayStatus.incomplete),
        _day(_ago(4), kcal: 2100.6),
        // An estimated day counts for kcal (A62 D10).
        _day(
          _ago(3),
          intake: IntakeTotals.ofDayEstimate(2500),
          status: DayStatus.estimated,
        ),
        _day(_today, kcal: 300),
      ];
      final a = _answer(
        _plan(QueryMetric.kcal, QueryOp.average, _lastWeek),
        QueryData(days: days),
      );
      expect(_value(a), ((1800 + 2200 + 2100.6 + 2500) / 4).roundToDouble());
      expect(a.days, 7);
      expect(a.loggedDays, 5);
      expect(
        a.link,
        QueryLink(QueryLinkScreen.progress, from: _ago(7), to: _ago(1)),
      );
      // Every day with intake when complete days aren't asked for.
      final all = _answer(
        _plan(
          QueryMetric.kcal,
          QueryOp.average,
          _lastWeek,
          const QueryFilters(completeDaysOnly: false),
        ),
        QueryData(days: days),
      );
      expect(
        _value(all),
        ((1800 + 2200 + 900 + 2100.6 + 2500) / 5).roundToDouble(),
      );
    });

    test("a macro average skips days where it isn't fully known", () {
      final partial = IntakeTotals.fromCounts(
        sum: Nutrients(kcal: 1500, protein: 40, carbs: 100, fat: 50, fiber: 10),
        items: 3,
        estimates: 0,
        proteinUnknown: 1,
      );
      final a = _answer(
        _plan(QueryMetric.protein, QueryOp.average, _lastWeek),
        QueryData(
          days: [
            _day(_ago(7), protein: 120),
            _day(_ago(6), protein: 140),
            _day(_ago(5), intake: partial),
            _day(
              _ago(4),
              intake: IntakeTotals.ofDayEstimate(2000),
              status: DayStatus.estimated,
            ),
          ],
        ),
      );
      expect(_value(a), 130);
    });

    test(
      'a partly known macro gives no exact claim; its coverage says why',
      () {
        final partial = IntakeTotals.fromCounts(
          sum: Nutrients(kcal: 900, protein: 40, carbs: 100, fat: 30, fiber: 5),
          items: 2,
          estimates: 0,
          proteinUnknown: 1,
        );
        final left = _answer(
          _plan(QueryMetric.protein, QueryOp.remaining),
          QueryData(days: [_day(_today, intake: partial)]),
        );
        expect(left.claims, isEmpty);
        expect(left.days, 1);
        expect(left.loggedDays, 0, reason: 'protein not fully known today');
        final total = _answer(
          _plan(QueryMetric.protein, QueryOp.total, _last7),
          QueryData(
            days: [
              _day(_ago(1), protein: 100),
              _day(_today, intake: partial),
            ],
          ),
        );
        expect(total.claims, isEmpty);
        expect(total.loggedDays, 1);
        // kcal is always known.
        final kcal = _answer(
          _plan(QueryMetric.kcal, QueryOp.remaining),
          QueryData(days: [_day(_today, intake: partial)]),
        );
        expect(kcal.loggedDays, 1);
        expect(_value(kcal), 2000 - 900);
      },
    );

    test('total includes today; max and min carry their day', () {
      final days = [
        _day(_ago(2), kcal: 1900),
        _day(_ago(1), kcal: 2400),
        _day(_today, kcal: 700),
      ];
      final total = _answer(
        _plan(QueryMetric.kcal, QueryOp.total, _last7),
        QueryData(days: days),
      );
      expect(_value(total), 5000);
      final max = _answer(
        _plan(QueryMetric.kcal, QueryOp.max, _last7),
        QueryData(days: days),
      );
      expect(max.claims.single.value, 2400);
      expect(max.claims.single.date, _ago(1));
      final min = _answer(
        _plan(QueryMetric.kcal, QueryOp.min, _last7),
        QueryData(days: days),
      );
      expect(min.claims.single.date, _ago(2), reason: 'today is not complete');
      final complete = _answer(
        _plan(
          QueryMetric.kcal,
          QueryOp.total,
          _last7,
          const QueryFilters(completeDaysOnly: true),
        ),
        QueryData(days: days),
      );
      expect(_value(complete), 4300);
      expect(
        _answer(
          _plan(QueryMetric.kcal, QueryOp.total, _last7),
          const QueryData(),
        ).claims,
        isEmpty,
      );
    });

    test('slot and weekday filters', () {
      final days = [_day(_ago(7)), _day(_ago(6)), _day(_ago(5))];
      final a = _answer(
        _plan(
          QueryMetric.kcal,
          QueryOp.average,
          _lastWeek,
          const QueryFilters(slot: 'breakfast'),
        ),
        QueryData(
          days: days,
          slotIntake: {
            _ago(7): IntakeTotals.known(
              Nutrients(kcal: 400, protein: 20, carbs: 50, fat: 10, fiber: 4),
            ),
            _ago(5): IntakeTotals.known(
              Nutrients(kcal: 600, protein: 30, carbs: 70, fat: 20, fiber: 6),
            ),
          },
        ),
      );
      expect(_value(a), 500);
      expect(a.loggedDays, 2);
      // Saturdays (ISO 6) only: _ago(7) is a Saturday.
      final sat = _answer(
        _plan(
          QueryMetric.kcal,
          QueryOp.total,
          _lastWeek,
          const QueryFilters(weekdays: {6}),
        ),
        QueryData(days: [_day(_ago(7), kcal: 1234), _day(_ago(6), kcal: 999)]),
      );
      expect(_value(sat), 1234);
      expect(sat.days, 1);
    });

    test('logged days', () {
      final days = [
        _day(_ago(3)),
        _day(_ago(2), status: DayStatus.incomplete),
        _day(_today),
      ];
      expect(
        _value(
          _answer(
            _plan(QueryMetric.loggedDays, QueryOp.count, _last7),
            QueryData(days: days),
          ),
        ),
        3,
      );
      expect(
        _value(
          _answer(
            _plan(
              QueryMetric.loggedDays,
              QueryOp.count,
              _last7,
              const QueryFilters(completeDaysOnly: true),
            ),
            QueryData(days: days),
          ),
        ),
        1,
      );
    });
  });

  group('AQ-09 AI-110 body', () {
    final weights = [
      (date: _ago(1), value: 81.26),
      (date: _ago(6), value: 82.0),
      (date: _ago(3), value: 81.5),
    ];

    test('weight latest, change and weigh-ins', () {
      final latest = _answer(
        _plan(QueryMetric.weight, QueryOp.latest, _last7),
        QueryData(weights: weights),
      );
      expect(latest.claims.single.value, 81.3);
      expect(latest.claims.single.date, _ago(1));
      expect(latest.link?.screen, QueryLinkScreen.weightGraph);
      final change = _answer(
        _plan(QueryMetric.weight, QueryOp.change, _last7),
        QueryData(weights: weights),
      );
      expect(_value(change), -0.7);
      expect(
        _answer(
          _plan(QueryMetric.weight, QueryOp.change, _last7),
          QueryData(weights: [weights.first]),
        ).claims,
        isEmpty,
      );
      expect(
        _value(
          _answer(
            _plan(QueryMetric.weighIns, QueryOp.count, _last7),
            QueryData(weights: weights),
          ),
        ),
        3,
      );
    });

    test('trend change since Ramadan runs from the day before', () {
      final start = LocalDate(2026, 2, 18);
      const plan = QueryPlan(
        metric: QueryMetric.weightTrend,
        op: QueryOp.change,
        period: QueryPeriod(
          QueryPeriodKind.since,
          since: QuerySince.ramadanStart,
        ),
      );
      final window = QueryEngine.window(
        plan.period,
        today: _today,
        ramadanStart: start,
      )!;
      double? trend(LocalDate d) => d == start.plusDays(-1)
          ? 86.04
          : d == _today
          ? 81.0
          : null;
      final a = QueryEngine.answer(
        plan,
        window: window,
        data: QueryData(trendOn: trend),
      )!;
      expect(_value(a), -5);
      // Without the day before, from the first day; unknown end → none.
      final b = QueryEngine.answer(
        plan,
        window: window,
        data: QueryData(
          trendOn: (d) => d == start
              ? 85.0
              : d == _today
              ? 81.0
              : null,
        ),
      )!;
      expect(_value(b), -4);
      expect(
        QueryEngine.answer(
          plan,
          window: window,
          data: const QueryData(),
        )!.claims,
        isEmpty,
      );
      final latest = _answer(
        _plan(QueryMetric.weightTrend, QueryOp.latest, _last7),
        QueryData(trendOn: (d) => d == _today ? 80.96 : null),
      );
      expect(latest.claims.single.value, 81);
      expect(latest.claims.single.date, _today);
    });

    test('a body-fat measurement is in percent, others in cm', () {
      final values = [
        (date: _ago(5), value: 21.4),
        (date: _ago(1), value: 20.9),
      ];
      final fat = _answer(
        _plan(
          QueryMetric.measurement,
          QueryOp.change,
          _last7,
          const QueryFilters(),
          'bodyFat',
        ),
        QueryData(values: values),
      );
      expect(fat.claims.single.unit, QueryUnit.percent);
      expect(_value(fat), -0.5);
      final waist = _answer(
        _plan(
          QueryMetric.measurement,
          QueryOp.latest,
          _last7,
          const QueryFilters(),
          'waist',
        ),
        QueryData(values: values),
      );
      expect(waist.claims.single.unit, QueryUnit.cm);
      expect(waist.loggedDays, 2);
    });
  });

  group('AQ-09 AI-110 workouts', () {
    final sessions = <QuerySession>[
      (
        id: 'a',
        date: _ago(20),
        exercises: [
          _ex('bench', [_set(70, 5)]),
        ],
      ),
      (
        id: 'b',
        date: _ago(5),
        exercises: [
          _ex('bench', [_set(80, 5), _set(75, 8)]),
          _ex('squat', [_set(100, 5)], primary: Muscle.quadriceps),
        ],
      ),
      (
        id: 'c',
        date: _ago(2),
        exercises: [
          _ex('curl', [_set(15, 10)], primary: Muscle.biceps),
          _ex(
            'plank',
            [const SetValues(durationSeconds: 60)],
            type: ExerciseType.duration,
            primary: Muscle.abs,
          ),
        ],
      ),
      (
        id: 'd',
        date: _ago(2),
        exercises: [
          _ex('lunge', [_set(20, 10)], primary: Muscle.glutes),
        ],
      ),
    ];

    test('when did I last do legs: the latest session, its workout and '
        'group', () {
      final a = _answer(
        _plan(
          QueryMetric.exerciseLastDate,
          QueryOp.last,
          _last7,
          const QueryFilters(muscleGroup: 'legs'),
        ),
        QueryData(sessions: sessions),
      );
      final claim = a.claims.single;
      expect(claim.date, _ago(2));
      expect(claim.value, isNull);
      expect(claim.unit, QueryUnit.date);
      expect(claim.workoutId, 'd');
      expect(claim.exerciseRef, 'lunge');
      expect(claim.muscleGroup, MuscleGroup.legs);
      expect(a.link, const QueryLink(QueryLinkScreen.workout, workoutId: 'd'));
      final none = _answer(
        _plan(
          QueryMetric.exerciseLastDate,
          QueryOp.last,
          _last7,
          const QueryFilters(exerciseRef: 'deadlift'),
        ),
        QueryData(sessions: sessions),
      );
      expect(none.claims, isEmpty);
    });

    test('workouts, sets and volume', () {
      expect(
        _value(
          _answer(
            _plan(QueryMetric.workouts, QueryOp.count, _last7),
            QueryData(sessions: sessions),
          ),
        ),
        3,
      );
      expect(
        _value(
          _answer(
            _plan(
              QueryMetric.workouts,
              QueryOp.count,
              _last7,
              const QueryFilters(exerciseRef: 'bench'),
            ),
            QueryData(sessions: sessions),
          ),
        ),
        1,
      );
      expect(
        _value(
          _answer(
            _plan(QueryMetric.sets, QueryOp.total, _last7),
            QueryData(sessions: sessions),
          ),
        ),
        6,
      );
      final avg = _answer(
        _plan(QueryMetric.sets, QueryOp.average, _last7),
        QueryData(sessions: sessions),
      );
      expect(_value(avg), 2);
      // 80×5 + 75×8 + 100×5 = 1500; the time set has no volume.
      final max = _answer(
        _plan(QueryMetric.volume, QueryOp.max, _last7),
        QueryData(sessions: sessions),
      );
      expect(max.claims.single.value, 1500);
      expect(max.claims.single.date, _ago(5));
      final total = _answer(
        _plan(QueryMetric.volume, QueryOp.total, _last7),
        QueryData(sessions: sessions),
      );
      expect(_value(total), 1500 + 150 + 200);
      expect(
        _answer(
          _plan(QueryMetric.volume, QueryOp.total, _last7),
          const QueryData(),
        ).claims,
        isEmpty,
      );
    });

    test('bench PR: the heaviest in the window, the change over the best '
        'before it', () {
      const bench = QueryFilters(exerciseRef: 'bench');
      final latest = _answer(
        _plan(QueryMetric.exercisePr, QueryOp.latest, _last7, bench),
        QueryData(sessions: sessions),
      );
      expect(latest.claims.single.value, 80);
      expect(latest.claims.single.date, _ago(5));
      expect(
        latest.link,
        const QueryLink(QueryLinkScreen.exercise, exerciseRef: 'bench'),
      );
      final change = _answer(
        _plan(QueryMetric.exercisePr, QueryOp.change, _last7, bench),
        QueryData(sessions: sessions),
      );
      expect(_value(change), 10);
      final first = _answer(
        _plan(QueryMetric.exercisePr, QueryOp.change, _last7, bench),
        QueryData(sessions: sessions.skip(1).toList()),
      );
      expect(first.claims, isEmpty, reason: 'no earlier record');
    });
  });

  test('AI-112 links survive their JSON form; broken ones are dropped', () {
    final links = [
      QueryLink(QueryLinkScreen.diary, date: _today),
      QueryLink(QueryLinkScreen.progress, from: _ago(6), to: _today),
      const QueryLink(QueryLinkScreen.exercise, exerciseRef: 'bench'),
      const QueryLink(QueryLinkScreen.workout, workoutId: 'w1'),
      const QueryLink(QueryLinkScreen.weightGraph),
    ];
    for (final link in links) {
      expect(QueryLink.fromJson(link.toJson()), link);
      expect(link.hashCode, QueryLink.fromJson(link.toJson()).hashCode);
    }
    expect(QueryLink.fromJson({'screen': 'diary'}), isNull);
    expect(QueryLink.fromJson({'screen': 'exercise'}), isNull);
    expect(QueryLink.fromJson({'screen': 'workout'}), isNull);
    expect(QueryLink.fromJson({'screen': 'moon'}), isNull);
    expect(QueryLink.fromJson('diary'), isNull);
  });

  test("AI-120 a suggestion fits within 5 % over today's target", () {
    expect(SuggestionFit.fits(remainingKcal: -100, targetKcal: 2000), isTrue);
    expect(SuggestionFit.fits(remainingKcal: -101, targetKcal: 2000), isFalse);
    expect(SuggestionFit.fits(remainingKcal: null, targetKcal: 2000), isTrue);
    expect(SuggestionFit.fits(remainingKcal: -500, targetKcal: null), isTrue);
  });

  test('content-free strings', () {
    const claim = QueryClaim(
      metric: QueryMetric.kcal,
      op: QueryOp.total,
      unit: QueryUnit.kcal,
      value: 1,
    );
    expect(
      claim,
      const QueryClaim(
        metric: QueryMetric.kcal,
        op: QueryOp.total,
        unit: QueryUnit.kcal,
        value: 1,
      ),
    );
    expect(claim.hashCode, isA<int>());
    expect('$claim', 'QueryClaim(kcal, total)');
    expect(
      _plan(
        QueryMetric.kcal,
        QueryOp.total,
        _last7,
        const QueryFilters(slot: 'secret'),
      ).toString(),
      isNot(contains('secret')),
    );
    expect('${const QueryFilters(slot: 'secret')}', isNot(contains('secret')));
    expect(
      '${QueryAnswer(claims: const [], days: 1, loggedDays: 0)}',
      contains('0/1'),
    );
    expect('${const QueryData()}', 'QueryData()');
    expect('${const QueryLink(QueryLinkScreen.diary)}', 'QueryLink(diary)');
  });
}
