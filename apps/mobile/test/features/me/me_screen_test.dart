import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../onboarding/setup_support.dart';
import '../settings/presentation/settings_support.dart';

Finder _header(String title) => find.widgetWithText(FbSectionHeader, title);

void main() {
  testWidgets('UX-060 UX-010 Me shows "Set up profile & targets" under You, '
      'first, until setup has run; the row opens setup', (tester) async {
    final c = await pumpAt(tester);
    await openMe(tester);
    expect(
      tester.getTopLeft(_header('You')).dy,
      lessThan(tester.getTopLeft(_header('Food')).dy),
    );
    await tester.tap(find.text('Set up profile & targets'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupScreen), findsOneWidget);

    final run = SetupRun(tester);
    await run.toTargets();
    await run.next('Save');
    await settleWrites(tester);
    await openMe(tester);
    // A13c adds Profile & goal and Targets; until then You has no rows.
    expect(find.text('Set up profile & targets'), findsNothing);
    expect(_header('You'), findsNothing);
    await unmountApp(tester, c);
  });

  testWidgets('A13a security #3 Me offers "Update the app" for a profile '
      "this version can't read", (tester) async {
    final c = await pumpAt(
      tester,
      overrides: [
        setupStatusProvider.overrideWith(
          (ref) async => SetupStatus.profileUnreadable,
        ),
      ],
    );
    await openMe(tester);
    expect(find.text('Set up profile & targets'), findsNothing);
    await tester.tap(find.widgetWithText(FbListRow, 'Update the app'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.text('Step 1 of 5'), findsNothing);
    await unmountApp(tester, c);
  });
}
