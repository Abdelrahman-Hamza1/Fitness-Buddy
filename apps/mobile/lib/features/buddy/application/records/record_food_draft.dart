import 'package:fb_domain/fb_domain.dart';

/// The personal-food draft a Buddy card prepares for the form (A67 D8,
/// TD-092): the components' per 100, or the stated figures on their own
/// basis (per serving with its size when stated so); figures not stated
/// are 0 for the user to fill in. `null` when nothing usable is there.
///
/// When [FoodView.needsServingSize] (per-serving figures without a size,
/// or components whose weight isn't known) the draft's per-100 slot
/// carries the **per-serving** figures and the form opens per serving with
/// the size empty, so it can't be saved before the user enters it (A67
/// review 3, 4): never silently per 100.
PersonalFoodDraft? recordFoodDraft(FoodView f) {
  String cut(String s) => s.length <= PersonalFoodBounds.name
      ? s
      : s.substring(0, PersonalFoodBounds.name).trim();
  final names = FoodNames(cut(f.name));
  final aliases = {
    for (final a in f.aliases)
      if (a.trim().isNotEmpty && a.trim() != f.name.trim()) cut(a.trim()),
  };
  if (f.totals case final totals? when f.stated == null) {
    return PersonalFoodDraft(
      names: names,
      per100: totals,
      aliases: aliases,
      createdFrom: 'buddy',
    );
  }
  final stated = f.stated;
  if (stated != null) {
    final values = Nutrients(
      kcal: stated.kcal ?? 0,
      protein: stated.protein ?? 0,
      carbs: stated.carbs ?? 0,
      fat: stated.fat ?? 0,
      fiber: stated.fiber ?? 0,
    );
    final size = stated.servingG ?? stated.servingMl;
    if (stated.basis == 'perServing' &&
        size != null &&
        size >= PersonalFoodBounds.minServing &&
        size <= PersonalFoodBounds.maxServing) {
      return PersonalFoodDraft.fromServing(
        names: names,
        valuesPerServing: values,
        serving: PersonalFoodServing('serving', size),
        basis: f.basis,
        aliases: aliases,
        createdFrom: 'buddy',
      );
    }
    return PersonalFoodDraft(
      names: names,
      per100: values,
      basis: f.basis,
      aliases: aliases,
      createdFrom: 'buddy',
    );
  }
  final per100 = f.per100;
  if (per100 == null) return null;
  return PersonalFoodDraft(
    names: names,
    per100: per100,
    basis: f.basis,
    aliases: aliases,
    createdFrom: 'buddy',
  );
}
