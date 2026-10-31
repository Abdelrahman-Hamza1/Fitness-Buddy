import 'package:fb_sync/testing.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('MemorySyncStore meets the store contract:', () {
    for (final MapEntry(key: name, value: check)
        in storeContractChecks.entries) {
      test(name, () => check(MemoryHarness()));
    }
  });
}
