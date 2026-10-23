import 'package:fb_mobile/core/db/connection.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol/patrol.dart';

import '../test/core/changes/support/apply_benchmark.dart';
import '../test/core/changes/support/test_db.dart';

/// The A01 apply benchmark on the device (A01 §5, exit criterion "10-op
/// change set < 10 ms on the A55"), run by `make test-it` on the phone. The
/// same body as the host test (`test/core/changes/apply_benchmark_test.dart`):
/// a file database in WAL through the background isolate, in the app's
/// cache directory, deleted afterwards. Prints median and p95 (numbers
/// only); the budget is checked by reading them, not asserted, so a slow
/// run reports instead of failing the integration suite.
void main() {
  patrolTest(
    'A01 perf: apply a 10-op change set (10 inserts over 2 tables, without '
    'and with one read per op) on the device: median and p95 over 200 runs '
    'after 20 warm-ups',
    ($) async {
      final cache = await getTemporaryDirectory();
      // Both variants, each on a fresh database: one batch per change set,
      // then one per op.
      for (final readsBeforePlan in [false, true]) {
        final root = await cache.createTemp('fb_perf');
        addTearDown(() => root.deleteSync(recursive: true));
        final location = DatabaseLocation(
          profileKey: 'perf',
          root: () async => root.path,
          temporary: () async => root.path,
        );
        final db = testDatabase(openUserDatabase(location));
        final result = await runApplyBenchmark(
          Harness(db),
          readsBeforePlan: readsBeforePlan,
        );
        debugPrint(result.summary('device'));
        expect(result.runs, 200);
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
