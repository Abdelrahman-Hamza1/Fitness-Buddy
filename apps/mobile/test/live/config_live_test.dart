@Tags(['live'])
library;

import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/config/app_version.dart';
import 'package:fb_mobile/core/config/client_config.dart';
import 'package:fb_mobile/core/config/upgrade_signal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_phone.dart';

// Runs only on request, against the local Host (see dart_test.yaml). The
// dev flavor's URL, as on the A55 through `adb reverse`.

void main() {
  test('live: GET /v1/config against the local Host', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final phone = TestPhone(realNetwork: true);
    final app = ProviderContainer.test(overrides: phone.overrides());

    // The generated client, with the app's headers, straight from the API.
    final config = await app.read(fbApiProvider).account.getConfig();
    expect(AppVersion.tryParse(config.minimumAppVersion), isNotNull);

    // The app's own path: refresh, cache, gate.
    expect(await app.read(clientConfigProvider.notifier).refresh(), isTrue);
    expect(app.read(clientConfigProvider), config);
    expect(app.read(upgradeSignalProvider), isFalse);
    // The evidence for the step's progress log (S06 plan WP2).
    // ignore: avoid_print
    print('live /v1/config from ${testConfig.apiBaseUrl}: ${config.toJson()}');
  });
}
