import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/catalog/catalog_providers.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'setup_flow.g.dart';

/// The five setup pages, in order (A13 D9).
enum SetupPage {
  /// Units, sex, birth year, height, current weight.
  you,

  /// The four activity levels.
  activity,

  /// Lose / maintain / gain and how.
  goal,

  /// Week start, halal, city (prefilled, each skippable).
  preferences,

  /// The calculated targets, the explanation and Save.
  targets,
}

/// A required input of setup, in page order: where a refused Next scrolls
/// (UX-052).
enum SetupField {
  /// Formula sex (page 1).
  sex,

  /// Birth year (page 1).
  birthYear,

  /// Height (page 1).
  height,

  /// Current weight (page 1).
  weight,

  /// Activity level (page 2).
  activity,

  /// The goal (page 3).
  goal,
}

/// Everything setup holds while the user goes through it (D9, UX-052):
/// the text as typed, in memory only, until Save. Immutable; [today] is
/// read once when setup opens. Sensitive: [toString] shows no values.
final class SetupDraft {
  /// A draft on [today] with the stored preferences.
  const new({
    required this.today,
    required this.units,
    required this.weekStart,
    required this.halal,
    this.cityId,
    this.city,
    this.alreadySetUp = false,
    this.page = SetupPage.you,
    this.sex,
    this.birthYear = '',
    this.height = const HeightDraft(),
    this.weight = const BodyWeightDraft(),
    this.activity,
    this.goal = const GoalDraft(),
    this.touched = false,
    this.showErrors = false,
    this.saving = false,
  });

  /// A new draft whose inputs follow [units] (TG-002).
  factory initial({
    required LocalDate today,
    required UnitSystem units,
    required DayOfWeek weekStart,
    required bool halal,
    String? cityId,
    CatalogCity? city,
    bool alreadySetUp = false,
  }) => SetupDraft(
    today: today,
    units: units,
    weekStart: weekStart,
    halal: halal,
    cityId: cityId,
    city: city,
    alreadySetUp: alreadySetUp,
  )._withUnits(units, touched: false);

  /// The setup's evaluation date (age, "this month", target dates).
  final LocalDate today;

  /// Display units: they drive the height, weight and goal inputs.
  final UnitSystem units;

  /// First day of the week (LC-021).
  final DayOfWeek weekStart;

  /// Halal food preference.
  final bool halal;

  /// The stored or chosen city identity, or null ("Not set"). Kept apart
  /// from [city]: a stored city the offline pack can't resolve stays stored
  /// (Save writes a city only when the user picks one).
  final String? cityId;

  /// [cityId] resolved for display, or null (not set, or not resolvable).
  final CatalogCity? city;

  /// Whether setup had already run when it opened (perhaps on another
  /// device): the screen goes back to Today instead of offering it.
  final bool alreadySetUp;

  /// The page shown.
  final SetupPage page;

  /// Formula sex, or null before a choice.
  final FormulaSex? sex;

  /// The birth year as typed.
  final String birthYear;

  /// The height as typed.
  final HeightDraft height;

  /// The current weight as typed (the first weigh-in, WB-001).
  final BodyWeightDraft weight;

  /// The activity level, or null before a choice.
  final ActivityLevel? activity;

  /// The goal as typed.
  final GoalDraft goal;

  /// Whether the user entered or changed anything (closing then asks).
  final bool touched;

  /// Whether this page's missing or invalid inputs show their messages (a
  /// refused Next or Save, UX-052). Off again on another page.
  final bool showErrors;

  /// Whether Save is in flight.
  final bool saving;

  /// The page's number, from 1.
  int get step => page.index + 1;

  /// The number of pages.
  static int get steps => SetupPage.values.length;

  /// Whether [page]'s required fields are all valid (Next is on).
  bool get canContinue => switch (page) {
    SetupPage.you => _youValid,
    SetupPage.activity => activity != null,
    SetupPage.goal => _goalValid,
    SetupPage.preferences => true,
    SetupPage.targets => preview?.calculation != null && !saving,
  };

  bool get _youValid => firstProblem == null;

  /// The first required input of this page that is missing or invalid, or
  /// null (where a refused Next scrolls).
  SetupField? get firstProblem => switch (page) {
    SetupPage.you when sex == null => SetupField.sex,
    SetupPage.you when readBirthYear(birthYear, today).value == null =>
      SetupField.birthYear,
    SetupPage.you when height.read().value == null => SetupField.height,
    SetupPage.you when weight.read().value == null => SetupField.weight,
    SetupPage.activity when activity == null => SetupField.activity,
    SetupPage.goal when !_goalValid => SetupField.goal,
    _ => null,
  };

  bool get _goalValid {
    if (goal.read(today).input == null || goalProblem != null) return false;
    return _previewFor()?.issue == null;
  }

  /// The current weight, kg, or null while it can't be read.
  double? get weightKg => weight.read().value;

  /// The goal's resolution problem against the typed weight (PA3), or null.
  GoalProblem? get goalProblem {
    final input = goal.read(today).input;
    final kg = weightKg;
    if (input == null || kg == null) return null;
    return GoalProblem.of(input, currentKg: kg, today: today);
  }

  /// What Save writes, or null while a required field is missing.
  SetupInput? get input => _previewInput();

  /// The engine's numbers for [input] (D9 page 5), or null.
  SetupPreview? get preview => _previewFor();

  /// The engine's calculation for the goal page's live line, or null.
  TargetCalculation? get goalCalculation =>
      goalProblem == null ? _previewFor()?.calculation : null;

  SetupInput? _previewInput() {
    final sex = this.sex;
    final activity = this.activity;
    final year = readBirthYear(birthYear, today).value;
    final length = height.read().value;
    final typed = parseTypedNumber(weight.text);
    final goalInput = goal.read(today).input;
    if (sex == null ||
        activity == null ||
        year == null ||
        length == null ||
        typed == null ||
        weightKg == null ||
        goalInput == null) {
      return null;
    }
    return SetupInput(
      sex: sex,
      birthYear: year,
      height: length,
      heightInputUnit: height.unit,
      weightValue: typed,
      weightUnit: weight.unit,
      activity: activity,
      goal: goalInput,
      preferences: SetupPreferences(
        unitSystem: units,
        weekStart: weekStart,
        halal: halal,
        cityId: cityId,
      ),
    );
  }

  SetupPreview? _previewFor() {
    final input = _previewInput();
    return input == null ? null : SetupPreview.of(input, today);
  }

  SetupDraft _withUnits(UnitSystem units, {required bool touched}) => _copy(
    units: units,
    height: height.withUnit(
      units == UnitSystem.imperial
          ? HeightInputUnit.feetInches
          : HeightInputUnit.centimeter,
    ),
    weight: weight.withUnit(units.bodyMass),
    goal: goal.withUnit(units.bodyMass),
    touched: touched,
  );

  SetupDraft _copy({
    UnitSystem? units,
    DayOfWeek? weekStart,
    bool? halal,
    String? cityId,
    CatalogCity? city,
    SetupPage? page,
    FormulaSex? sex,
    String? birthYear,
    HeightDraft? height,
    BodyWeightDraft? weight,
    ActivityLevel? activity,
    GoalDraft? goal,
    bool? touched,
    bool? showErrors,
    bool? saving,
  }) => SetupDraft(
    today: today,
    units: units ?? this.units,
    weekStart: weekStart ?? this.weekStart,
    halal: halal ?? this.halal,
    cityId: cityId ?? this.cityId,
    city: city ?? this.city,
    alreadySetUp: alreadySetUp,
    page: page ?? this.page,
    sex: sex ?? this.sex,
    birthYear: birthYear ?? this.birthYear,
    height: height ?? this.height,
    weight: weight ?? this.weight,
    activity: activity ?? this.activity,
    goal: goal ?? this.goal,
    touched: touched ?? this.touched,
    // A new page starts without messages.
    showErrors: showErrors ?? (page == null && this.showErrors),
    saving: saving ?? this.saving,
  );

  @override
  String toString() => 'SetupDraft(${page.name})';
}

/// The setup flow's view model (D9/D10): opens on the stored preferences,
/// keeps every page's input in memory, moves between pages and saves once
/// through [TargetsActions.completeSetup]. Disposed with the setup screen.
@riverpod
class SetupFlow extends _$SetupFlow {
  @override
  Future<SetupDraft> build() async {
    // One read each (not watched): setup's own Save writes these settings,
    // and the draft must not reset under the user.
    final store = ref.read(settingsStoreProvider);
    final today = EntryTime.now(ref.read(clockProvider)).localDate;
    final units = await store.read(AppSettings.unitSystem);
    final weekStart = await store.read(AppSettings.weekStart);
    final halal = await store.read(AppSettings.halal);
    final cityId = await store.read(AppSettings.cityId);
    // One read of the stored targets (not the auto-disposed status
    // provider, which a one-shot read could dispose while it loads).
    final stored = await ref.read(targetsRepositoryProvider).read();
    final alreadySetUp = stored.profile != null && stored.settings.isNotEmpty;
    CatalogCity? city;
    if (cityId != null) {
      try {
        city = await ref.read(offlineCatalogProvider).city(cityId);
      }
      // A missing or unreadable pack: the city shows "Not set" (offline).
      // ignore: avoid_catches_without_on_clauses
      catch (_) {
        city = null;
      }
    }
    return SetupDraft.initial(
      today: today,
      units: units,
      weekStart: weekStart,
      halal: halal,
      cityId: cityId,
      city: city,
      alreadySetUp: alreadySetUp,
    );
  }

  void _edit(SetupDraft Function(SetupDraft draft) change) {
    final draft = state.value;
    if (draft == null || draft.saving) return;
    state = AsyncData(change(draft));
  }

  /// Display units: switches the height, weight and goal inputs (TG-002).
  void setUnits(UnitSystem units) =>
      _edit((d) => d._withUnits(units, touched: true));

  /// Formula sex.
  void setSex(FormulaSex sex) => _edit((d) => d._copy(sex: sex, touched: true));

  /// The birth year text.
  void setBirthYear(String text) =>
      _edit((d) => d._copy(birthYear: text, touched: true));

  /// The height draft.
  void setHeight(HeightDraft height) =>
      _edit((d) => d._copy(height: height, touched: true));

  /// The weight draft.
  void setWeight(BodyWeightDraft weight) =>
      _edit((d) => d._copy(weight: weight, touched: true));

  /// The activity level.
  void setActivity(ActivityLevel level) =>
      _edit((d) => d._copy(activity: level, touched: true));

  /// The goal draft.
  void setGoal(GoalDraft goal) =>
      _edit((d) => d._copy(goal: goal, touched: true));

  /// The first day of the week.
  void setWeekStart(DayOfWeek day) =>
      _edit((d) => d._copy(weekStart: day, touched: true));

  /// The halal preference.
  // One value, like the settings' own setter (`FbSwitchRow.onChanged`).
  // ignore: avoid_positional_boolean_parameters
  void setHalal(bool halal) =>
      _edit((d) => d._copy(halal: halal, touched: true));

  /// The city.
  void setCity(CatalogCity city) =>
      _edit((d) => d._copy(city: city, cityId: city.id, touched: true));

  /// The next page when this one is complete; otherwise this page shows
  /// its messages (UX-052) and the screen scrolls to [SetupDraft.firstProblem].
  void next() => _edit((d) {
    if (d.page == SetupPage.targets) return d;
    if (!d.canContinue) return d._copy(showErrors: true);
    return d._copy(page: SetupPage.values[d.page.index + 1]);
  });

  /// The previous page; what was typed is kept.
  void back() => _edit((d) {
    if (d.page == SetupPage.you) return d;
    return d._copy(page: SetupPage.values[d.page.index - 1]);
  });

  /// Saves setup as one change set with one undo entry (D10), or null when
  /// the draft isn't complete or a save is in flight.
  Future<TargetsOutcome?> save() async {
    final draft = state.value;
    final input = draft?.input;
    if (draft == null ||
        input == null ||
        draft.saving ||
        draft.page != SetupPage.targets) {
      return null;
    }
    state = AsyncData(draft._copy(saving: true));
    try {
      return await ref.read(targetsActionsProvider).completeSetup(input);
    } finally {
      if (ref.mounted) {
        final now = state.value;
        if (now != null) state = AsyncData(now._copy(saving: false));
      }
    }
  }
}
