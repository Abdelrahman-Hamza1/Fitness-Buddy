import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/body.dart';
import '../helpers/measurement.dart';

void main() {
  test('WB-040 measurement ops: value equality, uuid and version checks; '
      'DeleteMeasurementType carries its measurements', () {
    final draft = measureOn(day0, 92);
    final a1 = VersionedId(measurementA, 1);
    final b2 = VersionedId(measurementB, 2);
    final t1 = VersionedId(typeA, 1);

    for (final op in <MeasurementOp>[
      CreateMeasurement(measurementA, draft),
      UpdateMeasurement(measurementA, 1, draft),
      DeleteMeasurement(a1),
      CreateMeasurementType(typeA, 'Left arm'),
      RenameMeasurementType(typeA, 1, 'Left arm'),
      DeleteMeasurementType(t1, const []),
    ]) {
      expect(op.family, 'measurement');
      expect(op.family, MeasurementOp.familyName);
    }

    // Create.
    final create = CreateMeasurement(measurementA, draft);
    expect(create, CreateMeasurement(measurementA, measureOn(day0, 92)));
    expect(
      create.hashCode,
      CreateMeasurement(measurementA, measureOn(day0, 92)).hashCode,
    );
    expect(create == CreateMeasurement(measurementB, draft), isFalse);
    expect(
      create == CreateMeasurement(measurementA, measureOn(day0, 93)),
      isFalse,
    );
    expect(create.id, measurementA);
    expect(create.draft, draft);
    expect(() => CreateMeasurement('A', draft), throwsArgumentError);

    // Update.
    final update = UpdateMeasurement(measurementA, 2, draft);
    expect(update, UpdateMeasurement(measurementA, 2, measureOn(day0, 92)));
    expect(update.hashCode, UpdateMeasurement(measurementA, 2, draft).hashCode);
    expect(update == UpdateMeasurement(measurementB, 2, draft), isFalse);
    expect(update == UpdateMeasurement(measurementA, 3, draft), isFalse);
    expect(
      update == UpdateMeasurement(measurementA, 2, measureOn(day0, 93)),
      isFalse,
    );
    expect(update.expectedVersion, 2);
    expect(update.id, measurementA);
    expect(() => UpdateMeasurement('A', 1, draft), throwsArgumentError);
    expect(
      () => UpdateMeasurement(measurementA, 0, draft),
      throwsArgumentError,
    );

    // Delete.
    final delete = DeleteMeasurement(a1);
    expect(delete, DeleteMeasurement(VersionedId(measurementA, 1)));
    expect(
      delete.hashCode,
      DeleteMeasurement(VersionedId(measurementA, 1)).hashCode,
    );
    expect(delete == DeleteMeasurement(b2), isFalse);
    expect(delete.measurement, a1);
    expect(delete.toString(), 'DeleteMeasurement($measurementA@v1)');

    // Types: names are stored trimmed.
    final createType = CreateMeasurementType(typeA, '  Left arm ');
    expect(createType.name, 'Left arm');
    expect(createType, CreateMeasurementType(typeA, 'Left arm'));
    expect(
      createType.hashCode,
      CreateMeasurementType(typeA, 'Left arm').hashCode,
    );
    expect(createType == CreateMeasurementType(typeB, 'Left arm'), isFalse);
    expect(createType == CreateMeasurementType(typeA, 'Right arm'), isFalse);
    expect(createType.id, typeA);
    expect(() => CreateMeasurementType('A', 'x'), throwsArgumentError);

    final rename = RenameMeasurementType(typeA, 2, ' Calf ');
    expect(rename.name, 'Calf');
    expect(rename, RenameMeasurementType(typeA, 2, 'Calf'));
    expect(rename.hashCode, RenameMeasurementType(typeA, 2, 'Calf').hashCode);
    expect(rename == RenameMeasurementType(typeB, 2, 'Calf'), isFalse);
    expect(rename == RenameMeasurementType(typeA, 3, 'Calf'), isFalse);
    expect(rename == RenameMeasurementType(typeA, 2, 'Shin'), isFalse);
    expect(rename.id, typeA);
    expect(rename.expectedVersion, 2);
    expect(() => RenameMeasurementType('A', 1, 'x'), throwsArgumentError);
    expect(() => RenameMeasurementType(typeA, 0, 'x'), throwsArgumentError);

    // Delete type: membership in any order, versions included.
    final deleteType = DeleteMeasurementType(t1, [a1, b2]);
    final reordered = DeleteMeasurementType(t1, [b2, a1]);
    expect(deleteType, reordered);
    expect(deleteType.hashCode, reordered.hashCode);
    expect(deleteType.type, t1);
    expect(deleteType.measurements, [a1, b2]);
    expect(() => deleteType.measurements.add(a1), throwsUnsupportedError);
    for (final other in [
      DeleteMeasurementType(VersionedId(typeA, 2), [a1, b2]),
      DeleteMeasurementType(VersionedId(typeB, 1), [a1, b2]),
      DeleteMeasurementType(t1, [a1]),
      DeleteMeasurementType(t1, [VersionedId(measurementA, 2), b2]),
      DeleteMeasurementType(t1, const []),
    ]) {
      expect(deleteType == other, isFalse, reason: '$other');
    }
    expect(
      () => DeleteMeasurementType(t1, [a1, VersionedId(measurementA, 2)]),
      throwsArgumentError,
    );
    expect(
      deleteType.toString(),
      'DeleteMeasurementType($typeA@v1, 2 measurements)',
    );
  });
}
