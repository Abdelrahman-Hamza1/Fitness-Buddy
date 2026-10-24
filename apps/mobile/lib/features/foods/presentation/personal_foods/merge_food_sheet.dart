import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/foods/application/foods_providers.dart';
import 'package:fb_mobile/features/foods/application/personal_food_actions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// Merges a duplicate into [food] (FD-073, A09 D6): first the list of the
/// foods that can be merged in, then the confirmation, which can swap which
/// of the two is kept. Resolves to the merge's outcome when it was applied,
/// so the caller can offer Undo; null when the user backed out.
Future<PersonalFoodDone?> showMergeFoodSheet(
  BuildContext context, {
  required PersonalFood food,
}) async {
  final picked = await showFbSheet<PersonalFood>(
    context,
    title: context.l10n.personalFoodMergeTitle,
    builder: (_) => MergePickerSheet(food: food),
  );
  if (picked == null || !context.mounted) return null;
  return await showFbSheet<PersonalFoodDone>(
    context,
    title: context.l10n.personalFoodMergeConfirmTitle,
    builder: (_) => MergeConfirmSheet(keep: food, other: picked),
  );
}

/// Calories per 100 as the lists show them: "250 kcal per 100 g".
String kcalPerText(AppLocalizations l10n, PersonalFood food) =>
    l10n.yourFoodsKcalPer(
      DisplayRounding.kcal(food.per100.kcal),
      food.basis == NutrientBasis.per100g
          ? l10n.personalFoodBasis100g
          : l10n.personalFoodBasis100ml,
    );

/// The foods that can be merged into [food]: every other food measured the
/// same way (grams or millilitres), by name. Pops with the one tapped.
class MergePickerSheet extends ConsumerWidget {
  /// Creates the list for [food].
  const new({required this.food, super.key});

  /// The food that stays, as the form shows it.
  final PersonalFood food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final foods = ref.watch(personalFoodsProvider).value ?? const [];
    final candidates = [
      for (final other in foods)
        if (other.id != food.id && other.basis == food.basis) other,
    ];
    if (candidates.isEmpty) {
      return Text(
        l10n.personalFoodMergeNone(
          food.basis == NutrientBasis.per100g ? 'g' : 'ml',
        ),
        style: FbType.body.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s2),
          child: Text(
            l10n.personalFoodMergePickMessage(food.names.en),
            style: FbType.body.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final other in candidates)
          FbListRow(
            key: ValueKey(other.id),
            title: other.names.en,
            subtitle: kcalPerText(l10n, other),
            leading: const FbSourceBadge(source: FbSource.yours),
            onTap: () => Navigator.of(context).pop(other),
          ),
      ],
    );
  }
}

/// The confirmation (UX-030's bulk rule): both foods as rows, the kept one
/// ("Stays") and the one merged in and removed, each with its calories per
/// 100; what happens, a swap, and Merge. It watches both foods and refuses
/// to merge ones that changed or were deleted since they were picked (A08
/// D12(4)).
class MergeConfirmSheet extends ConsumerStatefulWidget {
  /// Creates the confirmation that keeps [keep] and merges [other] into it.
  const new({required this.keep, required this.other, super.key});

  /// The food kept at first.
  final PersonalFood keep;

  /// The duplicate merged into it at first.
  final PersonalFood other;

  @override
  ConsumerState<MergeConfirmSheet> createState() => _MergeConfirmSheetState();
}

class _MergeConfirmSheetState extends ConsumerState<MergeConfirmSheet> {
  late PersonalFood _keep = widget.keep;
  late PersonalFood _other = widget.other;
  bool _busy = false;
  PersonalFoodFailure? _failure;

  Future<void> _merge() async {
    final nav = Navigator.of(context);
    setState(() {
      _busy = true;
      _failure = null;
    });
    final outcome = await ref
        .read(personalFoodActionsProvider)
        .merge(_keep, _other);
    if (!mounted) return;
    switch (outcome) {
      case PersonalFoodDone():
        nav.pop(outcome);
      case PersonalFoodFailed(:final reason):
        setState(() {
          _busy = false;
          _failure = reason;
        });
      case PersonalFoodUnchanged() || PersonalFoodPending():
        setState(() => _busy = false);
    }
  }

  /// Takes over both foods as they are stored now.
  void _reload() {
    final keep = ref.read(personalFoodProvider(_keep.id)).value;
    final other = ref.read(personalFoodProvider(_other.id)).value;
    if (keep == null || other == null) return;
    setState(() {
      _keep = keep;
      _other = other;
      _failure = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final live = (
      keep: ref.watch(personalFoodProvider(_keep.id)),
      other: ref.watch(personalFoodProvider(_other.id)),
    );
    final liveKeep = live.keep.value;
    final liveOther = live.other.value;
    final loaded = live.keep.hasValue && live.other.hasValue;
    final removed = loaded && (liveKeep == null || liveOther == null);
    final changed =
        loaded &&
        !removed &&
        (liveKeep!.version != _keep.version ||
            liveOther!.version != _other.version);
    final note = removed
        ? l10n.personalFoodMergeRemoved
        : changed
        ? l10n.personalFoodMergeChanged
        : switch (_failure) {
            null => null,
            PersonalFoodFailure.changed => l10n.personalFoodMergeChanged,
            PersonalFoodFailure.removed => l10n.personalFoodMergeRemoved,
            PersonalFoodFailure.tooMany => l10n.personalFoodMergeTooMany,
            PersonalFoodFailure.basisMismatch => l10n.personalFoodMergeBasis,
            PersonalFoodFailure.invalid => l10n.personalFoodMergeFailed,
          };
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        if (note != null)
          FbInlineBanner(
            kind: removed || _failure != null
                ? FbInlineBannerKind.error
                : FbInlineBannerKind.info,
            message: note,
            actionLabel: changed ? l10n.personalFoodReload : null,
            onAction: changed ? _reload : null,
          ),
        FbListRow(
          key: const ValueKey('merge-keep'),
          title: _keep.names.en,
          subtitle: l10n.personalFoodMergeRowSubtitle(
            l10n.personalFoodMergeStays,
            kcalPerText(l10n, _keep),
          ),
          leading: const FbSourceBadge(source: FbSource.yours),
        ),
        FbListRow(
          key: const ValueKey('merge-other'),
          title: _other.names.en,
          subtitle: l10n.personalFoodMergeRowSubtitle(
            l10n.personalFoodMergeGoes,
            kcalPerText(l10n, _other),
          ),
          leading: const FbSourceBadge(source: FbSource.yours),
        ),
        Text(
          l10n.personalFoodMergeConfirmMessage(_keep.names.en, _other.names.en),
          style: FbType.body.copyWith(color: scheme.onSurfaceVariant),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FbButton.text(
            label: l10n.personalFoodMergeSwap,
            icon: FbIcons.move,
            onPressed: _busy
                ? null
                : () => setState(() {
                    final kept = _keep;
                    _keep = _other;
                    _other = kept;
                    _failure = null;
                  }),
          ),
        ),
        FbButton.primary(
          label: l10n.personalFoodMergeConfirm,
          expand: true,
          onPressed: _busy || removed || changed ? null : _merge,
        ),
      ],
    );
  }
}
