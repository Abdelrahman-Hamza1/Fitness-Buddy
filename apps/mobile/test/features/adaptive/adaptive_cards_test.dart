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
  testWidgets('TG-034 TG-035 UX-047 T-P2 the check-in is one row; Review '
      'opens the card with before → after, and Adjust stays within ±150 kcal '
      'of the current target', (tester) async {
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
    // One row on Progress; the proposal itself waits behind Review.
    expect(find.byKey(const ValueKey('check-in-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('check-in-lower')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('check-in-review')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('check-in-$_id')), findsOneWidget);
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

  testWidgets('TG-031 UX-047 T-X2 Expenditure before enough data shows the '
      'two numbers to go and How this works opens the explanation', (
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
    final toGo = find.byKey(const ValueKey('expenditure-to-go'));
    expect(toGo, findsOneWidget);
    expect(
      find.descendant(of: toGo, matching: find.byType(DecoratedBox)),
      findsNWidgets(2),
    );
    expect(find.byKey(const ValueKey('adaptive-automatic')), findsOneWidget);
    expect(find.byKey(const ValueKey('expenditure-intro')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('expenditure-how')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('expenditure-intro')), findsOneWidget);
  });

  testWidgets('DY-004 UX-047 T-P2 the incomplete day is one row; Review asks, '
      'it never marks', (tester) async {
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
    expect(find.byKey(const ValueKey('incomplete-day-row')), findsOneWidget);
    final card = find.byKey(
      ValueKey('incomplete-day-${LocalDate(2026, 11, 5)}'),
    );
    expect(card, findsNothing);
    await tester.tap(find.byKey(const ValueKey('incomplete-day-review')));
    await tester.pumpAndSettle();
    expect(card, findsOneWidget);
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

  testWidgets('A57 A48 T-R4 a failed check-in read shows a calm retry and '
      'keeps Change back', (tester) async {
    var fail = true;
    await tester.pumpWidget(
      _app(const CheckInCard(), [
        appliedCheckInCardProvider.overrideWith(
          (ref) async => CheckInCardView(
            record: _record(),
            draft: _draft,
            kind: CheckInCardKind.applied,
            floorKcal: 1750,
          ),
        ),
        checkInCardProvider.overrideWith((ref) async {
          if (fail) throw StateError('read failed');
          return null;
        }),
      ]),
    );
    await tester.pumpAndSettle();
    final failed = find.byKey(const ValueKey('check-in-load-failed'));
    final applied = find.byKey(const ValueKey('check-in-applied-row'));
    expect(failed, findsOneWidget);
    expect(applied, findsOneWidget);
    fail = false;
    await tester.tap(
      find.descendant(of: failed, matching: find.byType(TextButton)),
    );
    await tester.pumpAndSettle();
    expect(failed, findsNothing);
    expect(applied, findsOneWidget);
    // Change back is one tap away, in the row's sheet.
    await tester.tap(find.byKey(const ValueKey('check-in-applied-review')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('check-in-change-back')), findsOneWidget);
  });
}
