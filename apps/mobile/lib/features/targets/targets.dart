/// Targets: profile, goal phases and target settings storage, the per-date
/// providers and every targets command (A13a); the shared profile and goal
/// forms, the explanation and the targets words (A13b); Me's Profile & goal
/// and Targets screens (A13c). Other features and
/// `app/` import only this barrel (`03-architecture.md` §3.2).
library;

export 'application/body_weight.dart';
export 'application/setup_input.dart';
export 'application/target_form_input.dart';
export 'application/targets_actions.dart';
export 'application/targets_providers.dart';
export 'application/targets_screens.dart';
export 'data/targets_op_handler.dart';
export 'data/targets_repository.dart';
export 'presentation/activity_options.dart';
export 'presentation/goal_form.dart';
export 'presentation/macro_summary.dart';
export 'presentation/profile_fields.dart';
export 'presentation/profile_goal_screen.dart' show ProfileGoalScreen;
export 'presentation/target_explanation.dart';
export 'presentation/targets_screen.dart' show TargetsScreen;
export 'presentation/targets_text.dart';
