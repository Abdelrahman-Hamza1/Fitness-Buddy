import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/body/data/measurement_mappers.dart';
import 'package:fb_mobile/features/progress/application/measurement_graph_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/measurement_harness.dart';

/// A raw synced measurement row (the sync path never goes through the
/// handler).
MeasurementsCompanion _synced(
  String id, {
  int measuredAtUtc = 1792310400000,
  String kind = 'waist',
  String? typeId,
  String unit = 'cm',
  double value = 90,
  double? input,
  String date = '2026-10-17',
}) => MeasurementsCompanion(
  id: Value(id),
  kind: Value(kind),
  customTypeId: Value(typeId),
  measuredAtUtc: Value(measuredAtUtc),
  tzOffsetMin: const Value(180),
  localDate: Value(date),
  value: Value(value),
  inputValue: Value(input ?? value),
  inputUnit: Value(unit),
);

MeasurementRow _row({
  String kind = 'waist',
  String? typeId,
  String unit = 'cm',
  double value = 90,
  double input = 90,
  String date = '2026-10-17',
  String id = '0199e3c2-5b1a-7c3d-8e4f-000000000001',
}) => MeasurementRow(
  id: id,
  createdAt: 0,
  updatedHlc: 'h',
  version: 1,
  deviceId: 'd',
  origin: 'direct',
  editedByUser: false,
  kind: kind,
  customTypeId: typeId,
  measuredAtUtc: 0,
  tzOffsetMin: 0,
  localDate: date,
  value: value,
  inputValue: input,
  inputUnit: unit,
);

void main() {
  test("watchMeasurements emits a type's live rows by date, time and id; a "
      'measurement of a missing or deleted type is hidden', () async {
    final h = MeasurementHarness();
    final emissions = <List<String>>[];
    final sub = h.repository.watch().listen(
      (data) => emissions.add([for (final m in data.measurements) m.id]),
    );
    addTearDown(sub.cancel);
    Future<List<String>> next(int count) async {
      for (var i = 0; i < 100 && emissions.length < count; i++) {
        await pumpEventQueue();
      }
      return emissions.last;
    }

    expect(await next(1), <String>[]);
    await h.apply([
      CreateMeasurementType(tId(1), 'Calf'),
      CreateMeasurement(mId(5), measureDraft(92, hour: 9)),
      CreateMeasurement(mId(4), measureDraft(92.1, hour: 9)),
      CreateMeasurement(mId(3), measureDraft(92.2, hour: 6)),
      CreateMeasurement(
        mId(2),
        measureDraft(92.5, date: measureDay.plusDays(-1), hour: 20),
      ),
      CreateMeasurement(
        mId(1),
        measureDraft(40, type: MeasurementTypeRef.custom(tId(1))),
      ),
    ]);
    expect(await next(2), [mId(2), mId(3), mId(1), mId(4), mId(5)]);
    final data = await h.live();
    expect(data.types.single.name, 'Calf');
    expect(
      data.measurements.where((m) => m.type == waistRef).map((m) => m.id),
      [mId(2), mId(3), mId(4), mId(5)],
    );

    // A synced measurement of a type that doesn't exist is hidden.
    await h.apply([
      ScriptOp.rows([
        InsertRow(
          h.db.measurements,
          _synced(mId(6), kind: 'custom', typeId: tId(7)),
        ),
      ]),
    ]);
    expect(await next(3), [mId(2), mId(3), mId(1), mId(4), mId(5)]);

    // Types sort by name ignoring case, then ID; same names are both shown.
    await h.apply([
      CreateMeasurementType(tId(2), 'arm L'),
      ScriptOp.rows([
        InsertRow(
          h.db.measurementTypes,
          MeasurementTypesCompanion(
            id: Value(tId(3)),
            name: const Value('CALF'),
          ),
        ),
      ]),
    ]);
    expect(
      [for (final t in (await h.live()).types) t.id],
      [tId(2), tId(1), tId(3)],
    );
  });

  test('tolerant read: an unknown kind, an M1/M2/M3 mismatch, a non-finite or '
      'zero value or an empty name skips the row and counts it; nothing '
      'logged', () async {
    // Rows the CHECKs keep out of the table, through the mapper.
    for (final row in [
      _row(kind: 'calf'),
      _row(unit: 'mm'),
      _row(value: double.nan),
      _row(value: double.infinity),
      _row(input: 10000000),
      _row(date: 'yesterday'),
      _row(kind: 'custom', typeId: 'not-a-uuid'),
    ]) {
      expect(
        () => measurementOf(row),
        throwsA(
          isA<MeasurementMappingError>().having(
            (e) => e.toString(),
            'toString',
            'MeasurementMappingError',
          ),
        ),
      );
    }
    expect(measurementOf(_row()).value, 90);

    // Rows the CHECKs allow, through the repository.
    final h = MeasurementHarness();
    await h.apply([
      CreateMeasurement(mId(1), measureDraft(92)),
      ScriptOp.rows([
        // M1: custom without a type, a built-in with one.
        InsertRow(h.db.measurements, _synced(mId(2), kind: 'custom')),
        InsertRow(h.db.measurements, _synced(mId(3), typeId: tId(1))),
        // M2: percent on a length, cm on body fat.
        InsertRow(h.db.measurements, _synced(mId(4), unit: 'percent')),
        InsertRow(h.db.measurements, _synced(mId(5), kind: 'bodyFat')),
        // M3: body fat above 100 %.
        InsertRow(
          h.db.measurements,
          _synced(mId(6), kind: 'bodyFat', unit: 'percent', value: 101),
        ),
        // A zero value.
        InsertRow(h.db.measurements, _synced(mId(7), value: 0)),
        // An empty name.
        InsertRow(
          h.db.measurementTypes,
          MeasurementTypesCompanion(id: Value(tId(2)), name: const Value('  ')),
        ),
      ]),
    ]);
    final data = await h.live();
    expect([for (final m in data.measurements) m.id], [mId(1)]);
    expect(data.types, isEmpty);
    expect(data.skipped, 7);
    expect(
      data.toString(),
      'MeasurementData(0 types, 1 measurements, 7 skipped)',
    );
  });

  test('D25 a measurement that arrives before its custom type is hidden '
      'until the type arrives; a tombstoned type hides its '
      'measurements', () async {
    final h = MeasurementHarness();
    await h.apply([
      ScriptOp.rows([
        InsertRow(
          h.db.measurements,
          _synced(mId(1), kind: 'custom', typeId: tId(1), value: 40),
        ),
      ]),
    ]);
    expect((await h.live()).measurements, isEmpty);
    expect((await h.live()).skipped, 0);
    await h.apply([
      ScriptOp.rows([
        InsertRow(
          h.db.measurementTypes,
          MeasurementTypesCompanion(
            id: Value(tId(1)),
            name: const Value('Calf'),
          ),
        ),
      ]),
    ]);
    expect([for (final m in (await h.live()).measurements) m.id], [mId(1)]);
    await h.apply([
      ScriptOp.rows([TombstoneRow(h.db.measurementTypes, tId(1))]),
    ]);
    final data = await h.live();
    expect(data.types, isEmpty);
    expect(data.measurements, isEmpty);
  });

  test('a synced measurement whose wall clock is outside the years 1–9999 '
      'is skipped and counted, and the graph reads the rest (A15b review '
      'M1)', () async {
    final h = MeasurementHarness();
    await h.apply([
      CreateMeasurement(mId(1), measureDraft(92)),
      ScriptOp.rows([
        // 10000-01-01T00:00Z: inside the wire's integer bound.
        InsertRow(
          h.db.measurements,
          _synced(mId(2), measuredAtUtc: 253402300800000),
        ),
        InsertRow(
          h.db.measurements,
          _synced(mId(3), measuredAtUtc: 9007199254740991),
        ),
      ]),
    ]);
    final data = await h.live();
    expect([for (final m in data.measurements) m.id], [mId(1)]);
    expect(data.skipped, 2);
    final ordered = measurementChartOrdered(data.measurements);
    expect(ordered.map(measurementChartTime), hasLength(1));
    expect(MeasurementSeries.of(data.measurements).points, hasLength(1));
  });
}
