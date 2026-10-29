import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/onboarding/application/setup_flow.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/page_parts.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter/widgets.dart';

/// Page 2 (D9): the four activity levels with plain descriptions, nothing
/// preselected.
class ActivityPage extends StatelessWidget {
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: FbSpace.s2,
    children: [
      SetupHint(context.l10n.setupActivityHint),
      _keyed(
        SetupField.activity,
        ActivityOptions(
          selected: draft.activity,
          onSelected: flow.setActivity,
          showError: draft.showErrors,
        ),
      ),
    ],
  );
}
