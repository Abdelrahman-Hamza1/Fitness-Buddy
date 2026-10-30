import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/body.dart';
import '../helpers/measurement.dart';

void main() {
  test('WB-040 built-in kinds are waist, chest, hips, arm, thigh, neck and '
      'body fat; custom types are named lengths', () {
    expect(MeasurementKind.builtIns.map((k) => k.code), [
      'waist',
      'chest',
      'hips',
      'arm',
      'thigh',
      'neck',
      'bodyFat',
    ]);
    expect(MeasurementKind.values.map((k) => k.code).toSet().length, 8);
    for (final kind in MeasurementKind.values) {
      expect(MeasurementKind.fromCode(kind.code), kind);
      expect(kind.isLength, kind != MeasurementKind.bodyFat);
    }
    expect(MeasurementKind.custom.isLength, isTrue);
    expect(MeasurementKind.fromCode('Waist'), isNull);
    for (final unit in MeasurementUnit.values) {
      expect(MeasurementUnit.fromCode(unit.code), unit);
    }
    expect(MeasurementUnit.fromCode('inch'), isNull);
    expect(MeasurementUnit.ofLength(LengthUnit.inch), MeasurementUnit.inch);
    expect(MeasurementUnit.ofLength(LengthUnit.centimeter), MeasurementUnit.cm);

    // Refs and keys.
    final custom = MeasurementTypeRef.custom(typeA);
    expect(custom.kind, MeasurementKind.custom);
    expect(custom.key, 'custom-$typeA');
    expect(MeasurementTypeRef.parse(custom.key), custom);
    expect(waist.key, 'waist');
    expect(MeasurementTypeRef.parse('waist'), waist);
    expect(MeasurementTypeRef.parse('bodyFat')!.kind, MeasurementKind.bodyFat);
    for (final bad in ['custom', 'custom-x', 'Waist', '', 'custom-${typeA}x']) {
      expect(MeasurementTypeRef.parse(bad), isNull, reason: bad);
    }
    expect(
      () => MeasurementTypeRef.builtIn(MeasurementKind.custom),
      throwsArgumentError,
    );
    expect(() => MeasurementTypeRef.custom('A'), throwsArgumentError);
    expect(waist, MeasurementTypeRef(kind: MeasurementKind.waist));
    expect(
      waist.hashCode,
      MeasurementTypeRef.builtIn(MeasurementKind.waist).hashCode,
    );
    expect(waist == custom, isFalse);
    expect(waist.isConsistent, isTrue);
    expect(custom.isConsistent, isTrue);
    expect(
      MeasurementTypeRef(kind: MeasurementKind.custom).isConsistent,
      isFalse,
    );
    expect(
      MeasurementTypeRef(
        kind: MeasurementKind.waist,
        customTypeId: typeA,
      ).isConsistent,
      isFalse,
    );
    expect(MeasurementTypeRef(kind: MeasurementKind.custom).key, 'custom');

    // A stored custom type.
    final type = MeasurementType(id: typeA, version: 2, name: 'Left arm');
    expect(type.ref, custom);
    expect(type.versionedId, VersionedId(typeA, 2));
    expect(type, MeasurementType(id: typeA, version: 2, name: 'Left arm'));
    expect(
      type.hashCode,
      MeasurementType(id: typeA, version: 2, name: 'Left arm').hashCode,
    );
    expect(
      type == MeasurementType(id: typeA, version: 2, name: 'Arm'),
      isFalse,
    );
    expect(
      () => MeasurementType(id: 'A', version: 1, name: 'x'),
      throwsArgumentError,
    );
    expect(
      () => MeasurementType(id: typeA, version: 0, name: 'x'),
      throwsArgumentError,
    );
  });

  test('WB-040 a length typed in inches is stored in cm, rounded once, and '
      'shown back as typed', () {
    const input = MeasurementInput(36.5, MeasurementUnit.inch);
    expect(input.canonical, 92.71);
    final stored = measuredOn(day0, 36.5, unit: MeasurementUnit.inch);
    expect(stored.value, 92.71);
    expect(stored.input, input);
    expect(stored.input.value, 36.5);
    expect(stored.draft.input, input);
    expect(stored.draft.value, 92.71);
    expect(stored.draft.localDate, day0);
    expect(stored.versionedId, VersionedId(measurementA, 1));
    expect(const MeasurementInput(92.25, MeasurementUnit.cm).canonical, 92.25);
    expect(
      const MeasurementInput(18.4, MeasurementUnit.percent).canonical,
      18.4,
    );
    expect(input, const MeasurementInput(36.5, MeasurementUnit.inch));
    expect(
      input.hashCode,
      const MeasurementInput(36.5, MeasurementUnit.inch).hashCode,
    );
    expect(input == const MeasurementInput(36.5, MeasurementUnit.cm), isFalse);
    // Range hints with one decimal, inside the bounds.
    expect(MeasurementBounds.minIn(MeasurementUnit.cm), 10);
    expect(MeasurementBounds.maxIn(MeasurementUnit.cm), 300);
    expect(MeasurementBounds.minIn(MeasurementUnit.inch), 4);
    expect(MeasurementBounds.maxIn(MeasurementUnit.inch), 118.1);
    expect(MeasurementBounds.minIn(MeasurementUnit.percent), 2);
    expect(MeasurementBounds.maxIn(MeasurementUnit.percent), 75);
    // Equality of stored rows.
    expect(stored, measuredOn(day0, 36.5, unit: MeasurementUnit.inch));
    expect(
      stored.hashCode,
      measuredOn(day0, 36.5, unit: MeasurementUnit.inch).hashCode,
    );
    expect(stored == measuredOn(day0, 36.5), isFalse);
    expect(
      stored == measuredOn(day0, 36.5, unit: MeasurementUnit.inch, version: 2),
      isFalse,
    );
    expect(() => measuredOn(day0, 90, id: 'A'), throwsArgumentError);
    expect(() => measuredOn(day0, 90, version: 0), throwsArgumentError);
  });

  test('WB-040 MeasurementDraft rejects lengths outside 10–300 cm, body fat '
      'outside 2–75 %, non-finite values, percent on a length, cm on body '
      'fat, a custom kind without a type and a time before 1970', () {
    final bodyFat = MeasurementTypeRef.builtIn(MeasurementKind.bodyFat);
    MeasurementIssue? issue(
      double value, {
      MeasurementTypeRef? type,
      MeasurementUnit unit = MeasurementUnit.cm,
    }) => measureOn(day0, value, type: type, unit: unit).validate();

    expect(issue(10), isNull);
    expect(issue(300), isNull);
    expect(issue(9.99), MeasurementIssue.outOfRange);
    expect(issue(300.01), MeasurementIssue.outOfRange);
    expect(issue(4, unit: MeasurementUnit.inch), isNull); // 10.16 cm
    expect(issue(3.9, unit: MeasurementUnit.inch), MeasurementIssue.outOfRange);
    expect(issue(118.1, unit: MeasurementUnit.inch), isNull);
    expect(
      issue(118.2, unit: MeasurementUnit.inch),
      MeasurementIssue.outOfRange,
    );
    expect(issue(double.nan), MeasurementIssue.outOfRange);
    expect(issue(double.infinity), MeasurementIssue.outOfRange);
    expect(issue(1e300), MeasurementIssue.outOfRange);
    expect(issue(-50), MeasurementIssue.outOfRange);
    expect(issue(2, type: bodyFat, unit: MeasurementUnit.percent), isNull);
    expect(issue(75, type: bodyFat, unit: MeasurementUnit.percent), isNull);
    expect(
      issue(1.99, type: bodyFat, unit: MeasurementUnit.percent),
      MeasurementIssue.outOfRange,
    );
    expect(
      issue(75.01, type: bodyFat, unit: MeasurementUnit.percent),
      MeasurementIssue.outOfRange,
    );
    expect(issue(20, unit: MeasurementUnit.percent), MeasurementIssue.unit);
    expect(issue(20, type: bodyFat), MeasurementIssue.unit);
    expect(
      issue(20, type: bodyFat, unit: MeasurementUnit.inch),
      MeasurementIssue.unit,
    );
    expect(
      issue(80, type: MeasurementTypeRef(kind: MeasurementKind.custom)),
      MeasurementIssue.customWithoutType,
    );
    expect(
      issue(
        80,
        type: MeasurementTypeRef(
          kind: MeasurementKind.arm,
          customTypeId: typeA,
        ),
      ),
      MeasurementIssue.customWithoutType,
    );
    expect(issue(80, type: MeasurementTypeRef.custom(typeA)), isNull);
    expect(
      issue(
        20,
        type: MeasurementTypeRef.custom(typeA),
        unit: MeasurementUnit.percent,
      ),
      MeasurementIssue.unit,
    );
    final old = MeasurementDraft(
      type: waist,
      time: EntryTime(DateTime.utc(1969, 12, 31, 23, 59), 0),
      input: const MeasurementInput(90, MeasurementUnit.cm),
    );
    expect(old.validate(), MeasurementIssue.time);
    final epoch = MeasurementDraft(
      type: waist,
      time: EntryTime(DateTime.utc(1970), 0),
      input: const MeasurementInput(90, MeasurementUnit.cm),
    );
    expect(epoch.validate(), isNull);

    // Future: 5 minutes of skew.
    final draft = measureOn(day0, 90);
    final at = draft.time.occurredAtUtc;
    expect(draft.isInFuture(at.subtract(const Duration(minutes: 5))), isFalse);
    expect(
      draft.isInFuture(at.subtract(const Duration(minutes: 5, seconds: 1))),
      isTrue,
    );
    expect(draft, measureOn(day0, 90));
    expect(draft.hashCode, measureOn(day0, 90).hashCode);
    expect(draft == measureOn(day0, 91), isFalse);
    expect(draft == measureOn(day0, 90, hour: 8), isFalse);
    expect(
      draft == measureOn(day0, 90, type: MeasurementTypeRef.custom(typeA)),
      isFalse,
    );
  });

  test('WB-040 custom type names are trimmed, 1–40 characters, no control '
      'characters, ZWJ/RLM allowed, unique ignoring case including non-ASCII '
      'letters', () {
    expect(CustomTypeName.normalize('  Left arm '), 'Left arm');
    expect(CustomTypeName.validate('Left arm'), isNull);
    expect(CustomTypeName.validate('   '), CustomTypeNameIssue.empty);
    expect(CustomTypeName.validate(''), CustomTypeNameIssue.empty);
    expect(CustomTypeName.validate('a' * 40), isNull);
    expect(CustomTypeName.validate(' ${'a' * 40} '), isNull);
    expect(CustomTypeName.validate('a' * 41), CustomTypeNameIssue.tooLong);
    // 40 emoji are 80 UTF-16 units but 40 code points.
    expect(CustomTypeName.validate('💪' * 40), isNull);
    expect(CustomTypeName.validate('Arm\u0007'), CustomTypeNameIssue.invalid);
    expect(CustomTypeName.validate('Arm\nleft'), CustomTypeNameIssue.invalid);
    expect(CustomTypeName.validate('ذراع‏ left'), isNull); // RLM
    expect(CustomTypeName.validate('💪‍🔥'), isNull); // ZWJ
    expect(CustomTypeName.same('Left Arm', ' left arm '), isTrue);
    expect(CustomTypeName.same('ÄRM', 'ärm'), isTrue);
    expect(CustomTypeName.same('Ωmega', 'ωmega'), isTrue);
    expect(CustomTypeName.same('ذراع', 'ذراع'), isTrue);
    expect(CustomTypeName.same('Left arm', 'Right arm'), isFalse);
    expect(CustomTypeName.compareKey(' Left ARM '), 'left arm');
  });

  test('measurement types, drafts and ops toString show no values or '
      'names', () {
    const secret = 'Secret 92.71';
    final custom = MeasurementTypeRef.custom(typeA);
    final draft = measureOn(day0, 92.71, type: custom);
    final strings = [
      custom.toString(),
      waist.toString(),
      const MeasurementInput(92.71, MeasurementUnit.cm).toString(),
      draft.toString(),
      measuredOn(day0, 92.71).toString(),
      MeasurementType(id: typeA, version: 1, name: secret).toString(),
      CreateMeasurement(measurementA, draft).toString(),
      UpdateMeasurement(measurementA, 1, draft).toString(),
      DeleteMeasurement(VersionedId(measurementA, 1)).toString(),
      CreateMeasurementType(typeA, secret).toString(),
      RenameMeasurementType(typeA, 1, secret).toString(),
      DeleteMeasurementType(VersionedId(typeA, 1), [
        VersionedId(measurementA, 1),
      ]).toString(),
      MeasurementSeries.of([measuredOn(day0, 92.71)]).toString(),
      MeasurementTrendPoint(
        localDate: day0,
        measurementId: measurementA,
        trend: 92.71,
      ).toString(),
    ];
    for (final text in strings) {
      expect(text, isNot(contains('92')), reason: text);
      expect(text, isNot(contains('Secret')), reason: text);
    }
  });
}
