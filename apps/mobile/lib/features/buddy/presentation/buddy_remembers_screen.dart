import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/ui/settings_page.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/buddy/application/buddy_memory.dart';
import 'package:fb_mobile/features/buddy/application/buddy_summary_view.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/record_proposal_card.dart'
    show memoryValueText;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

/// "Buddy remembers" (AI-082, AI-165, A67 D14): everything Buddy remembers
/// in plain words, grouped, each forgettable with an Undo, and the summary
/// of older chat with Clear. Nothing is remembered in secret.
class BuddyRemembersScreen extends ConsumerWidget {
  /// The screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(buddySummaryTextProvider).value;
    final items = ref.watch(buddyMemoryItemsProvider).value ?? const [];
    final groups = <String, List<MemoryItem>>{
      l10n.buddyMemoryGroupDefaults: [
        for (final i in items)
          if (i.kind == MemoryKinds.defaultValue) i,
      ],
      l10n.buddyMemoryGroupPortions: [
        for (final i in items)
          if (i.kind == MemoryKinds.portion) i,
      ],
      l10n.buddyMemoryGroupNames: [
        for (final i in items)
          if (i.kind == MemoryKinds.alias ||
              i.kind == MemoryKinds.brand ||
              i.kind == MemoryKinds.nickname)
            i,
      ],
      l10n.buddyMemoryGroupLearned: [
        for (final i in items)
          if (i.kind == MemoryKinds.habit) i,
      ],
      l10n.buddyMemoryGroupTips: [
        for (final i in items)
          if (i.kind == MemoryKinds.nudge) i,
      ],
    };
    final known = {
      MemoryKinds.defaultValue,
      MemoryKinds.portion,
      MemoryKinds.alias,
      MemoryKinds.brand,
      MemoryKinds.nickname,
      MemoryKinds.habit,
      MemoryKinds.nudge,
    };
    final other = [
      for (final i in items)
        if (!known.contains(i.kind)) i,
    ];
    return SettingsPage(
      title: l10n.buddyRemembersTitle,
      children: [
        FbRowGroup(
          title: l10n.buddyMemorySummary,
          children: [
            FbListRow(
              title: summary ?? l10n.buddyRemembersEmpty,
              trailingAction: summary == null
                  ? null
                  : FbButton.text(
                      label: l10n.buddyRemembersClear,
                      onPressed: () => unawaited(_clearSummary(context, ref)),
                    ),
            ),
          ],
        ),
        settingsGroupGap,
        if (items.isEmpty)
          FbRowGroup(children: [FbListRow(title: l10n.buddyMemoryEmpty)]),
        for (final MapEntry(key: title, value: list)
            in <MapEntry<String, List<MemoryItem>>>[
              ...groups.entries,
              if (other.isNotEmpty) MapEntry(l10n.buddyRemembersTitle, other),
            ])
          if (list.isNotEmpty) ...[
            FbRowGroup(
              title: title,
              children: [
                for (final item in list)
                  FbListRow(
                    title: _line(context, item),
                    trailingAction: FbButton.text(
                      label: l10n.buddyMemoryForget,
                      onPressed: () => unawaited(_forget(context, ref, item)),
                    ),
                  ),
              ],
            ),
            settingsGroupGap,
          ],
        if (items.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FbButton.destructive(
              label: l10n.buddyMemoryClearAll,
              onPressed: () => unawaited(_clearAll(context, ref)),
            ),
          ),
      ],
    );
  }

  /// [item] in plain words: "rice: weighed raw", "my bowl: 350 g".
  static String _line(BuildContext context, MemoryItem item) {
    final l10n = context.l10n;
    String words(String s) =>
        s.replaceAll('_', ' ').replaceAll(RegExp('^[a-z]+:'), '');
    switch (item.kind) {
      case MemoryKinds.defaultValue || MemoryKinds.habit:
        final [dimension, ...rest] = item.key.split(':');
        final what = switch (dimension) {
          'state' => l10n.buddyMemoryDimensionState,
          'fat' => l10n.buddyMemoryDimensionFat,
          'variant' => l10n.buddyMemoryDimensionVariant,
          'portion' => l10n.buddyMemoryDimensionPortion,
          _ => dimension,
        };
        return l10n.recordMemoryDefault(
          words(rest.join(':')),
          what,
          memoryValueText(item.value),
        );
      case MemoryKinds.nudge:
        final day = DateTime.tryParse(item.value);
        return l10n.buddyMemoryTip(
          words(item.key),
          day == null
              ? item.value
              : DateFormat.yMMMd(l10n.localeName).format(day),
        );
      default:
        return l10n.recordMemoryLine(words(item.key), item.value);
    }
  }

  Future<void> _forget(
    BuildContext context,
    WidgetRef ref,
    MemoryItem item,
  ) async {
    final message = context.l10n.buddyMemoryForgotten;
    final entry = await ref.read(buddyMemoryActionsProvider).forget(item);
    if (entry != null && context.mounted) {
      showUndoFeedback(context, message: message, undoEntryId: entry);
    }
  }

  Future<bool> _confirm(
    BuildContext context,
    String body,
    String action,
  ) async {
    final l10n = context.l10n;
    return await showFbSheet<bool>(
          context,
          title: l10n.buddyRemembersTitle,
          builder: (context) => Text(body),
          actionsBuilder: (context) => Row(
            spacing: FbSpace.s3,
            children: [
              Expanded(
                child: FbButton.secondary(
                  label: l10n.buddyCancel,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              Expanded(
                child: FbButton.destructive(
                  label: action,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    if (!await _confirm(
      context,
      l10n.buddyMemoryClearAllBody,
      l10n.buddyMemoryClearAll,
    )) {
      return;
    }
    final entry = await ref.read(buddyMemoryActionsProvider).clearAll();
    if (entry != null && context.mounted) {
      showUndoFeedback(
        context,
        message: l10n.buddyMemoryForgotten,
        undoEntryId: entry,
      );
    }
  }

  Future<void> _clearSummary(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    if (!await _confirm(
      context,
      l10n.buddyRemembersClearBody,
      l10n.buddyRemembersClear,
    )) {
      return;
    }
    await ref.read(buddyThreadControllerProvider.notifier).clearSummary();
  }
}
