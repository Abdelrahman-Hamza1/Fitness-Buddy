import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/presentation/profile_fields.dart';
import 'package:fb_mobile/features/targets/presentation/targets_text.dart';
import 'package:flutter/widgets.dart';

/// The four activity levels with plain descriptions (TG-001, D9 page 2),
/// nothing preselected in setup. Shared with Me's activity sheet (A13c).
class ActivityOptions extends StatelessWidget {
  /// Creates the list.
  const new({
    required this.selected,
    required this.onSelected,
    this.showError = false,
    super.key,
  });

  /// The chosen level, or null before a choice.
  final ActivityLevel? selected;

  /// Called with the tapped level.
  final ValueChanged<ActivityLevel> onSelected;

  /// Say "Choose one to continue." while nothing is chosen (a refused Next).
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final list = FbOptionList<ActivityLevel>(
      selected: selected,
      onSelected: onSelected,
      options: [
        for (final level in ActivityLevel.values)
          FbOption(
            value: level,
            label: activityLabel(l10n, level),
            subtitle: activityDescription(l10n, level),
          ),
      ],
    );
    if (!showError || selected != null) return list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [ChoiceError(l10n.targetsChooseOne), list],
    );
  }
}
