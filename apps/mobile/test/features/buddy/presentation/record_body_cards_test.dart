import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';
import '../support/buddy_widgets.dart';

const _lang = {'language': 'english', 'script': 'latin'};

Future<BuddyHarness> _show(
  WidgetTester tester,
  Map<String, Object?> intent, {
  Future<Object?> Function(BuddyHarness h)? seed,
}) async {
  final h = BuddyHarness()
    ..answer({
      'intents': [intent],
    });
  await seed?.call(h);
  await pumpBuddyHost(tester, h, textScale: 2);
  await openBuddySheet(tester);
  await sendInSheet(tester, 'log it');
  await _settle(tester);
  return h;
}

/// Lets the turn and the card's local reads finish (more than the food
/// cards need: the plan reads several tables).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await settleBuddy(tester);
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  testWidgets('WO-033 a workout card asks for an unmatched exercise; a pick '
      'makes it savable (text scale 2)', (tester) async {
    const exercise = '019a1b2c-0000-7000-8000-00000000e001';
    final h = await _show(
      tester,
      {
        'kind': 'workout',
        ..._lang,
        'name': null,
        'timeHint': null,
        'dateHint': null,
        'exercises': [
          {
            'mention': 'bench',
            'exerciseRef': null,
            'sets': [
              {
                'reps': 8,
                'weight': 80,
                'unit': 'kg',
                'perDumbbell': false,
                'durationSeconds': null,
                'distanceMeters': null,
              },
            ],
            'assumptions': ['matched “bench”'],
          },
        ],
      },
      seed: (h) => h.applier.apply(
        ChangeSet([
          CreateCustomExercise(
            exercise,
            CustomExerciseDraft(
              name: 'Bench press',
              type: ExerciseType.weightReps,
              equipment: Equipment.barbell,
            ),
          ),
        ], origin: Origin.direct),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      find.text('Not in your exercises: “bench”. Which is it?'),
      findsOneWidget,
    );
    expect(find.text('matched “bench”'), findsOneWidget);
    await _tap(tester, find.text('Bench press'));
    final card = h.state.turns.single.records.single;
    expect(card.plan.canConfirm, isTrue);
    await _tap(tester, find.text('Save'));
    expect(
      h.state.turns.single.records.single.resolution,
      CardResolution.logged,
    );
    await unmountBuddy(tester, h);
  });

  testWidgets('WB-031 an import card lists flagged rows; Include counts them '
      '(text scale 2)', (tester) async {
    final h = await _show(tester, {
      'kind': 'importRows',
      ..._lang,
      'metric': 'weight',
      'measurementKind': null,
      'rows': [
        {
          'date': '2026-10-01',
          'value': 98,
          'unit': 'k',
          'original': 'oct 1: 98k',
        },
        {
          'date': '2026-10-05',
          'value': 97.6,
          'unit': 'kg',
          'original': 'oct 5: 97.6kg',
        },
      ],
    });
    expect(tester.takeException(), isNull);
    expect(find.text('1 of 2 rows will be imported'), findsOneWidget);
    expect(find.text('Import 1 row'), findsOneWidget);
    await _tap(tester, find.text('Include'));
    expect(find.text('Import 2 rows'), findsOneWidget);
    expect(h.state.turns.single.records.single.adjust.accepted, {0});
    await unmountBuddy(tester, h);
  });

  testWidgets('WB-040 a measurement card (text scale 2)', (tester) async {
    final h = await _show(tester, {
      'kind': 'measurement',
      ..._lang,
      'measurementKind': 'waist',
      'customTypeId': null,
      'value': 90,
      'unit': 'cm',
      'timeHint': null,
      'dateHint': null,
    });
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Waist: 90.0 cm'), findsOneWidget);
    await unmountBuddy(tester, h);
  });

  testWidgets('A69 review: a new exercise shows its sets with the type it '
      'takes from them (a timed plank)', (tester) async {
    final h = await _show(tester, {
      'kind': 'workout',
      ..._lang,
      'name': null,
      'timeHint': null,
      'dateHint': null,
      'exercises': [
        {
          'mention': 'plank',
          'exerciseRef': null,
          'sets': [
            {
              'reps': null,
              'weight': null,
              'unit': null,
              'perDumbbell': false,
              'durationSeconds': 60,
              'distanceMeters': null,
            },
          ],
          'assumptions': <String>[],
        },
      ],
    });
    expect(find.text('No sets yet'), findsNothing);
    expect(find.text('1:00'), findsOneWidget);
    await _tap(tester, find.text('New exercise “plank”'));
    expect(find.text('1:00'), findsOneWidget);
    expect(h.state.turns.single.records.single.plan.canConfirm, isTrue);
    await unmountBuddy(tester, h);
  });

  testWidgets('A69 review: every imported row can be listed before Import', (
    tester,
  ) async {
    final h = await _show(tester, {
      'kind': 'importRows',
      ..._lang,
      'metric': 'weight',
      'measurementKind': null,
      'rows': [
        for (var d = 1; d <= 6; d++)
          {
            'date': '2026-10-0$d',
            'value': 98 - d / 10,
            'unit': 'kg',
            'original': 'oct $d',
          },
      ],
    });
    expect(find.text('3 more rows are fine'), findsOneWidget);
    expect(find.textContaining('97.4 kg'), findsNothing);
    await _tap(tester, find.text('Show all 6 rows'));
    for (final v in ['97.9', '97.8', '97.7', '97.6', '97.5', '97.4']) {
      expect(find.textContaining('$v kg'), findsOneWidget);
    }
    await _tap(tester, find.text('Show fewer'));
    expect(find.textContaining('97.4 kg'), findsNothing);
    await unmountBuddy(tester, h);
  });
}
