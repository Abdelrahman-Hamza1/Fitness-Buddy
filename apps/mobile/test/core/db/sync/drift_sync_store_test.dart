import 'package:fb_sync/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_support.dart';

void main() {
  // covers: AC-010, AC-012
  group('DriftSyncStore meets the store contract:', () {
    for (final MapEntry(key: name, value: check)
        in storeContractChecks.entries) {
      test(name, () => check(DriftHarness()));
    }
  });
}
