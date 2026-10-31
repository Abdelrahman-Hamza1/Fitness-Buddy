import 'package:fb_domain/fb_domain.dart';
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
