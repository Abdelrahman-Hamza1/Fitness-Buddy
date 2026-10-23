@Tags(['perf'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';
import '../support/day_view_benchmark.dart';

void main() {
  test('DY-020 A08 perf P1 P2 P3 provider path: file WAL background '
      'isolate', () async {
    final result = await runDayViewBenchmark(
      backgroundDatabase(tempDir().path),
    );
    debugPrint(
      'A08 perf P1 cold p95 ${result.coldP95.toStringAsFixed(2)} ms '
      '(200 runs, 20 warm-ups); '
      'P2 write-visible p95 ${result.writeP95.toStringAsFixed(2)} ms '
      '(100 runs); '
      'P3 settled ${result.settleMs.toStringAsFixed(2)} ms; '
      'max concurrent reads/day ${result.maxReads}',
    );
    expect(result.coldP95, lessThan(10));
    expect(result.writeP95, lessThan(25));
    expect(result.settleMs, lessThan(150));
    expect(result.maxReads, 1);
  });
}
