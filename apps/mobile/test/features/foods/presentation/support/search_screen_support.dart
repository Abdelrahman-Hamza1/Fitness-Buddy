import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/db/support/db_support.dart';

/// A result row for a stored food: [kcal] per 100 g, [source] badge and an
/// optional Arabic name. With [loaf], the last input is one loaf of 60 g, so
/// the default serving is a loaf.
FoodSearchRow rowOf(
  String id,
  String name, {
  String? ar,
  double kcal = 100,
  FoodSource source = FoodSource.database,
  bool loaf = false,
  int at = 1,
}) => FoodSearchRow(
  tier: SourceTier.history,
  choice: historyChoice(
    FoodHistoryItem(
      food: EntryFood(
        ref: FoodRef.catalog(id, version: '6'),
        names: FoodNames(name, ar: ar),
        per100: Nutrients(kcal: kcal, protein: 2, carbs: 10, fat: 1, fiber: 0),
        provenance: Provenance(source: source),
      ),
      amount: EntryAmount(
        input: Quantity(loaf ? 1 : 100, loaf ? 'loaf' : 'g'),
        amount: loaf ? 60 : 100,
        basis: NutrientBasis.per100g,
      ),
      uses: 1,
      lastUsedHlc: Hlc.parse(hlcAt(at)),
    ),
  ),
);

/// Foods logged before, newest first.
final List<FoodSearchRow> recentRows = [
  rowOf(
    'usda:pita_white',
    'Pita bread, white',
    ar: 'خبز عربي',
    kcal: 275,
    loaf: true,
  ),
  rowOf('usda:rice_white_cooked', 'Rice, white, long-grain, cooked', kcal: 130),
  rowOf(
    'own:labaneh',
    'Labaneh',
    ar: 'لبنة',
    kcal: 180,
    source: FoodSource.yours,
  ),
  rowOf(
    'ref:mloukhiyeh',
    'Mloukhiyeh with rice and chicken, home style, one large plate',
    ar: 'ملوخية بالأرز والدجاج',
    kcal: 150,
    source: FoodSource.reference,
  ),
];

/// A search stand-in: answers each query at once from [answers], or with
/// [recent] for an empty one.
final class FakeFoodSearch extends FoodSearchController {
  new({
    this.packReady = true,
    this.recent = const [],
    this.answers = const {},
    this.fail = false,
    this.shouldFail,
  });

  final bool packReady;
  final List<FoodSearchRow> recent;
  final Map<String, List<FoodSearchRow>> answers;
  final bool fail;
  final bool Function()? shouldFail;

  /// Every query the screen asked for, in order.
  final queries = <String>[];

  @override
  FoodSearchState build() => const FoodSearchState();

  @override
  void setQuery(String text) {
    queries.add(text);
    final key = text.trim();
    if (fail || (shouldFail?.call() ?? false)) {
      state = FoodSearchState(
        query: text,
        error: StateError('x'),
        results: state.results,
        resultsFor: state.resultsFor,
      );
      return;
    }
    state = FoodSearchState(
      query: text,
      resultsFor: text,
      results: FoodSearchResults(
        packReady: packReady,
        rows: key.isEmpty ? recent : answers[key] ?? const [],
      ),
    );
  }
}

/// Overrides the search controller with [search].
Override searchOverride(FakeFoodSearch search) =>
    foodSearchControllerProvider.overrideWith(() => search);

/// [screen] in a themed app with both localizations (LTR, like R1).
Widget screenApp(
  Widget screen, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  GlobalKey<NavigatorState>? navigatorKey,
}) => MaterialApp(
  navigatorKey: navigatorKey,
  debugShowCheckedModeBanner: false,
  theme: brightness == Brightness.light ? FbTheme.light() : FbTheme.dark(),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    FbLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: true,
    ),
    child: app!,
  ),
  home: screen,
);

/// Pumps [screen] in a themed app with both localizations.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen,
  FakeFoodSearch search, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [searchOverride(search)],
      child: screenApp(screen, brightness: brightness, textScale: textScale),
    ),
  );
  // The first search starts after the first frame.
  await tester.pump();
}
