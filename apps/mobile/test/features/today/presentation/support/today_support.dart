import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/body/data/weigh_in_repository.dart';
import 'package:fb_mobile/features/body/data/weight_tip_store.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/quick_add/quick_add.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/quick_add_context.dart';
import '../../../../helpers/unit_feed.dart';
import '../../../body/support/memory_tip_store.dart';
import '../../../diary/support/diary_fixtures.dart' show fixtureId;
import '../../../diary/support/diary_harness.dart';

/// The fixed "today" of the Today tests: 2026-10-17, 12:00 UTC.
final LocalDate testToday = LocalDate(2026, 10, 17);

/// The day before [testToday].
final LocalDate testYesterday = testToday.plusDays(-1);

/// A prod-flavor configuration (no dev-only controls).
final AppConfig prodConfig = AppConfig(
  flavor: AppFlavor.prod,
  apiBaseUrl: Uri.parse('https://api.example.test'),
  sentryDsn: '',
);

/// A dev-flavor configuration.
final AppConfig devConfig = AppConfig(
  flavor: AppFlavor.dev,
  apiBaseUrl: Uri.parse('http://127.0.0.1:5198'),
  sentryDsn: '',
);

/// A navigator that records what was pushed.
final class RecordingNavigator implements AppNavigator {
  /// Every pushed route, in order.
  final List<AppRoute> pushed = [];

  /// Every route gone to (a tab switch), in order.
  final List<AppRoute> went = [];

  @override
  void go(AppRoute route) => went.add(route);

  @override
  void push(AppRoute route) => pushed.add(route);

  @override
  void pop() {}
}

/// The entry [n] on [date] in [slotId] at [hour]:[minute], named [name].
DiaryEntry fakeEntry(
  int n, {
  required LocalDate date,
  String slotId = DefaultSlots.breakfastId,
  int hour = 8,
  int minute = 0,
  String? name,
  String? ar,
  double kcal = 150,
  String? group,
  FoodSource source = FoodSource.database,
  bool edited = false,
  Quantity? input,
  double grams = 100,
  List<String> assumptions = const [],
  EstimateRange? range,
  Map<NutrientKey, double> extras = const {},
}) {
  final per = grams == 0 ? 0 : 100 / grams;
  return DiaryEntry(
    id: fixtureId(n),
    version: 1,
    time: EntryTime(
      DateTime.utc(date.year, date.month, date.day, hour, minute),
      0,
    ),
    localDate: date,
    slotId: slotId,
    dishGroupId: group == null ? null : fixtureId(900 + int.parse(group)),
    editedByUser: edited,
    food: EntryFood(
      ref: source == FoodSource.estimate
          ? FoodRef.estimate()
          : FoodRef.catalog('food-$n', version: '1'),
      names: FoodNames(name ?? 'Food $n', ar: ar),
      per100: Nutrients(
        kcal: kcal * per,
        protein: kcal / 15 * per,
        carbs: kcal / 8 * per,
        fat: kcal / 30 * per,
        fiber: kcal / 60 * per,
        extras: extras,
      ),
      provenance: Provenance(
        source: source,
        range: range,
        assumptions: assumptions,
      ),
    ),
    amount: EntryAmount(
      input: input ?? Quantity(grams, 'g'),
      amount: grams,
      basis: NutrientBasis.per100g,
    ),
    snapshot: Nutrients(
      kcal: kcal,
      protein: kcal / 15,
      carbs: kcal / 8,
      fat: kcal / 30,
      fiber: kcal / 60,
      extras: extras,
    ),
  );
}

/// The dish group [n] (of [fakeEntry]'s `group: '$n'`).
DishGroup fakeGroup(
  int n, {
  required LocalDate date,
  String name = 'Mloukhiyeh',
  String slotId = DefaultSlots.lunchId,
}) => DishGroup(
  id: fixtureId(900 + n),
  version: 1,
  name: name,
  localDate: date,
  slotId: slotId,
);

/// A day of the four default meals holding [entries] and [groups].
DiaryDay fakeDay(
  LocalDate date, [
  List<DiaryEntry> entries = const [],
  List<DishGroup> groups = const [],
]) => DiaryDay(
  date: date,
  slots: DefaultSlots.all,
  groups: groups,
  entries: entries,
);

/// The display model of [day].
DayView fakeView(DiaryDay day) => DayView(
  raw: day,
  layout: DayLayout.build(day.slots, day.groups, day.entries),
);

/// A full day: breakfast (2), lunch (a dish of 2 and a plate of rice),
/// dinner (1) and an empty snacks meal.
DiaryDay fullDay(LocalDate date, {int seed = 0}) => fakeDay(
  date,
  [
    fakeEntry(
      1 + seed * 10,
      date: date,
      name: 'Pita bread, white',
      ar: 'خبز عربي',
      kcal: 165,
      grams: 60,
      input: Quantity(1, 'loaf'),
      extras: {NutrientKey.sugar: 1.6, NutrientKey.sodium: 322},
    ),
    fakeEntry(
      2 + seed * 10,
      date: date,
      name: 'Labaneh',
      ar: 'لبنة',
      kcal: 90,
      minute: 20,
    ),
    fakeEntry(
      3 + seed * 10,
      date: date,
      slotId: DefaultSlots.lunchId,
      hour: 13,
      name: 'Mloukhiyeh leaves',
      kcal: 180,
      group: '${1 + seed}',
    ),
    fakeEntry(
      4 + seed * 10,
      date: date,
      slotId: DefaultSlots.lunchId,
      hour: 13,
      minute: 1,
      name: 'Chicken thigh',
      kcal: 240,
      group: '${1 + seed}',
    ),
    fakeEntry(
      5 + seed * 10,
      date: date,
      slotId: DefaultSlots.lunchId,
      hour: 13,
      minute: 5,
      name: 'Rice, white, cooked',
      kcal: 205,
      grams: 158,
      input: Quantity(1, 'cup'),
    ),
    fakeEntry(
      6 + seed * 10,
      date: date,
      slotId: DefaultSlots.dinnerId,
      hour: 19,
      name: 'Hummus',
      kcal: 310,
      source: FoodSource.yours,
    ),
  ],
  [fakeGroup(1 + seed, date: date)],
);

/// The providers of a Today screen on fake data: every day is [days] (an
/// empty one when it is not there), the targets of a day are [targets]
/// (none when it is not there) and setup stands at [setup] (A13: not set up,
/// so today shows the setup row), no database.
List<Override> fakeToday({
  Map<LocalDate, DiaryDay> days = const {},
  RecordingNavigator? navigator,
  AppConfig? config,
  ManualClock? clock,
  bool liveToday = false,
  bool fakeDays = true,
  UnitSystem units = UnitSystem.metric,
  List<QuickAddChip> chips = const [],
  Override? chipsOverride,
  List<WeighIn> weighIns = const [],
  CadenceTipState tip = CadenceTipState.initial,
  Map<LocalDate, DayTargets> targets = const {},
  SetupStatus setup = SetupStatus.notSetUp,
}) => [
  clockProvider.overrideWithValue(
    clock ?? ManualClock(DateTime.utc(2026, 10, 17, 12)),
  ),
  // No midnight timer, unless the test is about it: the screen falls back to
  // the clock for the first frame, which is today.
  if (!liveToday) todayProvider.overrideWith((ref) => Stream.value(testToday)),
  appConfigProvider.overrideWithValue(config ?? prodConfig),
  appNavigatorProvider.overrideWithValue(navigator ?? RecordingNavigator()),
  // No database stream to close at the end of a widget test.
  unitSystemProvider.overrideWith((ref) => Stream.value(units)),
  if (fakeDays)
    dayViewProvider.overrideWith(
      (ref, date) => AsyncData(fakeView(days[date] ?? fakeDay(date))),
    ),
  // The quick-add suggestions are their own tests' business (A09 WP8): the
  // Today tests see none unless they pass [chips].
  chipsOverride ??
      quickAddChipsProvider.overrideWith((ref, date) => AsyncData(chips)),
  // The weight card (A14) on [weighIns], with the suggestion state [tip]; no
  // database stream and no preferences.
  weighInsProvider.overrideWith((ref) => Stream.value(weighIns)),
  weightTipStoreProvider.overrideWithValue(MemoryTipStore(tip)),
  // The numbers block (A13 D12): synchronous, so no skeleton frame.
  dayTargetsProvider.overrideWith((ref, date) => targets[date]),
  setupStatusProvider.overrideWith((ref) => setup),
  // The workout row (A37 D20) is the workouts tests' business (R7): no row.
  todayWorkoutProvider.overrideWith((ref, date) => null),
];

/// The providers of a Today screen on a real in-memory diary, with a real
/// applier and undo stack.
final class TodayRig {
  /// Creates the rig; [apply] replaces the applier (to make commands fail).
  new({this.apply, AppConfig? config, this.realChips = false})
    : config = config ?? prodConfig {
    stack = UndoStack(revert: diary.applier.revert, clock: diary.clock);
    addTearDown(stack.dispose);
  }

  final Future<ApplyResult> Function(ChangeSet)? apply;
  final AppConfig config;

  /// Whether the quick-add row reads the real diary. Off, it shows nothing,
  /// so the A08 tests keep one row per logged item.
  final bool realChips;
  final DiaryHarness diary = DiaryHarness();

  /// The unit system; switch it with `units.set`.
  final UnitFeed units = UnitFeed();
  final RecordingNavigator navigator = RecordingNavigator();
  late final UndoStack stack;

  /// The weight card's suggestion state (A14 D10).
  final MemoryTipStore tips = MemoryTipStore();

  List<Override> get overrides => [
    diaryRepositoryProvider.overrideWithValue(DiaryRepository(diary.db)),
    personalFoodRepositoryProvider.overrideWithValue(
      PersonalFoodRepository(diary.db),
    ),
    changeSetApplierProvider.overrideWithValue(diary.applier),
    diaryApplyProvider.overrideWithValue(apply ?? diary.applier.apply),
    clockProvider.overrideWithValue(diary.clock),
    idGeneratorProvider.overrideWithValue(diary.ids),
    undoStackProvider.overrideWithValue(stack),
    todayProvider.overrideWith((ref) => Stream.value(testToday)),
    quickAddContextWithoutTimer(),
    if (!realChips)
      quickAddChipsProvider.overrideWith(
        (ref, date) => const AsyncData(<QuickAddChip>[]),
      ),
    appConfigProvider.overrideWithValue(config),
    appNavigatorProvider.overrideWithValue(navigator),
    units.override,
    // The weight card (A14) reads and writes the same in-memory profile.
    weighInRepositoryProvider.overrideWithValue(WeighInRepository(diary.db)),
    weightTipStoreProvider.overrideWithValue(tips),
    // The numbers block (A13 D12) reads the same in-memory profile: no
    // targets until a test stores some.
    targetsRepositoryProvider.overrideWithValue(TargetsRepository(diary.db)),
    weekStartProvider.overrideWith((ref) => Stream.value(DayOfWeek.saturday)),
    // The workout row (A37 D20) is the workouts tests' business (R7).
    todayWorkoutProvider.overrideWith((ref, date) => null),
  ];
}

/// [screen] in a themed app with both localizations (LTR, like R1).
Widget phoneApp(
  Widget screen, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool disableAnimations = true,
}) => MaterialApp(
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
      disableAnimations: disableAnimations,
    ),
    child: app!,
  ),
  home: screen,
);

/// A 360 x 800 phone.
void usePhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
