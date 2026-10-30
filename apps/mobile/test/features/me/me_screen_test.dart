import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../settings/presentation/settings_support.dart';

void main() {
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
