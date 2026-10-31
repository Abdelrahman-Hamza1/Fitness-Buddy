import 'package:drift/drift.dart' show Variable;
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/quick_add/quick_add.dart';
import 'package:fb_mobile/features/workouts/presentation/set_row.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_support.dart';

/// A fixed UUIDv7-shaped id for row [n] of this journey.
String _id(int n) =>
    '0199e3c2-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}';

/// Today's live diary entries in the profile.
Future<int> _todayEntries(ProviderContainer container, LocalDate today) async {
  final db = container.read(appDatabaseProvider);
  final rows = await db
      .customSelect(
        'SELECT id FROM diary_entries WHERE deleted_at IS NULL '
        'AND local_date = ?',
        variables: [Variable('$today')],
      )
      .get();
  return rows.length;
}

/// OF-01 on the device (A42 D4), in airplane mode: a repeat meal by its
/// quick-add chip, an edit of its amount, a weigh-in, a workout by the form
/// and the Progress charts, on a throw-away profile; every write goes
/// through the app's own screens and single writer.
/// The grams of today's one live entry.
Future<double?> _todayGrams(
  ProviderContainer container,
  LocalDate today,
) async {
  final rows = await container
      .read(appDatabaseProvider)
      .customSelect(
        'SELECT amount FROM diary_entries WHERE deleted_at IS NULL '
        'AND local_date = ?',
        variables: [Variable('$today')],
      )
      .get();
  return rows.length == 1 ? rows.single.read<double>('amount') : null;
}

/// Types [keys] on the visible number pad.
Future<void> _pad(WidgetTester tester, String keys) async {
  for (final key in keys.split('')) {
    await tapExactly(
      tester,
      find.descendant(of: find.byType(FbNumberPad), matching: find.text(key)),
      'pad key $key',
    );
    await tester.pump();
  }
}

void main() {
  patrolTest('OF-01 airplane mode: quick-add chip, entry edit, weigh-in, '
      'workout by form, Progress', ($) async {
    // Airplane mode for real (the CI emulator reaches no API anyway); back
    // on afterwards, so the next journey has its network.
    await $.platform.mobile.enableAirplaneMode();
    addTearDown($.platform.mobile.disableAirplaneMode);
    final container = await bootApp($, 'it-offline', rootName: 'fb_off_it');
    final tester = $.tester;
    final clock = container.read(clockProvider);
    final now = EntryTime.now(clock).localDateTime;
    final today = now.date;
    final slot = container.read(quickAddContextProvider).slotId;

    // History for one chip (the same food at this time of day on the three
    // days before) and a past workout for the form's hints.
    final food = EntryFood(
      ref: FoodRef.catalog('it-offline-food', version: '1'),
      names: FoodNames('Offline oats'),
      per100: Nutrients(kcal: 380, protein: 13, carbs: 60, fat: 7, fiber: 10),
      provenance: Provenance(source: FoodSource.database),
    );
    final applied = await container
        .read(changeSetApplierProvider)
        .apply(
          ChangeSet([
            LogEntries([
              for (var d = 1; d <= 3; d++)
                NewDiaryEntry(
                  id: _id(d),
                  when: EntryWhen.at(
                    EntryTime.fromLocal(
                      LocalDateTime(
                        today.plusDays(-d),
                        hour: now.hour,
                        minute: now.minute,
                      ),
                      clock,
                    ),
                  ),
                  slotId: slot,
                  food: food,
                  amount: EntryAmount(
                    input: Quantity(60, 'g'),
                    amount: 60,
                    basis: NutrientBasis.per100g,
                  ),
                ),
            ]),
            CreateCustomExercise(
              _id(20),
              CustomExerciseDraft(
                name: 'Offline press',
                type: ExerciseType.weightReps,
                equipment: Equipment.dumbbell,
              ),
            ),
            LogWorkoutSession(
              _id(21),
              WorkoutSessionDraft(
                date: today.plusDays(-2),
                name: 'Push',
                exercises: [
                  SessionExerciseDraft(
                    id: _id(22),
                    exerciseId: _id(20),
                    sets: [
                      LoggedSet(_id(23), const SetValues(reps: 10, kg: 20)),
                      LoggedSet(_id(24), const SetValues(reps: 8, kg: 22.5)),
                    ],
                  ),
                ],
              ),
            ),
          ], origin: Origin.direct),
        );
    expect(applied.toString(), startsWith('Applied'));

    // 1. The chip logs the repeat meal in one tap.
    final chip = find.widgetWithText(FbQuickAddChip, 'Offline oats');
    await waitUntil(
      tester,
      () => chip.evaluate().isNotEmpty,
      'the quick-add chip',
    );
    await tapExactly(tester, chip.first, 'the quick-add chip');
    await waitUntilAsync(
      tester,
      () async => await _todayEntries(container, today) == 1,
      "today's logged entry",
    );

    // 2. Edit it: its meal, its row, the amount, 120 g.
    await tapExactly(
      tester,
      find.byWidgetPredicate(
        (w) => w is SlotHeaderTile && w.section.key == slot,
      ),
      'the meal',
    );
    await pumpFor(tester, const Duration(milliseconds: 600));
    await tapExactly(
      tester,
      find.widgetWithText(FbListRow, 'Offline oats').first,
      'the entry',
    );
    await pumpFor(tester, const Duration(milliseconds: 600));
    await tapExactly(
      tester,
      find.byWidgetPredicate((w) => w is FbChoiceChip && w.label == 'Amount'),
      'Amount',
    );
    await waitUntil(
      tester,
      () => find.byType(FbNumberPad).evaluate().isNotEmpty,
      'the amount pad',
    );
    await _pad(tester, '120');
    await tapExactly(
      tester,
      find.widgetWithText(FbButton, 'Save').last,
      'Save',
    );
    await waitUntilAsync(
      tester,
      () async => await _todayGrams(container, today) == 120,
      'the edited amount',
    );

    // 3. A weigh-in from Today's weight card.
    await pumpFor(tester, const Duration(seconds: 6)); // the snackbar goes
    await tapExactly(tester, find.byType(WeightCard).first, 'the weight card');
    await waitUntil(
      tester,
      () => find.byType(FbNumberPad).evaluate().isNotEmpty,
      'the weigh-in pad',
    );
    await _pad(tester, '97.4');
    await tapExactly(
      tester,
      find.widgetWithText(FbButton, 'Save').last,
      'Save',
    );
    await waitUntilAsync(tester, () async {
      final rows = await container
          .read(appDatabaseProvider)
          .customSelect('SELECT id FROM weigh_ins WHERE deleted_at IS NULL')
          .get();
      return rows.length == 1;
    }, 'the weigh-in');
    await pumpFor(tester, const Duration(seconds: 6)); // the snackbar goes

    // 4. A workout by the form: last time's sets accepted, then Done.
    final router = container.read(appRouterProvider)
      ..go(WorkoutLogRoute(exercises: [_id(20)]));
    await waitUntil(
      tester,
      () => find.byType(SetRow).evaluate().length == 2,
      'the two set rows',
    );
    for (final row in tester.widgetList<SetRow>(find.byType(SetRow)).toList()) {
      await tapExactly(
        tester,
        find.byKey(ValueKey('workout-set-done-${row.row.id}')),
        'set done',
      );
      await pumpFor(tester, const Duration(milliseconds: 300));
    }
    await tapExactly(
      tester,
      find.byKey(const ValueKey('workout-log-done')),
      'Done',
    );
    await waitUntilAsync(tester, () async {
      final sessions = await WorkoutRepository(
        container.read(appDatabaseProvider),
      ).allSessions();
      return sessions.any((s) => s.draft.date == today);
    }, "today's workout");

    // 5. Progress draws its charts from local data.
    router.go(const ProgressRoute());
    await waitUntil(
      tester,
      () =>
          find.byType(ProgressScreen).evaluate().isNotEmpty &&
          find
              .byWidgetPredicate(
                (w) => w is FbBarChart || w is FbTimeSeriesChart,
                skipOffstage: false,
              )
              .evaluate()
              .isNotEmpty,
      'a Progress chart',
    );
  }, timeout: const Timeout(Duration(minutes: 4)));
}
