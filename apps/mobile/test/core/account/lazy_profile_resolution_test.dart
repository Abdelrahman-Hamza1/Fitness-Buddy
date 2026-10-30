import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_phone.dart';

void main() {
  test(
    'UX-001 A33 building the database, applier, gate and account '
    'providers reads no profile registry; the first database open does',
    () async {
      final phone = TestPhone();
      final container = ProviderContainer(overrides: phone.overrides());
      addTearDown(container.dispose);

      // Everything the first frame can build: no storage read.
      container
        ..read(databaseLocationProvider)
        ..read(appDatabaseProvider)
        ..read(changeSetApplierProvider)
        ..read(accountWriteGateProvider)
        ..read(accountServiceProvider);
      const registryReads = 'prefs get ${ProfileRegistry.storageKey}';
      expect(phone.events, isNot(contains(registryReads)));

      // The lazy resolution (when the database first opens) reads it once.
      expect(
        await container.read(databaseLocationProvider).resolvedProfileKey(),
        ProfileRegistry.guestKey,
      );
      expect(phone.events.where((e) => e == registryReads), hasLength(1));
    },
  );
}
