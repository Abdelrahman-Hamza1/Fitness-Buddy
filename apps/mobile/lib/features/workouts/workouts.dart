/// The Workouts feature. Other features and `app/` import only this barrel
/// (`03-architecture.md` §3.2).
library;

export 'application/workout_providers.dart';
export 'application/workout_views.dart'
    show
        TodayWorkout,
        TodayWorkoutLogged,
        TodayWorkoutPlanned,
        allWorkoutSessionsProvider,
        todayWorkoutProvider,
        weeklyWorkoutSummaryProvider;
export 'data/workout_op_handler.dart' show WorkoutOpHandler, planDayId;
export 'data/workout_repository.dart';
export 'presentation/exercise_picker_screen.dart' show ExercisePickerScreen;
export 'presentation/exercise_screen.dart'
    show ExerciseBrowseTab, ExerciseScreen;
export 'presentation/starter_plans_screen.dart' show StarterPlansScreen;
export 'presentation/weekly_plan_screen.dart' show WeeklyPlanScreen;
export 'presentation/workout_history_screen.dart';
export 'presentation/workout_log_screen.dart';
export 'presentation/workout_today_row.dart';
export 'presentation/workouts_screen.dart';
