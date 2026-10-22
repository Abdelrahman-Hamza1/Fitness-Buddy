import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/foods/application/food_search_controller.dart';
import 'package:fb_mobile/features/foods/application/food_search_row.dart';
import 'package:fb_mobile/features/foods/presentation/food_result_row.dart';
import 'package:fb_mobile/features/foods/presentation/food_sheet_entry.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the amount flow for a tapped result; see [openFoodSheet].
typedef FoodPicked = void Function(BuildContext context, FoodPick pick);

/// The add-food search (FD-020, FD-021, FD-023): one box, results as you
/// type from the offline pack and your own history, recent foods while the
/// box is empty. Tapping a result opens the food sheet.
class FoodSearchScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [date] and [slotId] (both optional, see
  /// `FoodSearchRoute`). [onPick] defaults to the food sheet.
  const new({
    this.date,
    this.slotId,
    this.onPick = openFoodSheet,
    @visibleForTesting this.initialQuery = '',
    super.key,
  });

  /// The diary day to add to; null for today.
  final LocalDate? date;

  /// The meal slot to add to; null to choose by the time of day.
  final String? slotId;

  /// Called with the tapped result.
  final FoodPicked onPick;

  /// The text in the search box when the screen opens (tests and goldens).
  final String initialQuery;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  late final _text = TextEditingController(text: widget.initialQuery);

  @override
  void initState() {
    super.initState();
    // Recent foods for the empty box. Providers can't change while the tree
    // builds, so the first search starts after the first frame.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _search(_text.text);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _search(String text) =>
      ref.read(foodSearchControllerProvider.notifier).setQuery(text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(foodSearchControllerProvider);
    final results = state.results;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.foodSearchTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: FbSpace.s4,
              vertical: FbSpace.s2,
            ),
            child: FbSearchField(
              controller: _text,
              hint: l10n.foodSearchHint,
              autofocus: true,
              onChanged: _search,
            ),
          ),
          if (results != null && !results.packReady && results.rows.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: FbSpace.s4,
                vertical: FbSpace.s2,
              ),
              child: FbInlineBanner(
                kind: FbInlineBannerKind.info,
                message: l10n.foodSearchPackNotReady,
              ),
            ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: FbSpace.s4,
                vertical: FbSpace.s2,
              ),
              child: FbInlineBanner(
                kind: FbInlineBannerKind.error,
                message: l10n.foodSearchFailed,
                actionLabel: l10n.foodTryAgain,
                onAction: () => _search(_text.text),
              ),
            ),
          Expanded(
            child: results == null
                ? const SizedBox.shrink()
                : _Results(
                    // The rows are shown under the query they answer, so a
                    // newer search never relabels them while it runs.
                    query: (state.resultsFor ?? '').trim(),
                    packReady: results.packReady,
                    carried: results.carried,
                    rows: results.rows,
                    date: widget.date,
                    slotId: widget.slotId,
                    onPick: widget.onPick,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const new({
    required this.query,
    required this.packReady,
    required this.carried,
    required this.rows,
    required this.date,
    required this.slotId,
    required this.onPick,
  });

  final String query;
  final bool packReady;
  final ParsedAmount? carried;
  final List<FoodSearchRow> rows;
  final LocalDate? date;
  final String? slotId;
  final FoodPicked onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (rows.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: !packReady
                ? FbEmptyState(
                    icon: FbIcons.search,
                    title: l10n.foodSearchNotReadyTitle,
                    message: l10n.foodSearchNotReadyMessage,
                  )
                : query.isEmpty
                ? FbEmptyState(
                    icon: FbIcons.search,
                    title: l10n.foodSearchEmptyTitle,
                    message: l10n.foodSearchEmptyMessage,
                  )
                : FbEmptyState(
                    icon: FbIcons.search,
                    title: l10n.foodSearchNoMatchTitle(query),
                    message: l10n.foodSearchNoMatchMessage,
                  ),
          ),
        ],
      );
    }
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (query.isEmpty) FbSectionHeader(title: l10n.foodSearchRecent),
        for (final row in rows)
          FoodResultRow(
            key: ValueKey(row.identity),
            row: row,
            onTap: () {
              FocusScope.of(context).unfocus();
              onPick(
                context,
                FoodPick(
                  row: row,
                  date: date,
                  slotId: slotId,
                  carried: carried,
                ),
              );
            },
          ),
      ],
    );
  }
}
