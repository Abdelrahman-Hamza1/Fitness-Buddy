import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/onboarding/application/setup_flow.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/page_parts.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';

/// Page 1, "About you" (D9, TG-001/002): units (prefilled from the setting;
/// they drive the inputs), sex, birth year, height and current weight (the
/// first weigh-in, WB-001).
class YouPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s4,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s2,
          children: [
            SetupLabel(l10n.settingsUnits),
            Wrap(
              spacing: FbSpace.s2,
              runSpacing: FbSpace.s2,
              children: [
                for (final (units, label) in [
                  (UnitSystem.metric, l10n.settingsUnitsMetric),
                  (UnitSystem.imperial, l10n.settingsUnitsImperial),
                ])
                  FbChoiceChip(
                    label: label,
                    selected: draft.units == units,
                    dropdown: false,
                    onTap: () => flow.setUnits(units),
                  ),
              ],
            ),
          ],
        ),
        _keyed(
          SetupField.sex,
          SexField(
            selected: draft.sex,
            onSelected: flow.setSex,
            showError: draft.showErrors,
          ),
        ),
        _keyed(
          SetupField.birthYear,
          BirthYearField(
            text: draft.birthYear,
            today: draft.today,
            onChanged: flow.setBirthYear,
            showError: draft.showErrors,
          ),
        ),
        _keyed(
          SetupField.height,
          HeightField(
            draft: draft.height,
            onChanged: flow.setHeight,
            showError: draft.showErrors,
          ),
        ),
        _keyed(
          SetupField.weight,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s1,
            children: [
              BodyWeightField(
                draft: draft.weight,
                onChanged: flow.setWeight,
                textInputAction: TextInputAction.done,
                showError: draft.showErrors,
              ),
              SetupHint(l10n.setupWeightHint),
            ],
          ),
        ),
      ],
    );
  }
}
