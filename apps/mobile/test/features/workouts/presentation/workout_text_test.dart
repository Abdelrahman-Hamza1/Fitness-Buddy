import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/presentation/workout_text.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('A65 m7 a name is blank while the library loads, never a false '
      '"Removed exercise"', () {
    expect(l10n.exerciseName(ExerciseLibrary.empty, 'bench-press'), '');
  });

  test('A65 m7 D15 a loaded library still names a real miss as removed', () {
    final loaded = ExerciseLibrary(const []);
    expect(l10n.exerciseName(loaded, 'gone'), l10n.workoutRemovedExercise);
  });
}
