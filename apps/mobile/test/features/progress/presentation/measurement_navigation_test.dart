import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';
import '../../body/support/weigh_in_harness.dart' show fixtureId;

void main() {
  testWidgets("UX-013 the Progress tab's Measurements row opens the list; a "
      'type row opens its graph; Back returns', (tester) async {
    final container = await pumpApp(tester);
    final router = container.read(appRouterProvider);
    // One waist entry (the app's real clock: now, never in the future).
    final now = EntryTime.now(container.read(clockProvider));
    await tester.runAsync(
      () => container
          .read(changeSetApplierProvider)
          .apply(
            ChangeSet([
              CreateMeasurement(
                fixtureId(1),
                MeasurementDraft(
                  type: MeasurementTypeRef.builtIn(MeasurementKind.waist),
                  time: now,
                  input: const MeasurementInput(92, MeasurementUnit.cm),
                ),
              ),
            ], origin: Origin.direct),
          ),
    );
    await settleWrites(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Progress'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Measurements'));
    await tester.pumpAndSettle();
    expect(find.byType(MeasurementsScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(router.config.state.matchedLocation, '/progress/measurements');

    await tester.tap(find.text('Waist'));
    await tester.pumpAndSettle();
    expect(find.byType(MeasurementTypeScreen), findsOneWidget);
    expect(router.config.state.matchedLocation, '/progress/measurements/waist');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(MeasurementTypeScreen), findsNothing);
    expect(find.byType(MeasurementsScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ProgressScreen), findsOneWidget);
    await unmountApp(tester, container);
  });
}
