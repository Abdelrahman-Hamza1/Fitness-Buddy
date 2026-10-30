import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/application/target_form_input.dart';
import 'package:fb_mobile/features/targets/application/targets_actions.dart';
import 'package:fb_mobile/features/targets/application/targets_providers.dart';
import 'package:fb_mobile/features/targets/application/targets_screens.dart';
import 'package:fb_mobile/features/targets/presentation/activity_options.dart';
import 'package:fb_mobile/features/targets/presentation/profile_fields.dart';
import 'package:fb_mobile/features/targets/presentation/targets_feedback.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The profile field a sheet edits (TG-001).
enum ProfileField {
  /// Formula sex.
  sex,

  /// Birth year.
  birthYear,

  /// Height (cm or ft + in).
  height,

  /// Activity level.
  activity,
}

/// Opens the editor of [field] for [opened] (D13): A13b's field, Save →
/// `saveProfile` against the row version shown, Undo "Profile updated"
/// (naming the recomputed target, D5). A profile changed elsewhere while the
/// sheet is open says "This changed. Reload." and keeps what was typed
/// (UX-052).
Future<void> showProfileEditSheet(
  BuildContext context, {
  required ProfileField field,
  required Versioned<ProfileRecord> opened,
  required LocalDate today,
}) => showFbStatefulSheet<void>(
  context,
  builder: (_) => ProfileEditSheet(field: field, opened: opened, today: today),
);

/// The body of the profile edit sheet.
class ProfileEditSheet extends ConsumerStatefulWidget {
  /// Edits [field] of the profile as it was [opened].
  const new({
    required this.field,
    required this.opened,
    required this.today,
    super.key,
  });

  /// The field edited.
  final ProfileField field;

  /// The profile row as shown when the sheet opened.
  final Versioned<ProfileRecord> opened;

  /// Today (the birth-year range).
  final LocalDate today;

  @override
  ConsumerState<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<ProfileEditSheet> {
  late Versioned<ProfileRecord> _base = widget.opened;
  late FormulaSex _sex = _base.value.sex;
  late String _birthYear = '${_base.value.birthYear}';
  late HeightDraft _height = _heightDraftOf(_base.value);
  late ActivityLevel _activity = _base.value.activity;
  bool _showErrors = false;
  bool _saving = false;
  bool _refused = false;
  TargetsFailure? _failure;

  static HeightDraft _heightDraftOf(ProfileRecord profile) {
    final length = Length.centimeters(profile.heightCm);
    return switch (profile.heightInputUnit) {
      HeightInputUnit.centimeter => HeightDraft(cm: _oneDecimal(length)),
      HeightInputUnit.feetInches => HeightDraft(
        unit: HeightInputUnit.feetInches,
        feet: '${length.toFeetAndInches().feet}',
        inches: '${length.toFeetAndInches().inches}',
      ),
    };
  }

  static String _oneDecimal(Length length) {
    final cm = roundHalfAwayFromZero(length.centimeters, 1);
    return cm == cm.truncateToDouble() ? '${cm.toInt()}' : '$cm';
  }

  /// The edit, or null while the typed value can't be used.
  ProfilePatch? get _patch => switch (widget.field) {
    ProfileField.sex => ProfilePatch(sex: _sex),
    ProfileField.activity => ProfilePatch(activity: _activity),
    ProfileField.birthYear => switch (readBirthYear(
      _birthYear,
      widget.today,
    ).value) {
      final year? => ProfilePatch(birthYear: year),
      null => null,
    },
    ProfileField.height => switch (_height.read().value) {
      final length? => ProfilePatch(
        heightCm: length.centimeters,
        heightInputUnit: _height.unit,
      ),
      null => null,
    },
  };

  String _title(AppLocalizations l10n) => switch (widget.field) {
    ProfileField.sex => l10n.profileSexLabel,
    ProfileField.birthYear => l10n.profileBirthYearLabel,
    ProfileField.height => l10n.profileHeightLabel,
    ProfileField.activity => l10n.profileActivityLabel,
  };

  Future<void> _save() async {
    final patch = _patch;
    if (patch == null) {
      setState(() => _showErrors = true);
      return;
    }
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    String doneText(TargetsDone done) => switch (recomputedKcalOf(done)) {
      final kcal? => host.l10n.profileUpdatedTarget(kcal),
      null => host.l10n.profileUpdated,
    };
    setState(() {
      _saving = true;
      _failure = null;
    });
    final outcome = await ref
        .read(targetsActionsProvider)
        .saveProfile(patch, _base.version);
    if (!mounted) {
      // Dismissed during Save: the result, Undo included, still shows on
      // the root messenger (UX-030).
      if (host.mounted) showTargetsFeedback(host, outcome, done: doneText);
      return;
    }
    setState(() => _saving = false);
    switch (outcome) {
      // A refusal keeps the sheet and what was typed (UX-052).
      case TargetsFailed(reason: TargetsFailure.changed):
        setState(() => _refused = true);
        return;
      case TargetsFailed(:final reason):
        setState(() => _failure = reason);
        return;
      case TargetsPending() || TargetsNeedsAcknowledgement():
        return;
      case TargetsDone() || TargetsUnchanged():
        nav.pop();
    }
    if (!host.mounted) return;
    showTargetsFeedback(host, outcome, done: doneText);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stored = ref.watch(profileProvider).value;
    final stale =
        _refused || (stored != null && stored.version != _base.version);
    final field = switch (widget.field) {
      ProfileField.sex => SexField(
        selected: _sex,
        onSelected: (sex) => setState(() => _sex = sex),
      ),
      ProfileField.birthYear => BirthYearField(
        text: _birthYear,
        today: widget.today,
        showError: _showErrors,
        onChanged: (text) => setState(() => _birthYear = text),
      ),
      ProfileField.height => HeightField(
        draft: _height,
        showError: _showErrors,
        showUnitChoice: true,
        onChanged: (draft) => setState(() => _height = draft),
      ),
      ProfileField.activity => ActivityOptions(
        selected: _activity,
        onSelected: (level) => setState(() => _activity = level),
      ),
    };
    return FbSheet(
      title: _title(l10n),
      actions: FbButton.primary(
        label: l10n.targetsSave,
        expand: true,
        onPressed: stale || _saving ? null : () => unawaited(_save()),
      ),
      child: Padding(
        // Lifts the sheet above the keyboard.
        padding: EdgeInsetsDirectional.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s3,
          children: [
            if (stale)
              FbInlineBanner(
                kind: FbInlineBannerKind.info,
                message: l10n.targetsChangedReload,
                actionLabel: l10n.targetsReload,
                onAction: stored == null
                    ? null
                    : () => setState(() {
                        // The stored row becomes the base; what was typed
                        // stays (UX-052).
                        _base = stored;
                        _refused = false;
                      }),
              ),
            if (_failure case final reason?) SaveFailedBanner(reason: reason),
            field,
          ],
        ),
      ),
    );
  }
}
