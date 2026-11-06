import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/approx_text.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/text/name_filter.dart';
import 'package:fb_mobile/core/ui/load_states.dart';
import 'package:fb_mobile/features/diary/application/saved_meals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Saved meals (DY-031, UX-050, A09 D11): the meals the user saved, by name,
/// each with its item count, calories and the ⓨ badge. A tap opens the
/// meal. Nothing here writes; saving a meal starts from a meal's menu on
/// Today (A08).
class SavedMealsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  ConsumerState<SavedMealsScreen> createState() => _SavedMealsScreenState();
}

class _SavedMealsScreenState extends ConsumerState<SavedMealsScreen> {
  /// Filters a long list by the meal's or its foods' names (A65 m13).
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(SavedMeal meal) => namesMatch([
    meal.name,
    for (final i in meal.items) ...[i.food.names.en, i.food.names.ar],
  ], _query.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final meals = ref.watch(savedMealsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.savedMealsTitle)),
      body: switch (meals) {
        AsyncData(:final value) when value.isEmpty => FbEmptyState(
          icon: FbIcons.meal,
          title: l10n.savedMealsEmptyTitle,
          message: l10n.savedMealsEmptyMessage,
          action: FbButton.secondary(
            label: l10n.savedMealsGoToToday,
            onPressed: () =>
                ref.read(appNavigatorProvider).go(const TodayRoute()),
          ),
        ),
        AsyncData(:final value) => ListView(
          children: [
            if (value.length > listSearchThreshold)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  FbSpace.s4,
                  FbSpace.s3,
                  FbSpace.s4,
                  FbSpace.s2,
                ),
                child: FbSearchField(
                  key: const ValueKey('saved-meals-search'),
                  controller: _query,
                  hint: l10n.savedMealsSearchHint,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            for (final meal in _byName(value))
              if (value.length <= listSearchThreshold || _matches(meal))
                _MealRow(
                  key: ValueKey(meal.id),
                  meal: meal,
                  onTap: () => ref
                      .read(appNavigatorProvider)
                      .push(SavedMealRoute(id: meal.id)),
                ),
          ],
        ),
        AsyncError() => Padding(
          padding: const EdgeInsetsDirectional.all(FbSpace.s4),
          child: FbInlineBanner(
            kind: FbInlineBannerKind.error,
            message: l10n.savedMealsLoadFailed,
            actionLabel: l10n.commonTryAgain,
            onAction: () => ref.invalidate(savedMealsProvider),
          ),
        ),
        _ => const LoadingRows(count: 2),
      },
    );
  }

  /// By name, ignoring case; the ID breaks ties so the order is stable.
  static List<SavedMeal> _byName(List<SavedMeal> meals) =>
      [...meals]..sort((a, b) {
        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return byName != 0 ? byName : a.id.compareTo(b.id);
      });
}

class _MealRow extends StatelessWidget {
  const new({required this.meal, required this.onTap, super.key});

  final SavedMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FbListRow(
    title: meal.name,
    subtitle: context.l10n.diaryMealSummary(
      meal.items.length,
      kcalSummaryText(context.l10n, meal.intake),
    ),
    leading: const FbSourceBadge(source: FbSource.yours),
    trailing: const Icon(FbIcons.next),
    onTap: onTap,
  );
}
