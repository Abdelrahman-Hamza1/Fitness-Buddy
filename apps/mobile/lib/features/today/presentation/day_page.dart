import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart' show ReadyScansTodayHint;
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:fb_mobile/features/sync/sync.dart';
import 'package:fb_mobile/features/today/presentation/today_numbers.dart'
    show EmptyDayHint;
import 'package:fb_mobile/features/today/presentation/today_slide_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// One day of the pager (HM-009): the day's header (the numbers, then the
/// summary card) on top, then the meals. A flat
/// sliver list of [DayRow]s, so only the rows on screen are built. A day that
/// is not loaded yet shows meal skeletons; a prefetched one never does
/// (UX-051). Today and past days look the same.
class DayPage extends ConsumerWidget {
  /// Creates the page of [date]; [isToday] picks the empty-day wording.
  const new({required this.date, required this.isToday, super.key});

  /// The day.
  final LocalDate date;

  /// Whether the day is today.
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(dayViewProvider(date));
    final data = view.value;
    if (data == null) {
      return view.hasError
          ? _LoadFailed(onRetry: () => ref.invalidate(dayProvider(date)))
          : const _DaySkeleton();
    }
    final choices = ref.watch(diaryViewStateProvider);
    final rows = DayRows.of(data.layout, choices, isToday: isToday);
    final keys = [for (final row in rows) _keyOf(row)];
    final indexOfKey = {for (final (i, key) in keys.indexed) key: i};
    final slots = data.raw.slots;
    // A re-tap of the Today tab scrolls the page to the top (A45 D13). Several
    // pages exist while swiping: none takes the primary controller, so each
    // owns one (all mounted pages scroll, which is harmless).
    return ScrollToTopOnTabReselect.builder(
      tab: AppTab.today,
      builder: (context, controller) => CustomScrollView(
        controller: controller,
        primary: false,
        slivers: [
          SliverList.builder(
            itemCount: rows.length,
            findChildIndexCallback: (key) => indexOfKey[key],
            itemBuilder: (context, i) {
              final key = keys[i];
              return switch (rows[i]) {
                NumbersRow(:final totals) => _DayHeader(
                  key: key,
                  date: date,
                  isToday: isToday,
                  totals: totals,
                  incomplete: data.raw.mark?.incomplete ?? false,
                ),
                EmptyHintRow(:final isToday) => EmptyDayHint(
                  key: key,
                  isToday: isToday,
                ),
                SlotHeaderRow(:final section, :final expanded) =>
                  SlotHeaderTile(
                    key: key,
                    section: section,
                    date: date,
                    expanded: expanded,
                  ),
                SlotMacrosRow(:final section) => SlotMacrosLine(
                  key: key,
                  section: section,
                ),
                GroupHeaderRow(:final item, :final expanded) => DishGroupTile(
                  key: key,
                  item: item,
                  expanded: expanded,
                ),
                EntryRow(:final entry) => DiaryEntryTile(
                  key: key,
                  entry: entry,
                  slots: slots,
                  expanded: _isOpen(choices, entry),
                ),
                GroupMemberRow(:final entry) => DiaryEntryTile(
                  key: key,
                  entry: entry,
                  slots: slots,
                  expanded: _isOpen(choices, entry),
                  indented: true,
                ),
                EntryDetailsRow(:final entry) => EntryDetailsPanel(
                  key: key,
                  entry: entry,
                  slots: slots,
                ),
              };
            },
          ),
          const SliverPadding(
            padding: EdgeInsetsDirectional.only(bottom: FbSpace.s5),
          ),
        ],
      ),
    );
  }
}

/// The summary card, Ramadan proposal and not-fasting note, incomplete-day
/// note, ready-scans hint, account banner and sync line, in that order.
class _DayHeader extends StatelessWidget {
  const new({
    required this.date,
    required this.isToday,
    required this.totals,
    this.incomplete = false,
    super.key,
  });

  final LocalDate date;
  final bool isToday;
  final Nutrients totals;
  final bool incomplete;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TodaySlideCard(date: date, isToday: isToday, totals: totals),
      if (isToday) const RamadanProposalCard(),
      _NotFastingNote(date: date),
      if (incomplete) _IncompleteNote(date: date),
      if (isToday) const ReadyScansTodayHint(),
      if (isToday) const AccountTodayBanner(),
      if (isToday) const SyncTodayLine(),
    ],
  );
}

/// A day marked incomplete says so, with Count this day again (DY-004).
class _IncompleteNote extends StatelessWidget {
  const new({required this.date});

  final LocalDate date;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      key: const ValueKey('today-incomplete-note'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        FbSpace.s4,
        0,
        FbSpace.s4,
        FbDensity.cardGap,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: FbSpace.s2,
        children: [
          Text(
            l10n.todayIncompleteNote,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
          FbButton.text(
            key: const ValueKey('today-count-again'),
            label: l10n.diaryCountAgain,
            onPressed: () => markDayWithUndo(context, date, incomplete: false),
          ),
        ],
      ),
    );
  }
}

/// A Ramadan day marked not fasting says so, with Fasting today (LC-034).
class _NotFastingNote extends ConsumerWidget {
  const new({required this.date});

  final LocalDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(daySlotsProvider(date)).value;
    if (slots == null || slots.ramadan == null || !slots.notFasting) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      key: const ValueKey('today-not-fasting-note'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        FbSpace.s4,
        0,
        FbSpace.s4,
        FbDensity.cardGap,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: FbSpace.s2,
        children: [
          Text(
            l10n.ramadanNotFastingNote,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
          FbButton.text(
            key: const ValueKey('today-fasting-again'),
            label: l10n.ramadanMarkFasting,
            onPressed: () =>
                markNotFastingWithUndo(context, date, notFasting: false),
          ),
        ],
      ),
    );
  }
}

bool _isOpen(DiaryViewChoices choices, DiaryEntry entry) =>
    choices.expandedEntry == (date: entry.localDate, id: entry.id);

/// A stable identity per row, so a removed row never hands its state to its
/// neighbour.
Key _keyOf(DayRow row) => ValueKey(switch (row) {
  NumbersRow() => 'numbers',
  EmptyHintRow() => 'empty',
  SlotHeaderRow(:final section) => 'slot:${section.key}',
  SlotMacrosRow(:final section) => 'macros:${section.key}',
  GroupHeaderRow(:final item, :final slotKey) =>
    'group:$slotKey:${item.group.id}',
  EntryRow(:final entry) => 'entry:${entry.id}',
  GroupMemberRow(:final entry) => 'entry:${entry.id}',
  EntryDetailsRow(:final entry) => 'details:${entry.id}',
});

class _DaySkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
    primary: false,
    physics: NeverScrollableScrollPhysics(),
    padding: EdgeInsetsDirectional.all(FbSpace.s4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FbSkeleton.box(width: 160, height: FbDensity.displayLineHeight),
        SizedBox(height: FbSpace.s3),
        FbSkeleton.line(width: 240),
        SizedBox(height: FbSpace.s5),
        FbSkeleton.card(height: 56),
        SizedBox(height: FbDensity.cardGap),
        FbSkeleton.card(height: 56),
        SizedBox(height: FbDensity.cardGap),
        FbSkeleton.card(height: 56),
        SizedBox(height: FbDensity.cardGap),
        FbSkeleton.card(height: 56),
      ],
    ),
  );
}

class _LoadFailed extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.all(FbSpace.s4),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: FbInlineBanner(
          kind: FbInlineBannerKind.error,
          message: l10n.diaryLoadFailed,
          actionLabel: l10n.foodTryAgain,
          onAction: onRetry,
        ),
      ),
    );
  }
}
