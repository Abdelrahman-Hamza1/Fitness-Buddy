import 'package:fb_mobile/core/session/auth_transport.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'session_fakes.dart';

void main() {
  testWidgets('AC-002 lifecycle provider pauses the timer for every '
      'non-resumed state; disposal removes observer and late wakeups', (
    tester,
  ) async {
    final f = Fixture();
    f.auth.create = () async =>
        throw const AuthFailure(AuthFailureKind.retryable);
    final container = ProviderContainer.test(
      overrides: [
        secureSessionStoreProvider.overrideWithValue(f.store),
        authTransportProvider.overrideWithValue(f.auth),
        sessionClockProvider.overrideWithValue(f.clock),
      ],
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final lifecycle = container.read(sessionLifecycleProvider)..start();
    await tester.pump();
    expect(f.auth.creates, 1);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      f.clock.advance(const Duration(seconds: 61));
      await tester.pump(const Duration(seconds: 61));
      lifecycle.transportSucceeded();
      expect(f.auth.creates, 1);
    }
    for (var i = 0; i < 10; i++) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      lifecycle.transportSucceeded();
    }
    await tester.pump();
    expect(f.auth.creates, 2);
    final callback = container.read(sessionTransportSucceededProvider);
    container.dispose();
    callback();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    f.clock.advance(const Duration(hours: 1));
    await tester.pump(const Duration(hours: 1));
    expect(f.auth.creates, 2);
    expect(tester.takeException(), isNull);
  });
}
