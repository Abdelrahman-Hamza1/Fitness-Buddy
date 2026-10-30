import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../today/presentation/support/today_support.dart' show phoneApp;

void main() {
  testWidgets('AC-003 while a transition switches profiles the app shows a '
      'calm blocking state and nothing underneath can be opened', (
    tester,
  ) async {
    var opened = 0;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: phoneApp(
          AccountBusyScope(
            child: Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => opened++,
                  child: const Text('Log weight'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Updating your account…'), findsNothing);

    container.read(accountBusyProvider.notifier).publish(busy: true);
    await tester.pump();
    expect(find.text('Updating your account…'), findsOneWidget);
    await tester.tap(find.text('Log weight'), warnIfMissed: false);
    expect(opened, 0);

    container.read(accountBusyProvider.notifier).publish(busy: false);
    await tester.pump();
    await tester.tap(find.text('Log weight'));
    expect(opened, 1);
  });
}
