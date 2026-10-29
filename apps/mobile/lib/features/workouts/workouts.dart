/// The Workouts feature. Other features and `app/` import only this barrel
/// (`03-architecture.md` §3.2).
library;

export 'application/workout_providers.dart';
export 'data/workout_op_handler.dart' show WorkoutOpHandler, planDayId;
export 'data/workout_repository.dart';
export 'presentation/workouts_screen.dart';
