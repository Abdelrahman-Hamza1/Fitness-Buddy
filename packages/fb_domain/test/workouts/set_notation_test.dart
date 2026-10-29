import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

const MassUnit _kg = MassUnit.kilogram;
const MassUnit _lb = MassUnit.pound;

ParsedSet _w(int reps, double w, [MassUnit unit = _kg]) =>
    ParsedSet(reps: reps, inputWeight: w, unit: unit, load: LoadKind.weight);

ParsedSet _add(int reps, double w, [MassUnit unit = _kg]) =>
    ParsedSet(reps: reps, inputWeight: w, unit: unit, load: LoadKind.added);

ParsedSet _assist(int reps, double w) =>
    ParsedSet(reps: reps, inputWeight: w, unit: _kg, load: LoadKind.assistance);

ParsedSet _r(int reps) => ParsedSet(reps: reps);

List<ParsedSet> _n(int count, ParsedSet set) => List.filled(count, set);

/// (notation, expected name, expected sets).
final _goldens = <(String, String?, List<ParsedSet>)>[
  // sets x reps weight
  ('3x8 80', null, _n(3, _w(8, 80))),
  ('3×8 80', null, _n(3, _w(8, 80))),
  ('3*8 80', null, _n(3, _w(8, 80))),
  ('3X8 80', null, _n(3, _w(8, 80))),
  ('3 x 8 80', null, _n(3, _w(8, 80))),
  ('3x8@80', null, _n(3, _w(8, 80))),
  ('3×8@80', null, _n(3, _w(8, 80))),
  ('3x8 @ 80', null, _n(3, _w(8, 80))),
  ('3x8 82.5', null, _n(3, _w(8, 82.5))),
  ('3x8 80kg', null, _n(3, _w(8, 80))),
  ('3x8 80 kg', null, _n(3, _w(8, 80))),
  ('3x8 176lb', null, _n(3, _w(8, 176, _lb))),
  ('3x8 176 lbs', null, _n(3, _w(8, 176, _lb))),
  ('bench 3x8 80', 'bench', _n(3, _w(8, 80))),
  ('Flat Bench 3x8 80', 'flat bench', _n(3, _w(8, 80))),
  ('ohp 3x10 40', 'ohp', _n(3, _w(10, 40))),
  ('3 sets of 8 at 80', null, _n(3, _w(8, 80))),
  ('3 sets of 8 reps at 80kg', null, _n(3, _w(8, 80))),
  // weight x reps x sets
  ('80x8x3', null, _n(3, _w(8, 80))),
  ('80×8×3', null, _n(3, _w(8, 80))),
  ('82.5x8x3', null, _n(3, _w(8, 82.5))),
  ('80kgx8x3', null, _n(3, _w(8, 80))),
  ('3x8x80', null, _n(3, _w(8, 80))),
  // reps lists
  ('8,8,7 @80', null, [_w(8, 80), _w(8, 80), _w(7, 80)]),
  ('8, 8, 7 @ 80', null, [_w(8, 80), _w(8, 80), _w(7, 80)]),
  ('8,8,7 80', null, [_w(8, 80), _w(8, 80), _w(7, 80)]),
  (
    '12,10,8 @ 100lb',
    null,
    [_w(12, 100, _lb), _w(10, 100, _lb), _w(8, 100, _lb)],
  ),
  ('20,15,12', null, [_r(20), _r(15), _r(12)]),
  // varying weights
  ('80x8, 85x6, 85x5', null, [_w(8, 80), _w(6, 85), _w(5, 85)]),
  ('80x8,85x6', null, [_w(8, 80), _w(6, 85)]),
  ('3x8 80, 2x6 85', null, [..._n(3, _w(8, 80)), ..._n(2, _w(6, 85))]),
  ('60kg x 10, 70kg x 8', null, [_w(10, 60), _w(8, 70)]),
  // bodyweight, added load and assistance
  ('dips +10 3x8', 'dips', _n(3, _add(8, 10))),
  ('dips 3x8 +10', 'dips', _n(3, _add(8, 10))),
  ('pull ups +20lb 3x6', 'pull ups', _n(3, _add(6, 20, _lb))),
  ('+10x8', null, [_add(8, 10)]),
  ('assisted pull-up -20 3x8', 'assisted pull-up', _n(3, _assist(8, 20))),
  ('dips 3x12', 'dips', _n(3, _r(12))),
  ('push-ups 3x15', 'push-ups', _n(3, _r(15))),
  ('push ups 20', 'push ups', [_r(20)]),
  // ambiguity rule: AxB without weight
  ('10x10', null, _n(10, _r(10))),
  ('80x8', null, [_w(8, 80)]),
  ('12x10', null, [_w(10, 12)]),
  ('80 3x8', null, _n(3, _w(8, 80))),
  ('80kg 3x8', null, _n(3, _w(8, 80))),
  // explicit units and set syntax beat the bare AxB rule
  ('5kgx8', null, [_w(8, 5)]),
  ('5 kg x 8', null, [_w(8, 5)]),
  ('10lbx12', null, [_w(12, 10, _lb)]),
  ('12 sets of 8', null, _n(12, _r(8))),
  ('12 sets of 8 reps', null, _n(12, _r(8))),
  ('3x8x80kg', null, _n(3, _w(8, 80))),
  ('2.5x10', null, [_w(10, 2.5)]),
  // durations and cardio
  ('plank 60s', 'plank', [const ParsedSet(durationSeconds: 60)]),
  ('plank 3x45s', 'plank', _n(3, const ParsedSet(durationSeconds: 45))),
  ('treadmill 30 min', 'treadmill', [const ParsedSet(durationSeconds: 1800)]),
  (
    'treadmill 30min 3km',
    'treadmill',
    [const ParsedSet(durationSeconds: 1800, distanceMeters: 3000)],
  ),
  (
    'walk 1 h 5 km',
    'walk',
    [const ParsedSet(durationSeconds: 3600, distanceMeters: 5000)],
  ),
  (
    'row 20 min 4000 m',
    'row',
    [const ParsedSet(durationSeconds: 1200, distanceMeters: 4000)],
  ),
];

final _rejected = <(String, SetNotationIssue)>[
  ('', SetNotationIssue.empty),
  ('bench', SetNotationIssue.empty),
  ('3x8 80kg 85lb', SetNotationIssue.mixedUnits),
  ('3x0 80', SetNotationIssue.outOfRange),
  ('0x8 80', SetNotationIssue.outOfRange),
  ('3x8 1200', SetNotationIssue.outOfRange),
  ('3x8 2500lb', SetNotationIssue.outOfRange),
  ('25x8 80', SetNotationIssue.outOfRange),
  ('3x8 0', SetNotationIssue.outOfRange),
  ('3x8 80 then 85', SetNotationIssue.unrecognized),
  ('3x8x8x8', SetNotationIssue.unrecognized),
  ('plank 0s', SetNotationIssue.outOfRange),
];

void main() {
  test('WO-031 golden notation set has at least 40 cases', () {
    expect(_goldens.length, greaterThanOrEqualTo(40));
  });

  for (final (text, name, sets) in _goldens) {
    test('WO-031 parses "$text"', () {
      final result = SetNotationParser.parse(text);
      expect(result, isA<SetNotationParsed>(), reason: text);
      final parsed = result as SetNotationParsed;
      expect(parsed.name, name);
      expect(parsed.sets, sets);
    });
  }

  for (final (text, issue) in _rejected) {
    test('WO-031 rejects "$text" as ${issue.name}', () {
      final result = SetNotationParser.parse(text);
      expect(result, isA<SetNotationRejected>(), reason: text);
      expect((result as SetNotationRejected).issue, issue);
    });
  }

  test('WO-031 weights without a unit use the default unit', () {
    final result = SetNotationParser.parse(
      '3x8 135',
      defaultUnit: MassUnit.pound,
    ) as SetNotationParsed;
    expect(result.sets.first.unit, MassUnit.pound);
    expect(result.sets.first.kg, closeTo(61.235, 0.001));
  });

  test('WO-031 lb converts to kg exactly', () {
    final result = SetNotationParser.parse('1x1 100lb') as SetNotationParsed;
    expect(result.sets.single.kg, closeTo(45.359237, 1e-9));
    expect(result.sets.single.inputWeight, 100);
  });

  test('WO-005 a dumbbell weight is per dumbbell, never doubled', () {
    final result = SetNotationParser.parse(
      'incline db press 3x10 30',
    ) as SetNotationParsed;
    expect(result.sets.every((s) => s.kg == 30), isTrue);
    expect(Equipment.dumbbell.weightIsPerImplement, isTrue);
    expect(Equipment.barbell.weightIsPerImplement, isFalse);
  });

  test('WO-004 parsed values feed the per-type check', () {
    final bench = SetNotationParser.parse('3x8 80') as SetNotationParsed;
    expect(bench.sets.first.values.issueFor(ExerciseType.weightReps), isNull);
    final dips = SetNotationParser.parse('dips +10 3x8') as SetNotationParsed;
    expect(
      dips.sets.first.values.issueFor(ExerciseType.bodyweightReps),
      isNull,
    );
    final plank = SetNotationParser.parse('plank 60s') as SetNotationParsed;
    expect(plank.sets.first.values.issueFor(ExerciseType.duration), isNull);
    expect(
      plank.sets.first.values.issueFor(ExerciseType.weightReps),
      WorkoutSetIssue.reps,
    );
  });

  test('WO-031 a default unit other than kg or lb is a caller error', () {
    expect(
      () => SetNotationParser.parse('3x8 80', defaultUnit: MassUnit.gram),
      throwsArgumentError,
    );
  });
}
