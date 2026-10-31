import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'setup_flow.g.dart';

/// Where the question screens were opened from (A51 D2).
enum SetupMode {
  /// "Set up profile & targets" (Today, Me, Targets): the questions only.
  setup,

  /// The first run on a fresh install (D-088): the questions, then the
  /// optional account step.
  firstRun,
}

/// The question screens, in order (A51 D2). Which ones a run shows depends
/// on the answers: [SetupDraft.pages].
enum SetupPage {
  /// What brings you here: lose / keep / gain / just see what I eat.
  goal,

  /// Sex, birth year, height, current weight; metric or imperial.
  you,

  /// The four activity levels.
  activity,

  /// Do you work out: not now / I mix it up / I want a plan.
  training,

  /// The calculated plan, "How is this worked out?" and Save.
  plan,

  /// Keep your data safe? Google / email / not now (first run only).
  account,
}

/// The answer to "Do you work out?" (D-088). Nothing is stored: "I want a
/// plan" only opens the starter plans when the flow ends.
enum TrainingChoice {
  /// Not right now: set it up later in the Workouts tab.
  notNow,

  /// Yes, I mix it up: log what I do each time.
  mixItUp,

  /// Yes, I want a plan: the starter plans open after the flow.
  wantPlan,
}

/// A required input, in page order: where a refused Continue scrolls
/// (UX-052).
enum SetupField {
  /// The goal answer.
  goal,

  /// Formula sex.
  sex,

  /// Birth year.
  birthYear,

  /// Height.
  height,

  /// Current weight.
  weight,

  /// Activity level.
  activity,

  /// The training answer.
  training,
}

/// What a Continue or Skip did.
enum SetupMove {
  /// Another page is shown.
  moved,

  /// This page shows what's missing (UX-052).
  refused,

  /// That was the last page: the flow is done.
  finished,
}

/// Everything the question screens hold (D9, UX-052, A51): the text as
/// typed, in memory only, until the plan is confirmed. Immutable; [today]
/// is read once when the flow opens. Sensitive: [toString] shows no values.
final class SetupDraft {
  /// A draft on [today] with the stored preferences.
  const new({
    required this.today,
    required this.units,
    required this.weekStart,
    required this.halal,
    this.mode = SetupMode.setup,
    this.cityId,
    this.alreadySetUp = false,
    this.page = SetupPage.goal,
    this.skipped = const {},
    this.justTrack = false,
    this.sex,
    this.birthYear = '',
    this.height = const HeightDraft(),
    this.weight = const BodyWeightDraft(),
    this.activity,
    this.goal = const GoalDraft(),
    this.training,
    this.touched = false,
    this.showErrors = false,
    this.saving = false,
    this.saved = false,
  });

  /// A new draft whose inputs follow [units] (TG-002).
  factory initial({
    required LocalDate today,
    required UnitSystem units,
    required DayOfWeek weekStart,
    required bool halal,
    SetupMode mode = SetupMode.setup,
    String? cityId,
    bool alreadySetUp = false,
  }) => SetupDraft(
    today: today,
    units: units,
    weekStart: weekStart,
    halal: halal,
    mode: mode,
    cityId: cityId,
    alreadySetUp: alreadySetUp,
  )._withUnits(units, touched: false);

  /// The evaluation date (age, "this month", target dates).
  final LocalDate today;

  /// Display units: they drive the height, weight and goal inputs.
  final UnitSystem units;

  /// The stored week start, passed through unchanged (D-088: no longer
  /// asked here).
  final DayOfWeek weekStart;

  /// The stored halal preference, passed through unchanged.
  final bool halal;

  /// The stored city, passed through unchanged.
  final String? cityId;

  /// Where the flow was opened from.
  final SetupMode mode;

  /// Whether targets were already set up when the flow opened (perhaps on
  /// another device): the screen goes back to Today instead.
  final bool alreadySetUp;

  /// The page shown.
  final SetupPage page;

  /// The question pages the user skipped (their typed text is kept for
  /// Back, but not used).
  final Set<SetupPage> skipped;

  /// "Just see what I eat": no calorie target.
  final bool justTrack;

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

  /// The goal as typed (lose / keep / gain with its pace).
  final GoalDraft goal;

  /// The training answer, or null.
  final TrainingChoice? training;

  /// Whether the user answered or changed anything (closing then asks).
  final bool touched;

  /// Whether this page's missing or invalid inputs show their messages (a
  /// refused Continue, UX-052). Off again on another page.
  final bool showErrors;

  /// Whether the save is in flight.
  final bool saving;

  /// Whether the plan was saved (the first run then shows the account
  /// step; nothing can be saved twice).
  final bool saved;

  /// Whether the starter plans open when the flow ends: "I want a plan",
  /// unless that question was skipped.
  bool get wantsPlan =>
      training == TrainingChoice.wantPlan &&
      !skipped.contains(SetupPage.training);

  /// Whether the body questions are on this run's path: unless the goal
  /// was skipped or is "just see what I eat".
  bool get asksBody => !justTrack && !skipped.contains(SetupPage.goal);

  /// Whether the plan page is on this run's path: every input it needs is
  /// asked and none was skipped.
  bool get offersPlan =>
      saved ||
      (asksBody &&
          !skipped.contains(SetupPage.you) &&
          !skipped.contains(SetupPage.activity));

  /// The pages of this run, in order (the progress bar's segments).
  List<SetupPage> get pages => [
    SetupPage.goal,
    if (asksBody) ...[SetupPage.you, SetupPage.activity],
    SetupPage.training,
    if (offersPlan) SetupPage.plan,
    if (mode == SetupMode.firstRun) SetupPage.account,
  ];

  /// The shown page's place in [pages], from 0.
  int get step => pages.indexOf(page).clamp(0, pages.length - 1);

  /// Whether this page's answers are complete (Continue moves on).
  bool get canContinue => firstProblem == null;

  /// The first required input of this page that is missing or invalid, or
  /// null (where a refused Continue scrolls).
  SetupField? get firstProblem => switch (page) {
    SetupPage.goal when goal.type == null && !justTrack => SetupField.goal,
    SetupPage.you when sex == null => SetupField.sex,
    SetupPage.you when readBirthYear(birthYear, today).value == null =>
      SetupField.birthYear,
    SetupPage.you when height.read().value == null => SetupField.height,
    SetupPage.you when weight.read().value == null => SetupField.weight,
    SetupPage.activity when activity == null => SetupField.activity,
    SetupPage.training when training == null => SetupField.training,
    _ => null,
  };

  /// Whether the plan can be saved now.
  bool get canSave =>
      page == SetupPage.plan &&
      !saved &&
      !saving &&
      preview?.calculation != null;

  /// The current weight, kg, or null while it can't be read.
  double? get weightKg => weight.read().value;

  /// The goal's resolution problem against the typed weight (PA3), or null.
  GoalProblem? get goalProblem {
    final input = goal.read(today).input;
    final kg = weightKg;
    if (input == null || kg == null) return null;
    return GoalProblem.of(input, currentKg: kg, today: today);
  }

  /// What the save writes, or null while an input is missing, skipped or
  /// the goal is "just see what I eat".
  SetupInput? get input => offersPlan && !justTrack ? _previewInput() : null;

  /// The engine's numbers for [input] (the plan page), or null.
  SetupPreview? get preview {
    final input = this.input;
    return input == null ? null : SetupPreview.of(input, today);
  }

  /// The engine's calculation for the goal form's live line, or null.
  TargetCalculation? get goalCalculation =>
      goalProblem == null ? preview?.calculation : null;

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

  /// The page after this one on the path, or null at the end.
  SetupPage? get _after {
    final path = pages;
    final i = path.indexOf(page);
    return i < 0 || i + 1 >= path.length ? null : path[i + 1];
  }

  /// The page before this one on the path, or null at the start.
  SetupPage? get before {
    if (saved) return null;
    final path = pages;
    final i = path.indexOf(page);
    return i <= 0 ? null : path[i - 1];
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
    SetupPage? page,
    Set<SetupPage>? skipped,
    bool? justTrack,
    FormulaSex? sex,
    String? birthYear,
    HeightDraft? height,
    BodyWeightDraft? weight,
    ActivityLevel? activity,
    GoalDraft? goal,
    TrainingChoice? training,
    bool? touched,
    bool? showErrors,
    bool? saving,
    bool? saved,
  }) => SetupDraft(
    today: today,
    units: units ?? this.units,
    weekStart: weekStart,
    halal: halal,
    cityId: cityId,
    mode: mode,
    alreadySetUp: alreadySetUp,
    page: page ?? this.page,
    skipped: skipped ?? this.skipped,
    justTrack: justTrack ?? this.justTrack,
    sex: sex ?? this.sex,
    birthYear: birthYear ?? this.birthYear,
    height: height ?? this.height,
    weight: weight ?? this.weight,
    activity: activity ?? this.activity,
    goal: goal ?? this.goal,
    training: training ?? this.training,
    touched: touched ?? this.touched,
    // A new page starts without messages.
    showErrors: showErrors ?? (page == null && this.showErrors),
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
  );

  @override
  String toString() => 'SetupDraft(${page.name}, ${mode.name})';
}

/// The question screens' view model (D9/D10, A51): opens on the stored
/// preferences, keeps every answer in memory, moves along the run's
/// [SetupDraft.pages] and saves once through
/// [TargetsActions.completeSetup]. Disposed with the screen.
@riverpod
class SetupFlow extends _$SetupFlow {
  @override
  Future<SetupDraft> build(SetupMode mode) async {
    // One read each (not watched): the save writes these settings, and the
    // draft must not reset under the user.
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
    return SetupDraft.initial(
      today: today,
      units: units,
      weekStart: weekStart,
      halal: halal,
      mode: mode,
      cityId: cityId,
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

  /// Lose / keep / gain, with the default pace prefilled (D9).
  void chooseGoal(GoalType type) => _edit(
    (d) =>
        d._copy(goal: d.goal.withType(type), justTrack: false, touched: true),
  );

  /// "Just see what I eat": no calorie target.
  void chooseJustTrack() =>
      _edit((d) => d._copy(justTrack: true, touched: true));

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

  /// The goal draft ("Change the numbers").
  void setGoal(GoalDraft goal) =>
      _edit((d) => d._copy(goal: goal, justTrack: false, touched: true));

  /// The training answer.
  void setTraining(TrainingChoice choice) =>
      _edit((d) => d._copy(training: choice, touched: true));

  /// Continue: the next page on the path once this one is complete (its
  /// skip mark cleared); otherwise this page shows its messages (UX-052).
  /// [SetupMove.finished] after the last question when there is nothing
  /// more to show.
  SetupMove next() => _move(skip: false);

  /// Skip: this question's answer isn't used; the next page on the path.
  SetupMove skip() => _move(skip: true);

  SetupMove _move({required bool skip}) {
    final draft = state.value;
    if (draft == null || draft.saving) return SetupMove.refused;
    // The account step has its own buttons; the plan is saved, or skipped
    // only when it can't be worked out.
    if (draft.page == SetupPage.account ||
        draft.saved ||
        (draft.page == SetupPage.plan && !skip)) {
      return SetupMove.refused;
    }
    if (!skip && !draft.canContinue) {
      state = AsyncData(draft._copy(showErrors: true));
      return SetupMove.refused;
    }
    final skipped = {...draft.skipped};
    if (skip) {
      skipped.add(draft.page);
    } else {
      skipped.remove(draft.page);
    }
    final moved = draft._copy(skipped: skipped, showErrors: false);
    final after = moved._after;
    if (after == null) {
      state = AsyncData(moved);
      return SetupMove.finished;
    }
    state = AsyncData(moved._copy(page: after));
    return SetupMove.moved;
  }

  /// The previous page; what was typed is kept. False on the first page
  /// (the screen closes) and after the save.
  bool back() {
    final draft = state.value;
    final before = draft?.before;
    if (draft == null || draft.saving || before == null) return false;
    state = AsyncData(draft._copy(page: before));
    return true;
  }

  /// Saves the plan as one change set with one undo entry (D10), or null
  /// when it can't be saved now. On success the first run moves to the
  /// account step.
  Future<TargetsOutcome?> save() async {
    final draft = state.value;
    final input = draft?.input;
    if (draft == null || input == null || !draft.canSave) return null;
    state = AsyncData(draft._copy(saving: true));
    TargetsOutcome? outcome;
    try {
      return outcome = await ref
          .read(targetsActionsProvider)
          .completeSetup(input);
    } finally {
      if (ref.mounted) {
        final now = state.value;
        if (now != null) {
          final done = outcome is TargetsDone;
          state = AsyncData(
            now._copy(
              saving: false,
              saved: done ? true : null,
              page: done && now.mode == SetupMode.firstRun
                  ? SetupPage.account
                  : null,
            ),
          );
        }
      }
    }
  }
}
