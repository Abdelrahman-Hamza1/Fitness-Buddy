import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/body/data/weigh_in_mappers.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart'
    show chartOrdered;
import 'package:flutter_test/flutter_test.dart';

import '../support/weigh_in_harness.dart';

void main() {
  test('watchLive emits live weigh-ins ordered by date, time and id, and '
      'updates after an apply', () async {
    final h = WeighInHarness();
    final emissions = <List<String>>[];
    final sub = h.repository.watchLive().listen((list) {
      emissions.add([for (final w in list) w.id]);
    });
    addTearDown(sub.cancel);
    Future<List<String>> next(int count) async {
      for (var i = 0; i < 100 && emissions.length < count; i++) {
        await pumpEventQueue();
      }
      return emissions.last;
    }

    expect(await next(1), <String>[]);

    // Inserted out of order: day, then time, then ID decide.
    await h.apply([
      CreateWeighIn(fixtureId(5), weighInDraft(97, hour: 9)),
      CreateWeighIn(fixtureId(4), weighInDraft(97.1, hour: 9)),
      CreateWeighIn(fixtureId(3), weighInDraft(97.2, hour: 6)),
      CreateWeighIn(
        fixtureId(2),
        weighInDraft(97.5, date: day17.plusDays(-1), hour: 20),
      ),
      CreateWeighIn(fixtureId(1), weighInDraft(97.4, date: day17)),
    ]);
    expect(await next(2), [
      fixtureId(2),
      fixtureId(3),
      fixtureId(1),
      fixtureId(4),
      fixtureId(5),
    ]);

    // A tombstone leaves the list.
    await h.apply([DeleteWeighIn(VersionedId(fixtureId(3), 1))]);
    expect(await next(3), [
      fixtureId(2),
      fixtureId(1),
      fixtureId(4),
      fixtureId(5),
    ]);
  });

  test('unreadable synced rows are left out of the list: a malformed date, '
      'or a kg or typed value outside the read bound', () async {
    final h = WeighInHarness();
    await h.seed([weighInDraft(97, note: 'n')]);
    WeighInsCompanion synced(
      int n, {
      String date = '2026-10-17',
      double kg = 80,
      double input = 80,
    }) => WeighInsCompanion(
      id: Value(fixtureId(n)),
      measuredAtUtc: const Value(0),
      tzOffsetMin: const Value(0),
      localDate: Value(date),
      kg: Value(kg),
      inputValue: Value(input),
      inputUnit: const Value('kg'),
    );
    await h.apply([
      ScriptOp.rows([
        InsertRow(h.db.weighIns, synced(2, date: 'not a date')),
        InsertRow(h.db.weighIns, synced(3, kg: 1e306)),
        InsertRow(h.db.weighIns, synced(4, kg: 0)),
        InsertRow(h.db.weighIns, synced(5, input: 1e306)),
      ]),
    ]);
    expect([for (final w in await h.live()) w.id], [fixtureId(1)]);
    for (final n in [2, 3, 4, 5]) {
      final row = await h.row(n);
      expect(
        () => weighInOf(row),
        throwsA(isA<WeighInMappingError>()),
        reason: 'row $n',
      );
    }
    expect(const WeighInMappingError().toString(), 'WeighInMappingError');
  });

  test('a synced weigh-in whose wall clock is outside the years 1–9999 is '
      'left out, and the graph orders the rest (A15b review M1)', () async {
    final h = WeighInHarness();
    await h.seed([weighInDraft(97)]);
    await h.apply([
      ScriptOp.rows([
        InsertRow(
          h.db.weighIns,
          WeighInsCompanion(
            id: Value(fixtureId(2)),
            measuredAtUtc: const Value(253402300800000),
            tzOffsetMin: const Value(840),
            localDate: const Value('2026-10-17'),
            kg: const Value(80),
            inputValue: const Value(80),
            inputUnit: const Value('kg'),
          ),
        ),
      ]),
    ]);
    final live = await h.live();
    expect([for (final w in live) w.id], [fixtureId(1)]);
    expect(chartOrdered(live), hasLength(1));
    final bad = await h.row(2);
    expect(() => weighInOf(bad), throwsA(isA<WeighInMappingError>()));
  });
}
