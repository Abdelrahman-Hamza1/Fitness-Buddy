import 'package:fb_mobile/features/onboarding/application/setup_flow.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter/widgets.dart';

/// Page 3 (D9, TG-010/011/013, PA3): the shared goal form with the engine's
/// live line for the typed profile and weight; an unresolvable goal shows
/// its message, and Next stays on this page until it is fixed.
class GoalPage extends StatelessWidget {
  /// Creates the page.
  const new({
    required this.draft,
    required this.flow,
    this.fieldKeys = const {},
    super.key,
  });

  /// What setup holds.
  final SetupDraft draft;

  /// The view model.
  final SetupFlow flow;

  /// Keys of the required inputs, so a refused Next can scroll to the first
  /// problem.
  final Map<SetupField, GlobalKey> fieldKeys;

  Widget _keyed(SetupField field, Widget child) =>
      KeyedSubtree(key: fieldKeys[field], child: child);

  @override
  Widget build(BuildContext context) => _keyed(
    SetupField.goal,
    GoalForm(
      draft: draft.goal,
      onChanged: flow.setGoal,
      today: draft.today,
      calculation: draft.goalCalculation,
      problem: draft.goalProblem,
      showErrors: draft.showErrors,
    ),
  );
}
