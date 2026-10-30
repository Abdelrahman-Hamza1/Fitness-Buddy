import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/adaptive/adaptive.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../progress/support/progress_support.dart';
import '../today/presentation/support/today_support.dart' show phoneApp;

const String _id = '0199e3c2-5b1a-7000-8000-00000000c001';

ProposalRecord _record() => ProposalRecord(
  id: _id,
  version: 1,
  createdAt: DateTime.utc(2026, 11, 9),
  kind: targetChangeKind,
  status: ProposalStatus.pending,
  codecVersion: 1,
  draftJson: _draft.toJson(),
);

final TargetChangeDraft _draft = TargetChangeDraft(
  weekStart: LocalDate(2026, 11, 7),
  versionId: '0199e3c2-5b1a-7000-8000-00000000a001',
  versionRevision: 1,
  fromKcal: 2600,
  toKcal: 2460,
  recommendedKcal: 2420,
  expenditureKcal: 2420,
  confidence: ExpenditureConfidence.medium,
);

Widget _app(Widget card, List<Override> overrides) => ProviderScope(
  retry: (_, _) => null,
  overrides: overrides,
  child: phoneApp(Scaffold(body: ListView(children: [card]))),
);

void main() {
  testWidgets('TG-034 TG-035 the check-in card shows before → after, and '
      'Adjust stays within ±150 kcal of the current target', (tester) async {
    await tester.pumpWidget(
      _app(const CheckInCard(), [
        appliedCheckInCardProvider.overrideWith((ref) async => null),
        checkInCardProvider.overrideWith(
          (ref) async => CheckInCardView(
            record: _record(),
            draft: _draft,
            kind: CheckInCardKind.pending,
            floorKcal: 1750,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Weekly check-in'), findsOneWidget);
    expect(find.text('2,600 → 2,460 kcal a day'), findsOneWidget);
    expect(find.text('Keep current'), findsOneWidget);
    expect(find.text('Use 2,460 kcal'), findsOneWidget);
    expect(find.textContaining('about 2,420 kcal a day'), findsOneWidget);
    // Down to 2,450 (150 below 2,600), then no further.
    await tester.tap(find.byKey(const ValueKey('check-in-lower')));
    await tester.pump();
    expect(find.text('2,600 → 2,450 kcal a day'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('check-in-lower')));
    await tester.pump();
    expect(find.text('2,600 → 2,450 kcal a day'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const ValueKey('check-in-raise')));
      await tester.pump();
    }
    expect(find.text('2,600 → 2,750 kcal a day'), findsOneWidget);
  });

  testWidgets('TG-031 the expenditure card says what is still needed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const ExpenditureCard(), [
        expenditureViewProvider.overrideWith(
          (ref) async => ExpenditureView(
            readiness: const AdaptiveReadiness(
              loggedDays: 9,
              completeDays: 9,
              weighIns: 1,
              weighInSpanDays: 0,
            ),
            points: const [],
            mode: CheckInMode.ask,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Expenditure'), findsOneWidget);
    expect(
      find.text('2 more weigh-ins until your targets can adapt'),
      findsOneWidget,
    );
    expect(
      find.text('Log 5 more days until your targets can adapt'),
      findsOneWidget,
    );
    expect(find.text('Apply weekly changes automatically'), findsOneWidget);
  });

  testWidgets('DY-004 the incomplete-day card asks, it never marks', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const IncompleteDayCard(), [
        incompleteDaySuggestionProvider.overrideWith(
          (ref) async => IncompleteDaySuggestion(
            date: LocalDate(2026, 11, 5),
            kcal: 600,
            mealCount: 1,
            targetKcal: 2600,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Was this a full day?'), findsOneWidget);
    expect(find.textContaining('600 kcal logged in 1 meal'), findsOneWidget);
    expect(find.text('It was complete'), findsOneWidget);
    expect(find.text('Mark day incomplete'), findsOneWidget);
  });

  testWidgets('A38 review 7 coming back to the Progress tab retries the '
      'check-in; another tab does not', (tester) async {
    var runs = 0;
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        ...progressOverrides(
          checkIn: () async {
            runs++;
            return CheckInRun.none;
          },
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: phoneApp(const ProgressScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final first = runs;
    expect(first, greaterThanOrEqualTo(1));
    container.read(tabActivationProvider.notifier).fire(AppTab.today);
    await tester.pumpAndSettle();
    expect(runs, first);
    // Tab away and back: new history may have arrived meanwhile.
    container.read(tabActivationProvider.notifier).fire(AppTab.progress);
    await tester.pumpAndSettle();
    expect(runs, first + 1);
  });
}
