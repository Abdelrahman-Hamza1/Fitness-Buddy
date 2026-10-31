import 'package:fb_sync/testing.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  // covers: AC-010, AC-011, AC-012, OF-03
  test(
    '1000 randomized multi-device runs converge with no silent loss',
    () async {
      for (var seed = 0; seed < 1000; seed++) {
        final server = FakeSyncServer(SimClock(base));
        await runScenario(
          server,
          seed,
          base,
          history: () async => server.historyVersions,
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  // covers: OF-03
  test(
    'OF-03: the later offline edit wins, the other is an earlier version',
    () async {
      for (final first in [true, false]) {
        await runOf03(
          FakeSyncServer(SimClock(base)),
          base,
          4242,
          firstSyncsFirst: first,
        );
      }
    },
  );

  test(
    'drops, lost acknowledgements, crashes and concurrent edits lose nothing',
    () async {
      final server = FakeSyncServer(SimClock(base));
      await runFaults(server, base, faulty: FaultyTransport(server));
    },
  );
}
