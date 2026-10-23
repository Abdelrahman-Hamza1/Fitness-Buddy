import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/application/day_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The entries of [section] in the order shown, group members included.
List<DiaryEntry> mealEntries(SlotSection section) => [
  for (final item in section.items)
    ...switch (item) {
      EntryItem(:final entry) => [entry],
      GroupItem(:final members) => members,
    },
];

/// What a copy or save depends on: every entry and dish group of [section]
/// with its version, and which groups an entries-source copy takes along
/// (a member deleted in another meal changes that without touching this
/// meal's rows). Two sections with the same stamp are the same source.
String mealStamp(SlotSection section) => [
  for (final entry in mealEntries(section)) '${entry.id}@${entry.version}',
  for (final item in section.items)
    if (item is GroupItem) 'g:${item.group.id}@${item.group.version}',
  for (final id in section.entryCopyGroupIds.toList()..sort()) 'copy:$id',
].join(',');

/// The calories of [section] as the meal's summary line shows them.
int mealKcal(SlotSection section) => DisplayRounding.kcal(section.totals.kcal);

/// How an open copy or save sheet's meal compares with the stored one.
final class LiveMeal {
  /// Creates the view.
  const new({
    required this.section,
    required this.slots,
    required this.stale,
    required this.gone,
    required this.reload,
  });

  /// The meal as the sheet last took it; commands are built from it.
  final SlotSection section;

  /// The day's meals, for the copy target.
  final List<MealSlot> slots;

  /// The stored meal differs from [section] (an item was added, edited,
  /// moved or deleted): copying or saving would be refused.
  final bool stale;

  /// Every item of the meal is gone.
  final bool gone;

  /// Takes over the stored meal. What the user chose or typed stays.
  final VoidCallback reload;

  /// Whether the meal has nothing left to copy or save.
  bool get empty => gone || section.items.isEmpty;

  /// Whether Copy or Save may be offered.
  bool get usable => !stale && !empty;
}

/// Keeps a meal sheet honest about its source (A08 D12(4)): it holds the
/// day of the meal and compares the stored meal with the one it opened on.
class LiveMealBuilder extends ConsumerStatefulWidget {
  /// Creates the wrapper around [builder] for [opened] on [date].
  const new({
    required this.opened,
    required this.date,
    required this.builder,
    super.key,
  });

  /// The meal as the sheet was opened.
  final SlotSection opened;

  /// Its day.
  final LocalDate date;

  /// Builds the sheet's content.
  final Widget Function(BuildContext context, LiveMeal live) builder;

  @override
  ConsumerState<LiveMealBuilder> createState() => _LiveMealBuilderState();
}

class _LiveMealBuilderState extends ConsumerState<LiveMealBuilder> {
  late SlotSection _base = widget.opened;

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(dayViewProvider(widget.date)).value;
    final stored = view?.layout.sections
        .where((s) => s.key == _base.key)
        .firstOrNull;
    final gone =
        view != null && stored == null && mealEntries(_base).isNotEmpty;
    final stale = stored != null && mealStamp(stored) != mealStamp(_base);
    return widget.builder(
      context,
      LiveMeal(
        section: _base,
        slots: view?.raw.slots ?? const [],
        stale: stale,
        gone: gone,
        reload: () {
          if (stored != null) setState(() => _base = stored);
        },
      ),
    );
  }
}

/// The calm notice for a meal that changed under an open sheet, with Reload.
class StaleMealBanner extends StatelessWidget {
  /// Creates the notice for [live].
  const new({required this.live, super.key});

  /// The meal's state.
  final LiveMeal live;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (live.empty) {
      return FbInlineBanner(
        kind: FbInlineBannerKind.info,
        message: l10n.diaryMealEmpty,
      );
    }
    if (!live.stale) return const SizedBox.shrink();
    return FbInlineBanner(
      kind: FbInlineBannerKind.info,
      message: l10n.diaryMealChanged,
      actionLabel: l10n.diaryReload,
      onAction: live.reload,
    );
  }
}
