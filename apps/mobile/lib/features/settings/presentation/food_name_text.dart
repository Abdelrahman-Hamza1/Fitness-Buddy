import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/settings/application/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A food's names as the "Food names" setting shows them (D-091): watch
/// this in a row's `build` and use [FoodNameLines.primary] as the title and
/// [FoodNameLines.secondary] (when set) at the start of the subtitle.
FoodNameLines watchFoodNames(WidgetRef ref, FoodNames names) =>
    FoodNameLines.of(names, ref.watch(foodNameLanguageProvider));

/// [text] wrapped in Unicode first-strong isolates (FSI … PDI) when it has
/// right-to-left letters, so an Arabic name inside an English line ("خبز
/// عربي · 1 loaf") keeps its own direction and doesn't reorder the rest.
String isolateName(String text) =>
    _rtl.hasMatch(text) ? '\u2068$text\u2069' : text;

final RegExp _rtl = RegExp('[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]');
