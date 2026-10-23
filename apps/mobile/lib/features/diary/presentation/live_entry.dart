import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/application/diary_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How an open edit sheet's item compares with the stored one (A08 D12(4)).
enum EntryFreshness {
  /// Saving works: the item is as opened, or it only moved to another meal,
  /// day or time.
  fresh,

  /// The item was deleted: Save is disabled.
  removed,

  /// The item's food, amount or values changed: Save would conflict until the
  /// sheet reloads.
  changed,
}

/// The item an edit sheet works on, and how it stands now.
final class LiveEntry {
  /// Creates the view.
  const new({
    required this.entry,
    required this.freshness,
    required this.reload,
  });

  /// The item to compute and save with, at the version a save must expect.
  final DiaryEntry entry;

  /// How [entry] compares with the stored item.
  final EntryFreshness freshness;

  /// Takes over the stored item (only meaningful when the freshness is
  /// `changed`). What the user typed stays: it lives in the sheet, not here.
  final VoidCallback reload;

  /// Whether Save may be offered.
  bool get canSave => freshness == EntryFreshness.fresh;
}

/// Whether [a] and [b] hold the same food, amount and values, whatever
/// their meal, day, time and version.
bool sameEditableContent(DiaryEntry a, DiaryEntry b) =>
    a.food == b.food &&
    a.amount == b.amount &&
    a.snapshot == b.snapshot &&
    a.editedByUser == b.editedByUser;

/// Keeps an edit sheet honest about its item (A08 D12(4)).
///
/// The sheet opens on [opened] and keeps that version. It watches the item by
/// ID (`watchEntry`), which follows it across meals and days:
/// - deleted: [EntryFreshness.removed];
/// - moved or re-timed only: still usable, saving expects the new version;
/// - food, amount or values differ: [EntryFreshness.changed], and `reload`
///   rebases on the stored item without touching the sheet's typed value.
class LiveEntryBuilder extends ConsumerStatefulWidget {
  /// Creates the wrapper around [builder].
  const new({required this.opened, required this.builder, super.key});

  /// The item as the sheet was opened.
  final DiaryEntry opened;

  /// Builds the sheet's content.
  final Widget Function(BuildContext context, LiveEntry live) builder;

  @override
  ConsumerState<LiveEntryBuilder> createState() => _LiveEntryBuilderState();
}

class _LiveEntryBuilderState extends ConsumerState<LiveEntryBuilder> {
  late DiaryEntry _base = widget.opened;

  @override
  Widget build(BuildContext context) {
    final stored = ref.watch(entryProvider(_base.id));
    final LiveEntry live;
    if (stored case AsyncData(value: final current)) {
      if (current == null) {
        live = LiveEntry(
          entry: _base,
          freshness: EntryFreshness.removed,
          reload: () {},
        );
      } else if (current.version == _base.version) {
        live = LiveEntry(
          entry: current,
          freshness: EntryFreshness.fresh,
          reload: () {},
        );
      } else if (sameEditableContent(_base, current)) {
        live = LiveEntry(
          entry: current,
          freshness: EntryFreshness.fresh,
          reload: () {},
        );
      } else {
        live = LiveEntry(
          entry: _base,
          freshness: EntryFreshness.changed,
          reload: () => setState(() => _base = current),
        );
      }
    } else {
      live = LiveEntry(
        entry: _base,
        freshness: EntryFreshness.fresh,
        reload: () {},
      );
    }
    return widget.builder(context, live);
  }
}

/// The calm notice for a removed or changed item, with Reload for a changed
/// one. Nothing for a fresh one.
class StaleEntryBanner extends StatelessWidget {
  /// Creates the notice for an item that is [freshness]; [onReload] is the
  /// Reload action of a changed one.
  const new({required this.freshness, required this.onReload, super.key});

  /// The item's state.
  final EntryFreshness freshness;

  /// Takes over the stored item.
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (freshness) {
      EntryFreshness.fresh => const SizedBox.shrink(),
      EntryFreshness.removed => FbInlineBanner(
        kind: FbInlineBannerKind.info,
        message: l10n.diaryEntryRemoved,
      ),
      EntryFreshness.changed => FbInlineBanner(
        kind: FbInlineBannerKind.info,
        message: l10n.diaryEntryChangedStale,
        actionLabel: l10n.diaryReload,
        onAction: onReload,
      ),
    };
  }
}
