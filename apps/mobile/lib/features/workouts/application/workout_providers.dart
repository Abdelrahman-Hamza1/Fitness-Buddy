import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/workouts/data/workout_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workout_providers.g.dart';

/// The weekly plan: planned weekday → template ID (WO-021).
@riverpod
Stream<Map<DayOfWeek, String>> weeklyPlan(Ref ref) =>
    ref.watch(workoutRepositoryProvider).watchPlan();

/// Dates from [from] to [to] with a logged session.
@riverpod
Stream<Set<LocalDate>> loggedWorkoutDates(
  Ref ref,
  LocalDate from,
  LocalDate to,
) => ref.watch(workoutRepositoryProvider).watchLoggedDates(from, to);

/// What the workout plan feeds into calorie shifting for the week
/// [from]–[to] (TG-043, WO-061, A36 D5): null while training-day shifting
/// is off or nothing is planned. Targets read it through this barrel.
@riverpod
Future<TrainingShiftInput?> trainingShift(
  Ref ref,
  LocalDate from,
  LocalDate to,
) async {
  final weightFuture = ref.watch(trainingDayWeightProvider.future);
  final planFuture = ref.watch(weeklyPlanProvider.future);
  final datesFuture = ref.watch(loggedWorkoutDatesProvider(from, to).future);
  final weight = await weightFuture;
  final plan = await planFuture;
  final dates = await datesFuture;
  if (weight == null || plan.isEmpty) return null;
  return TrainingShiftInput(
    plannedDays: plan.keys,
    weight: weight,
    loggedDates: dates,
  );
}
