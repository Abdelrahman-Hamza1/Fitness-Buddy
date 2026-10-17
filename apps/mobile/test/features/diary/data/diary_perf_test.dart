@Tags(['perf'])
library;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';
import '../support/diary_benchmark.dart';

/// The host half of the A06 exit criterion "a day query with 30 entries
/// < 5 ms on the A55" (A06 §5). It prints the median and p95 and asserts
/// only a generous host bound (a regression of several times), so a busy CI
/// runner doesn't fail it; `patrol_test/diary_perf_test.dart` prints the
/// same numbers on the phone.
void main() {
  test('A06 perf: a day query with 30 entries in a 5,500-entry year has a '
      'median under 25 ms (file database, WAL, background isolate)', () async {
    final root = tempDir().path;
    final db = backgroundDatabase(root);
    final result = await runDiaryBenchmark(db);
    debugPrint(result.summary('host'));

    expect(result.micros, hasLength(200));
    expect(result.medianMs, lessThan(25));
  });
}
