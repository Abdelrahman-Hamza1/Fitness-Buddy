import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/migrations/from_13_to_14.dart';
import 'package:fb_mobile/core/sync/legacy_target_factors.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

const _device = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _hlc = '1760351234567-00007-$_device';

String _id(int n) => '0199e3c2-5b1a-7c3d-8e4f-${'$n'.padLeft(12, '0')}';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final verifier = SchemaVerifier(GeneratedHelper());

  test('D-090 TD-112 v13→v14 turns shift weights into factors that keep '
      "every day's number, bumps HLC and version, captures the rows, and "
      'leaves rows without weights and tombstones alone', () async {
    final schema = await verifier.schemaAt(13);
    final raw = schema.rawDatabase
      ..execute(
        'INSERT INTO profile (id, created_at, updated_hlc, version, '
        'device_id, origin, edited_by_user, sex, birth_year, height_cm, '
        "height_input_unit, activity) VALUES (?, 1, ?, 1, ?, 'direct', 0, "
        "'male', 1990, 180, 'cm', 'light')",
        [_id(90), _hlc, _device],
      );
    void settings(
      int n, {
      required String mode,
      required double base,
      Map<String, double> shifts = const {},
      bool deleted = false,
    }) {
      const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
      raw.execute(
        'INSERT INTO target_settings (id, created_at, updated_hlc, version, '
        'deleted_at, device_id, origin, edited_by_user, revision, '
        'effective_from, mode, rebalancing, base_kcal, manual, acknowledged, '
        'basis_weight_kg, ${days.map((d) => 'shift_$d').join(', ')}, '
        'protein_value, protein_is_percent, fat_value, fat_is_percent, '
        'carbs_value, carbs_is_percent, fiber_g, calories_protein_only) '
        "VALUES (?, 1, ?, 3, ?, ?, 'direct', 0, 1, '2026-10-01', ?, 1, ?, "
        '0, 0, 80, ${List.filled(7, '?').join(', ')}, '
        'NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0)',
        [
          _id(n),
          _hlc,
          if (deleted) 5 else null,
          _device,
          mode,
          base,
          for (final d in days) shifts[d],
        ],
      );
    }

    settings(1, mode: 'weekly', base: 2500, shifts: {'fri': 1.3});
    settings(2, mode: 'fixed', base: 2500, shifts: {'fri': 1.3});
    settings(3, mode: 'weekly', base: 2500);
    settings(
      4,
      mode: 'weekly',
      base: 2500,
      shifts: {'fri': 1.3},
      deleted: true,
    );
    // Near the floor: Sunday's plain share would fall below it.
    settings(
      5,
      mode: 'weekly',
      base: 2000,
      shifts: {
        for (final d in ['mon', 'tue', 'wed', 'thu', 'fri', 'sat']) d: 1.3,
      },
    );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 14);
    final rows = {
      for (final r in await db.select(db.targetSettingsRows).get()) r.id: r,
    };

    final weekly = rows[_id(1)]!;
    expect(weekly.shiftFri, closeTo(1.3 * 7 / 7.3, 1e-9));
    expect(weekly.shiftMon, closeTo(7 / 7.3, 1e-9));
    expect(weekly.version, 4);
    expect(weekly.updatedHlc, '1760351234567-00008-$_device');

    final fixed = rows[_id(2)]!;
    expect(
      [fixed.shiftMon, fixed.shiftFri, fixed.shiftSun],
      everyElement(isNull),
      reason: 'fixed mode never used the weights',
    );
    expect(fixed.version, 4);

    expect(rows[_id(3)]!.version, 3);
    expect(rows[_id(3)]!.updatedHlc, _hlc);
    expect(rows[_id(4)]!.shiftFri, 1.3, reason: 'tombstone untouched');
    expect(rows[_id(4)]!.version, 3);

    // The floor case: the numbers stay above the floor and sum to the week.
    final near = rows[_id(5)]!;
    final floor = TargetCalculator.floor(
      const ProfileRecord(
        sex: FormulaSex.male,
        birthYear: 1990,
        heightCm: 180,
        heightInputUnit: HeightInputUnit.centimeter,
        activity: ActivityLevel.light,
      ).toProfile(80),
      LocalDate(2026, 10, 1),
    );
    final base = floor > 2000 ? floor : 2000.0;
    final factors = [
      near.shiftMon,
      near.shiftTue,
      near.shiftWed,
      near.shiftThu,
      near.shiftFri,
      near.shiftSat,
      near.shiftSun,
    ].map((f) => f ?? 1.0);
    final planned = [for (final f in factors) f * base];
    expect(planned, everyElement(greaterThanOrEqualTo(floor - 1e-6)));
    expect(planned.fold<double>(0, (a, b) => a + b), closeTo(base * 7, 1e-6));

    // Captured for sync: the rewritten rows only (inserts were captured
    // before the upgrade; drop them).
    final outbox = await db.select(db.syncOutbox).get();
    final rewrites = outbox
        .where((r) => r.hlc.startsWith('1760351234567-00008'))
        .map((r) => r.rowId)
        .toSet();
    expect(rewrites, {_id(1), _id(2), _id(5)});
    // The clock continues after the new HLCs; the factors marker is set.
    final state = {
      for (final r in await db.customSelect('SELECT * FROM sync_state').get())
        r.read<String>('key'): r.read<String>('value'),
    };
    expect(state['hlc.last'], '1760351234567-00008-$_device');
    expect(int.tryParse(state[dayFactorsSinceKey] ?? ''), isNotNull);
    await db.close();
  });

  test('D-090 v13Factors reproduces the old planned days and returns NULL '
      'for the usual ones', () {
    final factors = v13Factors(
      weights: [null, null, null, null, 1.15, null, null],
      baseKcal: 2000,
      fixed: false,
      manualAcknowledged: false,
      floorKcal: 1500,
    );
    expect(factors[4], closeTo(1.15 * 7 / 7.15, 1e-9));
    expect(factors[0], closeTo(7 / 7.15, 1e-9));
    expect(
      v13Factors(
        weights: List<double?>.filled(7, 1),
        baseKcal: 2000,
        fixed: false,
        manualAcknowledged: false,
      ),
      everyElement(isNull),
    );
  });

  test('TD-112 an earlier targetSettings version from before the factors '
      'converts its weights when restored; a later one stays', () {
    final payload = <String, Object?>{
      'baseKcal': 2000.0,
      'mode': 'weekly',
      'manual': false,
      'acknowledged': false,
      'shiftFri': 1.3,
    };
    final old = legacyTargetSettings(payload, wallMs: 10, sinceMs: 20);
    expect(old['shiftFri']! as num, closeTo(1.3 * 7 / 7.3, 1e-9));
    expect(old['shiftMon']! as num, closeTo(7 / 7.3, 1e-9));
    expect(legacyTargetSettings(payload, wallMs: 30, sinceMs: 20), payload);
  });
}
