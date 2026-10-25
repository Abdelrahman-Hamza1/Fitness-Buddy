import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:fb_mobile/features/diary/application/slot_providers.dart';
import 'package:fb_mobile/features/diary/presentation/entry_actions.dart';
import 'package:fb_mobile/features/diary/presentation/live_meal.dart';
import 'package:fb_mobile/features/diary/presentation/move_to_slot_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the sheet that copies [section] of [date] to another day or meal
/// (DY-023, A08 D11). The view stays on the current day.
Future<void> showCopyMealSheet(
  BuildContext context, {
  required SlotSection section,
  required LocalDate date,
}) {
  final l10n = context.l10n;
  final name = section.slot == null
      ? l10n.diarySlotOther
      : slotLabel(l10n, section.slot!);
  return showFbSheet<void>(
    context,
    title: l10n.diaryCopyTitle(name),
    builder: (_) => CopyMealSheet(section: section, date: date),
  );
}

/// The body of the copy sheet: a Day chip, a Meal chip and Copy.
class CopyMealSheet extends ConsumerStatefulWidget {
  /// Creates the sheet for [section] of [date].
  const new({required this.section, required this.date, super.key});

  /// The meal as shown when the sheet opened.
  final SlotSection section;

  /// The meal's day.
  final LocalDate date;

  @override
  ConsumerState<CopyMealSheet> createState() => _CopyMealSheetState();
}

class _CopyMealSheetState extends ConsumerState<CopyMealSheet> {
  /// The day after the viewed one, or today when that is still to come.
  late LocalDate _toDate = _defaultDay();

  /// The meal to copy to; null while it is the source meal itself.
  String? _toSlotId;
  bool _targetInitialised = false;

  bool _saving = false;
  DiaryActionFailure? _failure;

  LocalDate get _today => EntryTime.now(ref.read(clockProvider)).localDate;

  LocalDate _defaultDay() {
    final next = widget.date.plusDays(1);
    final today = EntryTime.now(ref.read(clockProvider)).localDate;
    return next.isAfter(today) ? today : next;
  }

  /// The meal a copy lands in: the chosen one, else a default. On today the
  /// day is the same as the source's, so the default is the next meal by
  /// order (the same meal would be refused); on a past day it is the same
  /// meal, on the next day. A source without a meal (the "Other" section)
  /// starts on the first meal.
  String? _targetSlot(LiveMeal live) {
    final slots = movableSlots(live.slots);
    // Pick the default once; later removal requires an explicit new choice.
    if (!_targetInitialised && live.slots.isNotEmpty) {
      _targetInitialised = true;
      final source = widget.section.slot;
      _toSlotId = source == null
          ? slots.firstOrNull?.id
          : widget.date == _today
          ? slots
                    .where((s) => s.sortOrder > source.sortOrder)
                    .firstOrNull
                    ?.id ??
                source.id
          : source.id;
    }
    if (!slots.any((s) => s.id == _toSlotId)) _toSlotId = null;
    return _toSlotId;
  }

  Future<void> _pickDay() async {
    final today = _today;
    final picked = await showFbDatePicker(
      context,
      initialDate: DateTime(_toDate.year, _toDate.month, _toDate.day),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _toDate = LocalDate(picked.year, picked.month, picked.day);
      _failure = null;
    });
  }

  Future<void> _pickSlot(LiveMeal live) async {
    final l10n = context.l10n;
    final target = _targetSlot(live);
    final chosen = await showFbSheet<MealSlot>(
      context,
      title: l10n.diaryCopySlotTitle,
      builder: (sheet) => Consumer(
        builder: (context, ref, _) => MoveToSlotList(
          slots: movableSlots(ref.watch(liveSlotsProvider).value ?? live.slots),
          currentSlotId: target ?? '',
          onPick: (slot) => Navigator.of(sheet).pop(slot),
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    setState(() {
      _toSlotId = chosen.id;
      _failure = null;
    });
  }

  Future<void> _copy(LiveMeal live, String? slotId) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    final section = live.section;
    // The overall day label is built from today as it is now.
    final today = _today;
    final toDate = _toDate;
    setState(() => _saving = true);
    final outcome = await ref
        .read(diaryActionsControllerProvider.notifier)
        .copyMeal(
          section,
          toDate,
          toSlotId: slotId == section.slot?.id ? null : slotId,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (outcome) {
      case DiaryActionFailed(:final reason):
        setState(() => _failure = reason);
      case DiaryActionUnchanged():
        nav.pop();
      case DiaryActionDone(:final args):
        nav.pop();
        if (host.mounted) {
          reportDiaryOutcome(
            host,
            outcome,
            () => host.l10n.diaryMealCopied(
              args['count']! as int,
              dayLabel(host, toDate, today),
            ),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) => LiveMealBuilder(
    opened: widget.section,
    date: widget.date,
    builder: _content,
  );

  Widget _content(BuildContext context, LiveMeal live) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final slotId = _targetSlot(live);
    final slot = live.slots.where((s) => s.id == slotId).firstOrNull;
    final same = _toDate == widget.date && slotId == widget.section.slot?.id;
    final canCopy = live.usable && !same && !_saving && slotId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        StaleMealBanner(live: live),
        Text(
          l10n.diaryMealSummary(
            mealEntries(live.section).length,
            mealKcal(live.section),
          ),
          style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
        ),
        Wrap(
          spacing: FbSpace.s2,
          runSpacing: FbSpace.s2,
          children: [
            FbChoiceChip(
              label: l10n.diaryCopyDay,
              value: dayLabel(context, _toDate, _today),
              onTap: _pickDay,
            ),
            FbChoiceChip(
              label: l10n.diaryChipMeal,
              value: slot == null ? null : slotLabel(l10n, slot),
              onTap: () => _pickSlot(live),
            ),
          ],
        ),
        if (same || slotId == null)
          Text(
            l10n.diaryCopyChoose,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
        if (_failure == DiaryActionFailure.slotRemoved)
          FbInlineBanner(
            kind: FbInlineBannerKind.info,
            message: l10n.diarySlotRemoved,
          )
        else if (_failure == DiaryActionFailure.invalid)
          FbInlineBanner(
            kind: FbInlineBannerKind.error,
            message: l10n.diaryActionFailed,
          )
        else if (_failure != null)
          FbInlineBanner(
            kind: FbInlineBannerKind.info,
            message: l10n.diaryMealChangedCopy,
          ),
        FbButton.primary(
          label: l10n.diaryCopyButton,
          expand: true,
          onPressed: canCopy ? () => _copy(live, slotId) : null,
        ),
      ],
    );
  }
}
