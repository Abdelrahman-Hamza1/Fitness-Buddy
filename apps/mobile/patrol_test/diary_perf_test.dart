import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/connection.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol/patrol.dart';

import '../test/features/diary/support/diary_benchmark.dart';

/// The A06 day-query benchmark on the device (A06 §5, exit criterion "a day
/// query with 30 entries < 5 ms on the A55"), run by `make test-it` on the
/// phone. The same body as the host test
/// (`test/features/diary/data/diary_perf_test.dart`): a file database in WAL
/// through the background isolate, in the app's cache directory, deleted
/// afterwards. Prints median and p95 (numbers only); the budget is checked
/// by reading them, not asserted.
void main() {
  patrolTest(
    'A06 perf: a day query with 30 entries in a 5,500-entry year on the '
    'device: median and p95 over 200 runs after 20 warm-ups',
    ($) async {
      // createTemp: a nested path that doesn't exist fails on Android.
      final cache = await getTemporaryDirectory();
      final root = await cache.createTemp('fb_diary_perf');
      addTearDown(() => root.deleteSync(recursive: true));
      final location = DatabaseLocation(
        profileKey: 'perf',
        root: () async => root.path,
        temporary: () async => root.path,
      );
      final db = AppDatabase(openUserDatabase(location));
      addTearDown(db.close);
      final result = await runDiaryBenchmark(db);
      debugPrint(result.summary('device'));
      expect(result.micros, hasLength(200));
    },
  );
}
