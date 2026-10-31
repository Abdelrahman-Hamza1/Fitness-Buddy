import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

String _id(int value) =>
    '0199e3c2-5b1a-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';
final _today = LocalDate(2026, 10, 28);

const _profile = ProfileRecord(
  heightInputUnit: HeightInputUnit.feetInches,
  sex: FormulaSex.female,
  birthYear: 1987,
  heightCm: 172.5,
  activity: ActivityLevel.moderate,
);
final _phase = GoalPhaseRecord(
  weightInputUnit: MassUnit.pound,
  id: _id(1),
  revision: 2,
  name: 'Wedding cut',
  start: _today,
  type: GoalType.lose,
  expression: GoalExpression.targetDate(63.4, LocalDate(2027, 5, 1)),
);
final _settings = TargetSettingsRecord(
  id: _id(2),
  revision: 1,
  effectiveFrom: _today,
  baseKcal: 1321.7,
  basisWeightKg: 68.9,
  manual: true,
  acknowledged: true,
  mode: TargetMode.fixed,
  dayFactors: {DayOfWeek.friday: 1.3},
  macros: MacroSettings(protein: MacroOverride.grams(141), fiberGrams: 33),
);

void main() {
  test('D4 the targets op family: three puts, create or update by expected '
      'version, value equality', () {
    final ops = <TargetsOp>[
      PutProfile(_profile),
      PutGoalPhase(_phase, expectedVersion: 3),
      PutTargetSettings(_settings),
    ];
    expect(ops.map((op) => op.family).toSet(), {TargetsOp.familyName});
    expect(TargetsOp.familyName, 'targets');
    expect(ops.map((op) => op.part), TargetsPart.values);
    expect(ops.map((op) => op.expectedVersion), [null, 3, null]);
    expect(PutProfile(_profile), PutProfile(_profile));
    expect(PutProfile(_profile).hashCode, PutProfile(_profile).hashCode);
    expect(
      PutProfile(_profile),
      isNot(PutProfile(_profile, expectedVersion: 1)),
    );
    expect(
      PutProfile(_profile),
      isNot(PutProfile(_profile.copyWith(birthYear: 1988))),
    );
    expect(PutGoalPhase(_phase), PutGoalPhase(_phase));
    expect(PutGoalPhase(_phase).hashCode, PutGoalPhase(_phase).hashCode);
    expect(PutGoalPhase(_phase), isNot(PutGoalPhase(_phase.withName(null))));
    expect(PutTargetSettings(_settings), PutTargetSettings(_settings));
    expect(
      PutTargetSettings(_settings).hashCode,
      PutTargetSettings(_settings).hashCode,
    );
    expect(
      PutTargetSettings(_settings),
      isNot(PutTargetSettings(_settings, expectedVersion: 2)),
    );
    expect(PutGoalPhase(_phase), isNot(PutTargetSettings(_settings)));
    expect(() => PutProfile(_profile, expectedVersion: 0), throwsArgumentError);
    expect(
      () => PutGoalPhase(_phase.copyWith(id: 'not-a-uuid')),
      throwsArgumentError,
    );
    expect(
      () => PutTargetSettings(
        _settings.copyWith(id: '0199e3c2-5b1a-4000-8000-000000000002'),
      ),
      throwsArgumentError,
    );
    expect(ChangeSet(ops, origin: Origin.direct).ops, ops);
  });

  test('D4 TargetsChanged names the parts that changed, in any order', () {
    final event = TargetsChanged([TargetsPart.settings, TargetsPart.profile]);
    expect(event, TargetsChanged([TargetsPart.profile, TargetsPart.settings]));
    expect(
      event.hashCode,
      TargetsChanged([TargetsPart.profile, TargetsPart.settings]).hashCode,
    );
    expect(event, isNot(TargetsChanged([TargetsPart.profile])));
    expect(event.parts.clear, throwsUnsupportedError);
    expect('$event', 'TargetsChanged(profile, settings)');
  });

  test('PA14 toString of every targets op, record and command outcome (incl. '
      'TargetsNeedsAcknowledgement and TargetsDone) shows no body values, '
      'names, weights or kcal', () {
    final values = <Object>[
      _profile,
      _phase,
      _settings,
      PutProfile(_profile),
      PutProfile(_profile, expectedVersion: 4),
      PutGoalPhase(_phase, expectedVersion: 2),
      PutTargetSettings(_settings),
      TargetsChanged(TargetsPart.values),
      const TargetsDone(
        'undo-1',
        TargetsChangeKind.profileUpdated,
        recomputedKcal: 2143.6,
        warnings: {TargetWarning.calorieFloorApplied},
      ),
      const TargetsUnchanged(),
      const TargetsPending(),
      TargetsNeedsAcknowledgement(
        floorKcal: 1544.4,
        impliedKgPerWeek: -.83,
        warnings: [
          TargetWarning.manualLossRateExceeded,
          TargetWarning.manualBelowFloor,
        ],
      ),
      for (final reason in TargetsFailure.values) TargetsFailed(reason),
      DayIntake(date: _today, kcal: 1834.2, entryCount: 5),
    ];
    final forbidden = [
      '1987',
      '172',
      'female',
      'moderate',
      'Wedding',
      '63.4',
      '2027',
      '1321',
      '68.9',
      '141',
      '33',
      '1.3',
      '2143',
      '1544',
      '0.83',
      '1834',
      'targetDate',
    ];
    for (final value in values) {
      final text = '$value';
      for (final secret in forbidden) {
        expect(text, isNot(contains(secret)), reason: text);
      }
    }
    expect('${PutProfile(_profile)}', 'TargetsOp.putProfile(create)');
    expect(
      '${PutGoalPhase(_phase, expectedVersion: 2)}',
      'TargetsOp.putGoalPhase(update)',
    );
    expect(
      '${PutTargetSettings(_settings)}',
      'TargetsOp.putTargetSettings(create)',
    );
    expect(
      '${const TargetsDone('u', TargetsChangeKind.targetsSet)}',
      'TargetsDone(targetsSet)',
    );
    final both = TargetsNeedsAcknowledgement(
      floorKcal: 1,
      impliedKgPerWeek: 0,
      warnings: [
        TargetWarning.manualLossRateExceeded,
        TargetWarning.manualBelowFloor,
      ],
    );
    expect(
      '$both',
      'TargetsNeedsAcknowledgement(manualBelowFloor, manualLossRateExceeded)',
    );
    expect(
      '${const TargetsFailed(TargetsFailure.fixedBelowFloor)}',
      'TargetsFailed(fixedBelowFloor)',
    );
  });

  test('D11 command outcomes carry their typed fields', () {
    const done = TargetsDone(
      'undo-1',
      TargetsChangeKind.phaseStarted,
      recomputedKcal: 2000,
      warnings: {TargetWarning.lossRateCapped},
    );
    expect(done.undoEntryId, 'undo-1');
    expect(done.kind, TargetsChangeKind.phaseStarted);
    expect(done.recomputedKcal, 2000);
    expect(done.warnings, {TargetWarning.lossRateCapped});
    expect(
      const TargetsDone('u', TargetsChangeKind.goalUpdated).recomputedKcal,
      isNull,
    );
    final needs = TargetsNeedsAcknowledgement(
      floorKcal: 1600,
      impliedKgPerWeek: -1.2,
      warnings: [TargetWarning.manualBelowFloor],
    );
    expect(needs.floorKcal, 1600);
    expect(needs.impliedKgPerWeek, -1.2);
    expect(needs.warnings.clear, throwsUnsupportedError);
    expect(
      const TargetsFailed(TargetsFailure.changed).reason,
      TargetsFailure.changed,
    );
    expect(TargetsChangeKind.values, hasLength(5));
  });
}
