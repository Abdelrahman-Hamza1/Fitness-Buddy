/// The Workouts feature. Other features and `app/` import only this barrel
/// (`03-architecture.md` §3.2).
library;

export 'application/workout_providers.dart';
export 'application/workout_views.dart' show TodayWorkout, todayWorkoutProvider;
export 'data/workout_op_handler.dart' show WorkoutOpHandler, planDayId;
export 'data/workout_repository.dart';
export 'presentation/workout_history_screen.dart';
export 'presentation/workout_log_screen.dart';
export 'presentation/workout_today_row.dart';
export 'presentation/workouts_screen.dart';
