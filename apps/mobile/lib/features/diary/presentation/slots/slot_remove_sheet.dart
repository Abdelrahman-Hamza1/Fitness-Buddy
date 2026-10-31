import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/diary/application/slot_actions.dart';
import 'package:fb_mobile/features/diary/application/slot_providers.dart';
import 'package:fb_mobile/features/diary/presentation/slots/slot_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the remove sheet for [record]; resolves to whether the meal was
/// removed (A10 D11).
Future<bool?> showSlotRemoveSheet(BuildContext context, SlotRecord record) =>
    showFbStatefulSheet<bool>(
      context,
      builder: (_) => SlotRemoveSheet(record: record),
    );

/// The meal to move items to when none was picked: the one without a time
/// window (the catch-all), else the next meal in order, else the previous
/// one. Null when there is no other meal.
SlotRecord? defaultDestination(SlotRecord source, List<SlotRecord> active) {
  final others = [
    for (final r in active)
      if (r.slot.id != source.slot.id) r,
  ];
  if (others.isEmpty) return null;
  final windowless = others.where((r) => r.slot.window == null).firstOrNull;
  if (windowless != null) return windowless;
  final next = others
      .where((r) => r.slot.sortOrder > source.slot.sortOrder)
      .firstOrNull;
  return next ?? others.last;
}

/// What removing a meal does, and where its items go (DY-010, A10 D11,
/// PA1). An empty meal just goes. A meal with items says how many, on how
/// many days, live, and asks for the meal to move them to; the command
/// carries exactly the items and the destination shown, so a change since
/// refuses with nothing removed.
class SlotRemoveSheet extends ConsumerStatefulWidget {
  /// Creates the sheet for [record], as rendered when it opened.
  const new({required this.record, super.key});

  /// The meal to remove.
  final SlotRecord record;

  @override
  ConsumerState<SlotRemoveSheet> createState() => _SlotRemoveSheetState();
}

class _SlotRemoveSheetState extends ConsumerState<SlotRemoveSheet> {
  /// The destination as rendered when it was picked (or defaulted): its
  /// version travels with the command, so a rename after the pick refuses.
  SlotRecord? _destination;
  late SlotRecord _opened = widget.record;
  bool _removing = false;
  String? _failure;

  String get _id => widget.record.slot.id;

  Future<void> _remove(
    BuildContext context, {
    required SlotRecord source,
    required SlotContents contents,
    required SlotRecord? destination,
  }) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final nav = Navigator.of(context);
    final l10n = context.l10n;
    final sourceName = slotLabel(l10n, source.slot);
    final targetName = destination == null
        ? null
        : slotLabel(l10n, destination.slot);
    final items = l10n.slotItemsCount(contents.entries.length);
    setState(() {
      _removing = true;
      _failure = null;
    });
    final outcome = await ref
        .read(slotActionsProvider.notifier)
        .removeSlot(source, shown: contents, moveTo: destination);
    if (mounted) setState(() => _removing = false);
    switch (outcome) {
      case SlotDone(:final undoEntryId):
        if (mounted) nav.pop(true);
        if (host.mounted) {
          showUndoFeedback(
            host,
            message: targetName == null
                ? host.l10n.slotRemovedMessage(sourceName)
                : host.l10n.slotRemovedMovedMessage(
                    sourceName,
                    items,
                    targetName,
                  ),
            undoEntryId: undoEntryId,
          );
        }
      case SlotUnchanged():
        break;
      case SlotFailed(:final reason, :final code):
        if (!mounted) return;
        setState(() {
          // What the user sees now becomes the base of the next try: the
          // same meal, at its current version.
          _destination = ref
              .read(slotRecordsProvider(widget.record.slot.mode))
              .value
              ?.where((r) => r.slot.active && r.slot.id == destination?.slot.id)
              .firstOrNull;
          _failure = switch ((reason, code)) {
            (SlotFailure.removed, _) => l10n.slotStaleRemoved,
            (SlotFailure.invalid, 'lastSlot') => l10n.slotKeepOne,
            (SlotFailure.invalid, 'badTarget' || 'slotNotEmpty') =>
              l10n.slotRemoveChanged,
            (SlotFailure.changed, _) => l10n.slotRemoveChanged,
            _ => l10n.diaryActionFailed,
          };
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recordsAsync = ref.watch(
      slotRecordsProvider(widget.record.slot.mode),
    );
    final records = recordsAsync.value;
    final contentsAsync = ref.watch(slotContentsProvider(_id));
    final contents = contentsAsync.value;
    final pending = ref.watch(
      slotActionsProvider.select((s) => s.contains(_id)),
    );
    final source = records?.where((r) => r.slot.id == _id).firstOrNull;
    final gone = records != null && (source == null || !source.slot.active);
    final changed = source != null && source.version != _opened.version;
    final active = [
      for (final r in records ?? const <SlotRecord>[])
        if (r.slot.active) r,
    ];
    final others = [
      for (final r in active)
        if (r.slot.id != _id) r,
    ];
    final isLast = records != null && !gone && others.isEmpty;
    // A destination that is no longer a usable meal is dropped; the default
    // is taken once, so its version is the one rendered.
    if (_destination != null &&
        !others.any((r) => r.slot.id == _destination!.slot.id)) {
      _destination = null;
    }
    if (source != null && !gone && others.isNotEmpty) {
      _destination ??= defaultDestination(source, active);
    }
    final loaded = source != null && contents != null && !gone;
    final empty = contents?.isEmpty ?? true;
    final name = slotLabel(l10n, (source ?? widget.record).slot);
    final destination = empty ? null : _destination;
    final itemsText = l10n.slotItemsCount(contents?.entries.length ?? 0);
    final daysText = l10n.slotDaysCount(contents?.dates.length ?? 0);
    final canRemove =
        loaded &&
        !isLast &&
        !_removing &&
        !pending &&
        (empty || destination != null);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: FbSheet(
        title: l10n.slotRemoveTitle(name),
        actions: FbButton.primary(
          label: empty ? l10n.slotRemoveButton : l10n.slotRemoveMoveButton,
          expand: true,
          onPressed: canRemove
              ? () => unawaited(
                  _remove(
                    context,
                    source: _opened,
                    contents: contents,
                    destination: destination,
                  ),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FbSpace.s3,
          children: [
            if (recordsAsync.hasError || contentsAsync.hasError)
              FbInlineBanner(
                kind: FbInlineBannerKind.error,
                message: l10n.mealTimesLoadFailed,
                actionLabel: l10n.mealTimesTryAgain,
                onAction: () {
                  ref
                    ..invalidate(slotRecordsProvider(widget.record.slot.mode))
                    ..invalidate(slotContentsProvider(_id));
                },
              ),
            if (gone)
              FbInlineBanner(
                kind: FbInlineBannerKind.info,
                message: l10n.slotStaleRemoved,
              )
            else if (changed)
              FbInlineBanner(
                kind: FbInlineBannerKind.info,
                message: l10n.slotStaleChanged,
                actionLabel: l10n.diaryReload,
                onAction: () => setState(() {
                  _opened = source;
                  _failure = null;
                }),
              ),
            if (!gone && isLast)
              Text(
                l10n.slotKeepOne,
                style: FbType.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else if (!gone && (contents == null || records == null))
              const FbSkeleton.line(height: 20)
            else if (!gone && empty)
              Text(l10n.slotRemoveEmpty(name))
            else if (!gone && contents != null) ...[
              Text(l10n.slotRemoveHasItems(name, itemsText, daysText)),
              FbOptionList<String>(
                selected: destination?.slot.id,
                options: [
                  for (final r in others)
                    FbOption(
                      value: r.slot.id,
                      label: slotLabel(l10n, r.slot),
                      subtitle: windowText(context, r.slot.window),
                    ),
                ],
                onSelected: _removing || pending
                    ? (_) {}
                    : (id) => setState(() {
                        _failure = null;
                        _destination = others.firstWhere(
                          (r) => r.slot.id == id,
                        );
                      }),
              ),
            ],
            if (_failure != null)
              FbInlineBanner(
                kind: FbInlineBannerKind.error,
                message: _failure!,
              ),
          ],
        ),
      ),
    );
  }
}
