import 'package:alchemist/alchemist.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'support/search_screen_support.dart';

/// Phone size of a screen golden cell, in dp.
const double _width = 360;
const double _height = 640;

/// The search screen as a phone shows it: LTR only in R1 (`09` §3),
/// [brightness], text [scale], animations off.
Widget _phone(
  FakeFoodSearch search,
  Brightness brightness,
  double scale, {
  String query = '',
}) => SizedBox(
  width: _width,
  height: _height,
  // The screen focuses its box, but only one cell of a golden can have the
  // focus: none of them does, so every cell looks the same.
  child: ExcludeFocus(
    child: ProviderScope(
      overrides: [searchOverride(search)],
      child: screenApp(
        FoodSearchScreen(initialQuery: query),
        brightness: brightness,
        textScale: scale,
      ),
    ),
  ),
);

Future<void> _screenGolden(
  String name,
  String file,
  FakeFoodSearch Function() search, {
  String query = '',
}) => goldenTest(
  name,
  fileName: file,
  builder: () => GoldenTestGroup(
    columns: 4,
    children: [
      for (final scale in const [1.0, 2.0])
        for (final (label, brightness) in const [
          ('light', Brightness.light),
          ('dark', Brightness.dark),
        ])
          GoldenTestScenario(
            name: '$label, x$scale',
            child: _phone(search(), brightness, scale, query: query),
          ),
    ],
  ),
);

Future<void> main() async {
  await _screenGolden(
    'FD-020 food search: empty unavailable pack with a query',
    'food_search_pack_empty',
    () => FakeFoodSearch(packReady: false),
    query: 'zzqx',
  );
  await _screenGolden(
    'FD-023 food search: recent foods',
    'food_search_recent',
    () => FakeFoodSearch(recent: recentRows),
  );
  await _screenGolden(
    'FD-020 FD-021 food search: results',
    'food_search_results',
    () => FakeFoodSearch(answers: {'rice': recentRows}),
    query: 'rice',
  );
  await _screenGolden(
    'FD-020 food search: no results',
    'food_search_no_results',
    FakeFoodSearch.new,
    query: 'zzqx',
  );
  await _screenGolden(
    'FD-023 food search: no history yet',
    'food_search_no_history',
    FakeFoodSearch.new,
  );
  await _screenGolden(
    'FD-023 food search: food database not ready',
    'food_search_pack_not_ready',
    () => FakeFoodSearch(packReady: false, recent: recentRows.take(2).toList()),
  );
}
