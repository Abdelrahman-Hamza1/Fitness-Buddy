import 'dart:async';

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
import 'package:fb_mobile/features/today/presentation/today_summary_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// One day of the pager (HM-009): the day's header (the numbers, then the
/// summary card) on top, then the meals. A flat
/// sliver list of [DayRow]s, so only the rows on screen are built. A day that
/// is not loaded yet shows meal skeletons; a prefetched one never does
/// (UX-051). Today and past days look the same.
///
/// Opening or closing a meal, a group or an entry's details (A57 D18, A16,
/// A17) grows the new rows in under the tapped one and lets the closed ones
/// shrink away over [FbMotion.local]; the tapped row never moves. Data
/// changes (log, delete, move) stay immediate.
class DayPage extends ConsumerStatefulWidget {
  /// Creates the page of [date]; [isToday] picks the empty-day wording.
  const new({required this.date, required this.isToday, super.key});

  /// The day.
  final LocalDate date;

  /// Whether the day is today.
  final bool isToday;

  @override
  ConsumerState<DayPage> createState() => _DayPageState();
}

/// A row on screen: its key, its row, and whether it is shrinking away.
typedef _Shown = ({Key key, DayRow row, bool exiting});

class _DayPageState extends ConsumerState<DayPage> {
  DiaryViewChoices? _lastChoices;
  List<_Shown> _shown = const [];
  final Set<Key> _exiting = {};
  Timer? _drop;

  @override
  void dispose() {
    _drop?.cancel();
    super.dispose();
  }

  /// [rows] plus the rows a disclosure just closed, each at its old place,
  /// and which rows it just opened.
  (List<_Shown>, Set<Key>) _withMotion(
    List<DayRow> rows,
    DiaryViewChoices choices,
  ) {
    final duration = FbMotion.localOf(context);
    final current = <_Shown>[
      for (final row in rows) (key: _keyOf(row), row: row, exiting: false),
    ];
    final now = {for (final s in current) s.key};
    final disclosed =
        _lastChoices != null &&
        !identical(choices, _lastChoices) &&
        duration > Duration.zero;
    _lastChoices = choices;
    var entering = const <Key>{};
    _exiting.removeAll(now);
    if (disclosed) {
      entering = now.difference({for (final s in _shown) s.key});
      final closed = [
        for (final s in _shown)
          if (!now.contains(s.key)) s.key,
      ];
      if (closed.isNotEmpty) {
        _exiting.addAll(closed);
        _drop?.cancel();
        _drop = Timer(duration, () {
          if (mounted) setState(_exiting.clear);
        });
      }
    }
    final combined = [...current];
    Key? previous;
    for (final s in _shown) {
      if (_exiting.contains(s.key)) {
        final at = previous == null
            ? 0
            : combined.indexWhere((c) => c.key == previous) + 1;
        combined.insert(at, (key: s.key, row: s.row, exiting: true));
      } else if (!now.contains(s.key)) {
        continue;
      }
      previous = s.key;
    }
    _shown = combined;
    return (combined, entering);
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.date;
    final isToday = widget.isToday;
    final view = ref.watch(dayViewProvider(date));
    final data = view.value;
    if (data == null) {
      return view.hasError
          ? _LoadFailed(onRetry: () => ref.invalidate(dayProvider(date)))
          : const _DaySkeleton();
    }
    final choices = ref.watch(diaryViewStateProvider);
    final (rows, entering) = _withMotion(
      DayRows.of(data.layout, choices, isToday: isToday, mark: data.raw.mark),
      choices,
    );
    final indexOfKey = {for (final (i, s) in rows.indexed) s.key: i};
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
              final (:key, :row, :exiting) = rows[i];
              final content = switch (row) {
                NumbersRow(:final intake) => _DayHeader(
                  key: key,
                  date: date,
                  isToday: isToday,
                  intake: intake,
                  incomplete: data.raw.mark?.incomplete ?? false,
                ),
                EmptyHintRow(:final isToday) => EmptyDayHint(isToday: isToday),
                DayEstimatePromptRow(:final mark) => DayEstimatePrompt(
                  date: date,
                  mark: mark,
                ),
                DayEstimateRow(:final mark, :final superseded) =>
                  DayEstimateTile(mark: mark, superseded: superseded),
                SlotHeaderRow(:final section, :final expanded) =>
                  SlotHeaderTile(
                    section: section,
                    date: date,
                    expanded: expanded,
                  ),
                SlotMacrosRow(:final section) => SlotMacrosLine(
                  section: section,
                ),
                GroupHeaderRow(:final item, :final expanded) => DishGroupTile(
                  item: item,
                  expanded: expanded,
                ),
                EntryRow(:final entry) => DiaryEntryTile(
                  entry: entry,
                  slots: slots,
                  expanded: _isOpen(choices, entry),
                ),
                GroupMemberRow(:final entry) => DiaryEntryTile(
                  entry: entry,
                  slots: slots,
                  expanded: _isOpen(choices, entry),
                  indented: true,
                ),
                EntryDetailsRow(:final entry) => EntryDetailsPanel(
                  entry: entry,
                  slots: slots,
                ),
              };
              // The header never enters or leaves (and isn't clipped).
              if (row is NumbersRow) return content;
              return FbReveal(
                key: key,
                visible: !exiting,
                appearOnMount: entering.contains(key),
                child: content,
              );
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

/// The calories card with the weight | workout line (D-093), then the
/// Ramadan proposal and not-fasting note, incomplete-day note, ready-scans
/// hint, account banner and sync line, in that order. The notes share one
/// [FbSizeFade], so one appearing or going grows or shrinks the region
/// smoothly instead of jumping the meals (A57 A09).
class _DayHeader extends StatelessWidget {
  const new({
    required this.date,
    required this.isToday,
    required this.intake,
    this.incomplete = false,
    super.key,
  });

  final LocalDate date;
  final bool isToday;
  final IntakeTotals intake;
  final bool incomplete;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TodaySummaryCard(date: date, isToday: isToday, intake: intake),
      FbSizeFade(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isToday) const RamadanProposalCard(),
            _NotFastingNote(date: date),
            if (incomplete) _IncompleteNote(date: date),
            if (isToday) const ReadyScansTodayHint(),
            if (isToday) const AccountTodayBanner(),
            if (isToday) const SyncTodayLine(),
          ],
        ),
      ),
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
  DayEstimatePromptRow() => 'estimate-prompt',
  DayEstimateRow() => 'day-estimate',
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
