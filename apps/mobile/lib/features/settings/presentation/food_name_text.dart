import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/settings/application/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A food's names as the "Food names" setting shows them (D-091): watch
/// this in a row's `build` and use [FoodNameLines.primary] as the title and
/// [FoodNameLines.secondary] (when set) at the start of the subtitle.
FoodNameLines watchFoodNames(WidgetRef ref, FoodNames names) =>
    FoodNameLines.of(names, ref.watch(foodNameLanguageProvider));

/// A food's one name for use inside a sentence, a title or a snackbar
/// (LC-007, D-095): the setting's main name, [isolateName]-wrapped. In
/// "Both" that is the English name only, so a sentence never mixes scripts.
String foodNameInline(FoodNames names, FoodNameLanguage language) =>
    isolateName(FoodNameLines.of(names, language).primary);

/// [foodNameInline] in the current setting, watched (for `build`).
String watchFoodNameInline(WidgetRef ref, FoodNames names) =>
    foodNameInline(names, ref.watch(foodNameLanguageProvider));

/// [foodNameInline] in the current setting, read once (for callbacks such
/// as a snackbar after an action).
String readFoodNameInline(WidgetRef ref, FoodNames names) =>
    foodNameInline(names, ref.read(foodNameLanguageProvider));

/// An undo-label or outcome placeholder for a sentence: [FoodNames] as
/// [foodNameInline], anything else as its text, isolated.
String foodNameArg(Object? value, FoodNameLanguage language) => switch (value) {
  final FoodNames names => foodNameInline(names, language),
  _ => isolateName('${value ?? ''}'),
};

/// [lines] as one spoken label (N2): "English, Arabic" in "Both", else the
/// main name.
String foodNameSpoken(FoodNameLines lines) => switch (lines.secondary) {
  final second? => '${lines.primary}, $second',
  null => lines.primary,
};

/// [text] wrapped in Unicode first-strong isolates (FSI … PDI) when it has
/// right-to-left letters, so an Arabic name inside an English line ("خبز
/// عربي · 1 loaf") keeps its own direction and doesn't reorder the rest.
String isolateName(String text) =>
    _rtl.hasMatch(text) ? '\u2068$text\u2069' : text;

final RegExp _rtl = RegExp('[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]');
