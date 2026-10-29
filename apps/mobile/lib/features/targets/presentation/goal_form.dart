import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/application/target_form_input.dart';
import 'package:fb_mobile/features/targets/presentation/profile_fields.dart';
import 'package:fb_mobile/features/targets/presentation/targets_text.dart';
import 'package:fb_mobile/features/targets/presentation/typed_number_field.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// The goal form (TG-010/011/013, D9 page 3), shared by setup (WP6) and
/// Me's goal sheet (A13c): Lose / Maintain / Gain; for lose and gain the
/// four ways to express it with their fields; then one live line.
///
/// The line is decided by the caller's view model, which knows the profile:
/// with a [problem] (PA3: a deadline not after today, a target weight on the
/// wrong side) the form shows that message instead of numbers; else with a
/// [calculation] (the A12 engine's, for this draft) it shows the TG-011
/// projection ("≈ −0.46 kg a week · −2 kg in November · goal reached around
/// March 2027") and, when the requested loss was capped, the TG-013 cap
/// message with the planned rate. Units follow [GoalDraft.unit].
class GoalForm extends StatelessWidget {
  /// Creates the form.
  const new({
    required this.draft,
    required this.onChanged,
    required this.today,
    this.calculation,
    this.problem,
    this.showErrors = false,
    super.key,
  });

  /// The goal as typed.
  final GoalDraft draft;

  /// Called with every edit.
  final ValueChanged<GoalDraft> onChanged;

  /// Today: "This month" is its month; target dates come after it.
  final LocalDate today;

  /// The engine's calculation for this draft, or null while incomplete.
  final TargetCalculation? calculation;

  /// Why the goal can't be resolved, or null.
  final GoalProblem? problem;

  /// Show every field's message (a refused Next or Save).
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final type = draft.type;
    final directed = type == GoalType.lose || type == GoalType.gain;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        Text(
          l10n.goalTypeTitle,
          style: FbType.label.copyWith(color: scheme.onSurface),
        ),
        Wrap(
          spacing: FbSpace.s2,
          runSpacing: FbSpace.s2,
          children: [
            for (final t in GoalType.values)
              FbChoiceChip(
                label: goalTypeLabel(l10n, t),
                selected: type == t,
                dropdown: false,
                onTap: () => onChanged(draft.withType(t)),
              ),
          ],
        ),
        if (showErrors && type == null) ChoiceError(l10n.targetsChooseOne),
        if (directed) ...[
          Text(
            l10n.goalHow,
            style: FbType.label.copyWith(color: scheme.onSurface),
          ),
          FbOptionList<GoalExpressionKind>(
            selected: draft.kind,
            onSelected: (kind) => onChanged(draft.withKind(kind)),
            options: [
              for (final kind in _kinds)
                FbOption(value: kind, label: _kindLabel(l10n, kind)),
            ],
          ),
          ..._fields(context, type!),
        ],
        if (type != null) _GoalLine(form: this),
      ],
    );
  }

  static const List<GoalExpressionKind> _kinds = [
    GoalExpressionKind.weekly,
    GoalExpressionKind.monthly,
    GoalExpressionKind.targetDate,
    GoalExpressionKind.targetRate,
  ];

  static String _kindLabel(AppLocalizations l10n, GoalExpressionKind kind) =>
      switch (kind) {
        GoalExpressionKind.weekly => l10n.goalKindWeekly,
        GoalExpressionKind.monthly => l10n.goalKindMonthly,
        GoalExpressionKind.targetDate => l10n.goalKindTargetDate,
        GoalExpressionKind.targetRate => l10n.goalKindTargetRate,
      };

  List<Widget> _fields(BuildContext context, GoalType type) {
    final l10n = context.l10n;
    final errors = draft.read(today).errors;
    final unitWord = massUnitLabel(l10n, draft.unit);
    final lose = type == GoalType.lose;
    String? error(GoalField field) =>
        goalFieldErrorText(l10n, field, errors[field], draft.unit);
    Widget number(
      GoalField field,
      String text,
      String label,
      GoalDraft Function(String) edit, {
      TextInputAction action = TextInputAction.done,
    }) => TypedNumberField(
      key: ValueKey(field),
      text: text,
      onChanged: (t) => onChanged(edit(t)),
      label: label,
      unit: unitWord,
      maxDecimals: 2,
      showError: showErrors,
      errorText: error(field),
      textInputAction: action,
    );
    final target = number(
      GoalField.targetWeight,
      draft.targetWeight,
      l10n.goalTargetWeightLabel,
      (t) => draft.copyWith(targetWeight: t),
      action: TextInputAction.next,
    );
    return switch (draft.kind) {
      GoalExpressionKind.weekly => [
        number(
          GoalField.rate,
          draft.rate,
          lose ? l10n.goalRateLoseLabel : l10n.goalRateGainLabel,
          (t) => draft.copyWith(rate: t),
        ),
      ],
      GoalExpressionKind.monthly => [
        number(
          GoalField.month,
          draft.month,
          lose ? l10n.goalMonthLoseLabel : l10n.goalMonthGainLabel,
          (t) => draft.copyWith(month: t),
        ),
      ],
      GoalExpressionKind.targetDate => [
        target,
        _DateChip(form: this, errorText: error(GoalField.targetDate)),
      ],
      GoalExpressionKind.targetRate => [
        target,
        number(
          GoalField.pace,
          draft.pace,
          l10n.goalPaceLabel,
          (t) => draft.copyWith(pace: t),
        ),
      ],
    };
  }
}

/// The "By" date chip: opens the date picker from tomorrow to 5 years ahead.
class _DateChip extends StatelessWidget {
  const new({required this.form, required this.errorText});

  final GoalForm form;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final today = form.today;
    final first = today.plusDays(1);
    final last = TargetRules.input.latestTargetDate(today);
    final current = form.draft.targetDate;
    final initial = current != null && current.isAfter(today)
        ? current
        : today.plusDays(90);
    final picked = await showFbDatePicker(
      context,
      initialDate: _dateTime(initial.isAfter(last) ? last : initial),
      firstDate: _dateTime(first),
      lastDate: _dateTime(last),
    );
    if (picked == null) return;
    form.onChanged(
      form.draft.copyWith(
        targetDate: LocalDate(picked.year, picked.month, picked.day),
      ),
    );
  }

  static DateTime _dateTime(LocalDate d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final date = form.draft.targetDate;
    final message = form.showErrors ? errorText : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FbSpace.s1,
      children: [
        FbChoiceChip(
          label: l10n.goalTargetDateLabel,
          value: date == null ? l10n.goalTargetDatePick : shortDate(l10n, date),
          icon: FbIcons.calendar,
          onTap: () => _pick(context),
        ),
        if (message != null)
          Text(message, style: FbType.bodySmall.copyWith(color: scheme.error)),
      ],
    );
  }
}

/// The live line under the goal: the problem, the maintain note, or the
/// TG-011 projection with the TG-013 cap message.
class _GoalLine extends StatelessWidget {
  const new({required this.form});

  final GoalForm form;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final draft = form.draft;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    if (form.problem case final problem?) {
      return FbInlineBanner(
        kind: FbInlineBannerKind.info,
        message: goalProblemText(l10n, problem),
      );
    }
    if (draft.type == GoalType.maintain) {
      return Text(l10n.goalMaintainNote, style: muted);
    }
    final calc = form.calculation;
    if (calc == null) return const SizedBox.shrink();
    final unit = draft.unit;
    final today = form.today;
    final month = LocalDate(today.year, today.month, 1);
    final rate = rateText(l10n, calc.achievableKgPerWeek, unit, signed: true);
    final change = massText(
      l10n,
      monthlyKgFromWeeklyRate(calc.achievableKgPerWeek, month),
      unit,
      signed: true,
    );
    final withTarget =
        draft.kind == GoalExpressionKind.targetDate ||
        draft.kind == GoalExpressionKind.targetRate;
    final projected = withTarget ? calc.projectedDate : null;
    final line = projected == null
        ? l10n.goalProjection(rate, change, monthName(l10n, month))
        : l10n.goalProjectionWithDate(
            rate,
            change,
            monthName(l10n, month),
            monthYear(l10n, projected),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        Text(
          line,
          style: FbType.numeric(FbType.body).copyWith(color: scheme.onSurface),
        ),
        if (calc.warnings.contains(TargetWarning.lossRateCapped))
          Text(capMessage(l10n, calc, unit), style: muted),
      ],
    );
  }
}

/// The TG-013 / SF-011 cap message for [calc] in [unit]: "You asked for
/// 1.2 kg a week. Plans stay within 1% of your weight a week, so this plan
/// uses 0.98 kg." Also a line of the target explanation.
String capMessage(
  AppLocalizations l10n,
  TargetCalculation calc,
  MassUnit unit,
) => l10n.goalCapMessage(
  rateText(l10n, calc.requestedKgPerWeek.abs(), unit),
  rateText(l10n, calc.cappedKgPerWeek.abs(), unit),
);
