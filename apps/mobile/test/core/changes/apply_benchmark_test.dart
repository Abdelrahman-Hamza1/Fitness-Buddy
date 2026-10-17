@Tags(['perf'])
library;

import 'package:fb_mobile/core/db/connection.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

import '../db/support/db_support.dart';
import 'support/apply_benchmark.dart';
import 'support/test_db.dart';

/// The host half of the A01 exit criterion "a 10-op change set applies in
/// < 10 ms on the A55" (A01 §5). It prints the median and p95 and asserts
/// only a generous host bound, so a slow or busy CI runner doesn't fail it:
/// the laptop's median is about 2.5 ms in one batch and about 7 ms with one
/// read per op (A01 WP5), so the bounds (10 and 30 ms) mean something
/// regressed by several times. The real budget is checked on the
/// phone: `patrol_test/db_perf_test.dart` (`make test-it` on the A55) prints
/// the same numbers there.
void main() {
  for (final readsBeforePlan in [false, true]) {
    test('A01 perf: a 10-op change set (10 inserts over 2 tables'
        '${readsBeforePlan ? ', one read per op' : ''}) applies in a median '
        'under ${readsBeforePlan ? 30 : 10} ms (file database, WAL, '
        'background isolate)', () async {
      final root = tempDir().path;
      final db = testDatabase(
        openUserDatabase(CountingLocation(root).location),
      );
      final result = await runApplyBenchmark(
        Harness(db),
        readsBeforePlan: readsBeforePlan,
      );
      debugPrint(result.summary('host'));

      expect(result.runs, 200);
      expect(await db.select(db.testNotes).get(), hasLength(1100));
      expect(result.medianMs, lessThan(readsBeforePlan ? 30 : 10));
    });
  }
}
