import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/onboarding/application/setup_flow.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/page_parts.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// "A bit about you" (D9, TG-001/002, D-088): sex, birth year, height and
/// current weight (the first weigh-in, WB-001), in the units of the
/// setting, with a quiet switch to the other system.
class YouPage extends StatelessWidget {
  /// Creates the page.
  const new({
    required this.draft,
    required this.flow,
    this.fieldKeys = const {},
    super.key,
  });

  /// What the flow holds.
  final SetupDraft draft;

  /// The view model.
  final SetupFlow flow;

  /// Keys of the required inputs, so a refused Continue can scroll there.
  final Map<SetupField, GlobalKey> fieldKeys;

  Widget _keyed(SetupField field, Widget child) =>
      KeyedSubtree(key: fieldKeys[field], child: child);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final imperial = draft.units == UnitSystem.imperial;
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final year = _keyed(
      SetupField.birthYear,
      BirthYearField(
        text: draft.birthYear,
        today: draft.today,
        onChanged: flow.setBirthYear,
        showError: draft.showErrors,
      ),
    );
    final height = _keyed(
      SetupField.height,
      HeightField(
        draft: draft.height,
        onChanged: flow.setHeight,
        showError: draft.showErrors,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s4,
      children: [
        SetupHeader(title: l10n.setupYouTitle, hint: l10n.setupYouHint),
        _keyed(
          SetupField.sex,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s2,
            children: [
              SetupLabel(l10n.profileSexLabel),
              FbSegmented<FormulaSex>(
                options: [
                  for (final sex in FormulaSex.values)
                    FbOption(value: sex, label: sexLabel(l10n, sex)),
                ],
                selected: draft.sex,
                onSelected: flow.setSex,
              ),
              if (draft.showErrors && draft.sex == null)
                ChoiceError(l10n.targetsChooseOne),
            ],
          ),
        ),
        // Side by side on a phone; stacked at large text (UX-070) and for
        // feet + inches, which need the room.
        if (large || imperial) ...[
          year,
          height,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FbSpace.s3,
            children: [
              Expanded(child: year),
              Expanded(child: height),
            ],
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
        _UnitsSwitch(
          ask: imperial ? l10n.setupToMetricAsk : l10n.setupToImperialAsk,
          action: imperial ? l10n.setupToMetric : l10n.setupToImperial,
          onTap: () =>
              flow.setUnits(imperial ? UnitSystem.metric : UnitSystem.imperial),
        ),
      ],
    );
  }
}

/// "Using pounds or feet? Switch to imperial" (TG-002).
class _UnitsSwitch extends StatelessWidget {
  const new({required this.ask, required this.action, required this.onTap});

  final String ask;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: FbSpace.s1,
    children: [
      Text(
        ask,
        style: FbType.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      FbButton.text(label: action, onPressed: onTap),
    ],
  );
}
