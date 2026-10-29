import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/today/presentation/today_numbers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// One day of the pager (HM-009): the day's header (the numbers, then the
/// weight card) on top, then the meals. A flat
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
    return CustomScrollView(
      // Several pages exist while swiping: none takes the primary controller.
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
              ),
              EmptyHintRow(:final isToday) => EmptyDayHint(
                key: key,
                isToday: isToday,
              ),
              SlotHeaderRow(:final section, :final expanded) => SlotHeaderTile(
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
    );
  }
}

/// The top of a day page, as an ordered list (A14 §3.5): the day's numbers →
/// [A22: the to-confirm strip] → the weight card → [A37: the workout hint].
/// Later steps add one entry here instead of nesting widgets.
class _DayHeader extends StatelessWidget {
  const new({
    required this.date,
    required this.isToday,
    required this.totals,
    super.key,
  });

  final LocalDate date;
  final bool isToday;
  final Nutrients totals;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TodayNumbers(totals: totals),
      WeightCard(date: date, isToday: isToday),
    ],
  );
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
        FbSkeleton.box(width: 160, height: 56),
        SizedBox(height: FbSpace.s3),
        FbSkeleton.line(width: 240),
        SizedBox(height: FbSpace.s5),
        FbSkeleton.card(height: 56),
        SizedBox(height: FbSpace.s3),
        FbSkeleton.card(height: 56),
        SizedBox(height: FbSpace.s3),
        FbSkeleton.card(height: 56),
        SizedBox(height: FbSpace.s3),
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
