import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/design_preview/application/fake_data.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/food_proposal_mockup.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(360, 1000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: FbTheme.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FbLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SingleChildScrollView(child: FoodProposalMockup()),
      ),
    ),
  );
}

void main() {
  testWidgets('AI-033 tapping the assumption chip opens the alternatives', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text(FakeData.proposalAssumption));
    await tester.pumpAndSettle();
    expect(find.text('Change the assumption'), findsOneWidget);
    expect(find.text(FakeData.assumptionAlternatives.last), findsOneWidget);
  });

  testWidgets('AI-034 tapping an answer chip selects it, the default is '
      'labelled', (tester) async {
    await _pump(tester);
    expect(find.text('Default'), findsWidgets);
    await tester.tap(find.text(FakeData.answerOptions.last));
    await tester.pump();
    expect(find.byIcon(FbIcons.check), findsOneWidget);
  });

  testWidgets('AI-032 tapping the ~ marker opens the estimate range', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byType(FbEstimateMarker));
    await tester.pumpAndSettle();
    expect(find.text(FakeData.estimateRange), findsOneWidget);
  });
}
