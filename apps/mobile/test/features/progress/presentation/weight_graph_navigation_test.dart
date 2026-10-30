import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';
import '../../body/support/weigh_in_harness.dart' show fixtureId;

void main() {
  testWidgets('UX-013 the Progress tab Weight row opens the weight graph, and '
      'Back returns to Progress', (tester) async {
    final container = await pumpApp(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Progress'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weight graph'));
    await tester.pumpAndSettle();
    expect(find.byType(WeightGraphScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WeightGraphScreen), findsNothing);
    expect(find.byType(ProgressScreen), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets("HM-005 the weight card's graph row opens the weight graph, and "
      'Back returns to Today', (tester) async {
    final container = await pumpApp(tester);
    // The app's real clock: a weigh-in now, so never in the future.
    final now = EntryTime.now(container.read(clockProvider));
    final today = now.localDate;
    await tester.runAsync(
      () => container
          .read(changeSetApplierProvider)
          .apply(
            ChangeSet([
              CreateWeighIn(
                fixtureId(1),
                WeighInDraft(
                  time: now,
                  input: const WeighInInput(97.4, MassUnit.kilogram),
                ),
              ),
            ], origin: Origin.direct),
          ),
    );
    await settleWrites(tester);

    final row = find
        .descendant(
          of: find.byKey(ValueKey<LocalDate>(today)),
          matching: find.descendant(
            of: find.byType(WeightCard),
            matching: find.text('Weight graph'),
          ),
        )
        .first;
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(WeightGraphScreen), findsOneWidget);
    expect(
      container.read(appRouterProvider).config.state.matchedLocation,
      TodayWeightGraphRoute.path,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WeightGraphScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets("UX-013 weight history opens outside the tabs from the graph's "
      'action and its empty state; Back returns to the graph', (tester) async {
    final container = await pumpApp(tester);
    final router = container.read(appRouterProvider);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Progress'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weight graph'));
    await tester.pumpAndSettle();

    // The empty state's secondary action.
    await tester.tap(find.widgetWithText(FbButton, 'Add past weigh-ins'));
    await tester.pumpAndSettle();
    expect(find.byType(WeightHistoryScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(router.config.state.matchedLocation, WeightHistoryRoute.path);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WeightHistoryScreen), findsNothing);
    expect(find.byType(WeightGraphScreen), findsOneWidget);

    // The AppBar action; one row saved shows on the graph.
    await tester.tap(find.byTooltip('Add past weigh-ins'));
    await tester.pumpAndSettle();
    expect(find.byType(WeightHistoryScreen), findsOneWidget);
    await tester.tap(find.text('Pick a date'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('1')),
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '97.4');
    await tester.pump();
    await tester.tap(find.widgetWithText(FbButton, 'Save'));
    await settleWrites(tester);
    expect(find.byType(WeightHistoryScreen), findsNothing);
    expect(find.byType(WeightGraphScreen), findsOneWidget);
    expect(find.byType(FbTimeSeriesChart), findsOneWidget);
    expect(find.text('1 weigh-in added'), findsOneWidget);
    await unmountApp(tester, container);
  });
}
