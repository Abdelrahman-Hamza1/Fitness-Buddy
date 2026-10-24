import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/application/food_search_controller.dart';
import 'package:fb_mobile/features/foods/application/food_search_row.dart';
import 'package:fb_mobile/features/foods/application/new_food_prefill.dart';
import 'package:fb_mobile/features/foods/presentation/food_result_row.dart';
import 'package:fb_mobile/features/foods/presentation/food_sheet_entry.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the amount flow for a tapped result; see [openFoodSheet].
typedef FoodPicked = void Function(BuildContext context, FoodPick pick);

/// The most characters of a query the "Create …" label quotes.
const int _createQuoteMax = 24;

/// [query] as the "Create …" label quotes it: whole when short, else its
/// first characters and "…" (the form gets the whole query).
String createQuote(String query) {
  final chars = query.characters;
  return chars.length <= _createQuoteMax
      ? query
      : '${chars.take(_createQuoteMax - 1).toString().trimRight()}…';
}

/// The add-food search (FD-020, FD-021, FD-023): one box, results as you
/// type from the offline pack and your own history, recent foods while the
/// box is empty. Tapping a result opens the food sheet.
class FoodSearchScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [date] and [slotId] (both optional, see
  /// `FoodSearchRoute`). [onPick] defaults to the food sheet.
  const new({
    this.date,
    this.slotId,
    this.replace,
    this.onPick = openFoodSheet,
    @visibleForTesting this.initialQuery = '',
    super.key,
  });

  /// The diary day to add to; null for today.
  final LocalDate? date;

  /// The meal slot to add to; null to choose by the time of day.
  final String? slotId;

  /// The logged item whose food is replaced (change-food mode, A08 D7); null
  /// to add a new item.
  final VersionedId? replace;

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

  /// "Create … as your own food" (A09 D9): the query goes to the form
  /// through a one-shot provider, never through the URL (backlog #42).
  void _createFood(String query) {
    FocusScope.of(context).unfocus();
    ref.read(newFoodPrefillProvider.notifier).put(query);
    ref
        .read(appNavigatorProvider)
        .push(NewFoodFromSearchRoute(date: widget.date, slotId: widget.slotId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(foodSearchControllerProvider);
    final results = state.results;
    final replacing = widget.replace == null
        ? null
        : ref.watch(entryProvider(widget.replace!.id)).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.replace == null
              ? l10n.foodSearchTitle
              : l10n.foodSearchChangeTitle,
        ),
      ),
      body: Column(
        children: [
          // Change-food mode: which item gets the new food.
          if (replacing != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: FbSpace.s4,
                end: FbSpace.s4,
                top: FbSpace.s2,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.foodSearchReplacing(replacing.food.names.en),
                  style: FbType.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
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
                    replace: widget.replace,
                    onPick: widget.onPick,
                    // Changing a logged item's food picks an existing food.
                    onCreate: widget.replace == null ? _createFood : null,
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
    required this.replace,
    required this.onPick,
    required this.onCreate,
  });

  final String query;
  final bool packReady;
  final ParsedAmount? carried;
  final List<FoodSearchRow> rows;
  final LocalDate? date;
  final String? slotId;
  final VersionedId? replace;
  final FoodPicked onPick;

  /// Starts a new personal food named [query]; null where it isn't offered.
  final ValueChanged<String>? onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final create = query.isEmpty ? null : onCreate;
    final createLabel = l10n.foodSearchCreate(createQuote(query));
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
                    action: create == null
                        ? null
                        : FbButton.secondary(
                            label: createLabel,
                            icon: FbIcons.add,
                            onPressed: () => create(query),
                          ),
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
                    action: create == null
                        ? null
                        : FbButton.secondary(
                            label: createLabel,
                            icon: FbIcons.add,
                            onPressed: () => create(query),
                          ),
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
                  replacing: replace,
                ),
              );
            },
          ),
        if (create != null)
          FbListRow(
            key: const ValueKey('create-personal-food'),
            title: createLabel,
            leading: const Icon(FbIcons.add),
            onTap: () => create(query),
          ),
      ],
    );
  }
}
