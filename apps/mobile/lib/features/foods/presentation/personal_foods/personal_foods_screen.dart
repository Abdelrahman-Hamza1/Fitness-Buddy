import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/application/foods_providers.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Your foods (FD-070, UX-050, A09 D10): the foods the user made, by name,
/// each with the ⓨ badge. A tap opens the form; "New food" starts an empty
/// one. Nothing here writes.
class PersonalFoodsScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  void _open(WidgetRef ref, PersonalFoodRoute route) =>
      ref.read(appNavigatorProvider).push(route);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final foods = ref.watch(personalFoodsProvider);
    // Rows that can't be read stay counted, never silently hidden (#100).
    final unreadable =
        ref.watch(unreadablePersonalFoodCountProvider).value ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.yourFoodsTitle),
        actions: [
          FbIconButton(
            tooltip: l10n.yourFoodsNew,
            icon: FbIcons.add,
            onPressed: () => _open(ref, const PersonalFoodRoute()),
          ),
        ],
      ),
      body: Column(
        children: [
          if (unreadable > 0)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                FbSpace.s4,
                FbSpace.s3,
                FbSpace.s4,
                0,
              ),
              child: FbInlineBanner(
                kind: FbInlineBannerKind.info,
                message: l10n.yourFoodsUnreadable(unreadable),
              ),
            ),
          Expanded(child: _body(context, ref, foods)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<PersonalFood>> foods,
  ) {
    final l10n = context.l10n;
    return switch (foods) {
      AsyncData(:final value) when value.isEmpty => FbEmptyState(
        icon: FbIcons.empty,
        title: l10n.yourFoodsEmptyTitle,
        message: l10n.yourFoodsEmptyMessage,
        action: FbButton.primary(
          label: l10n.yourFoodsNew,
          icon: FbIcons.add,
          onPressed: () => _open(ref, const PersonalFoodRoute()),
        ),
      ),
      AsyncData(:final value) => ListView(
        children: [
          for (final food in value)
            _FoodRow(
              key: ValueKey(food.id),
              food: food,
              onTap: () => _open(ref, PersonalFoodRoute(id: food.id)),
            ),
        ],
      ),
      AsyncError() => Padding(
        padding: const EdgeInsetsDirectional.all(FbSpace.s4),
        child: FbInlineBanner(
          kind: FbInlineBannerKind.error,
          message: l10n.yourFoodsLoadFailed,
          actionLabel: l10n.foodTryAgain,
          onAction: () => ref.invalidate(personalFoodsProvider),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsetsDirectional.all(FbSpace.s4),
        child: Column(
          spacing: FbSpace.s3,
          children: [FbSkeleton.line(height: 56), FbSkeleton.line(height: 56)],
        ),
      ),
    };
  }
}

class _FoodRow extends ConsumerWidget {
  const new({required this.food, required this.onTap, super.key});

  final PersonalFood food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kcal = l10n.yourFoodsKcalPer(
      DisplayRounding.kcal(food.per100.kcal),
      food.basis == NutrientBasis.per100g
          ? l10n.personalFoodBasis100g
          : l10n.personalFoodBasis100ml,
    );
    final names = watchFoodNames(ref, food.names);
    return FbListRow(
      title: names.primary,
      subtitle: switch (names.secondary) {
        final ar? => l10n.foodResultSubtitle(isolateName(ar), kcal),
        null => kcal,
      },
      leading: const FbSourceBadge(source: FbSource.yours),
      trailing: const Icon(FbIcons.next),
      onTap: onTap,
    );
  }
}
