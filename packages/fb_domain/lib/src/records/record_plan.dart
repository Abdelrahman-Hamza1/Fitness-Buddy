import 'package:fb_domain/src/body/weigh_in.dart';
import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/chat/memory_item_ops.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/diary_ops.dart' show VersionedId;
import 'package:fb_domain/src/diary/meal_slot.dart';
import 'package:fb_domain/src/diary/saved_meal.dart';
import 'package:fb_domain/src/food/personal_food.dart';
import 'package:fb_domain/src/nutrition/nutrients.dart';
import 'package:fb_domain/src/records/record_request.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';
import 'package:fb_domain/src/units/food_measures.dart';

/// Why a record request can't be a card (codes only, never values).
enum RecordIssue {
  /// The entries, meal or batch it names aren't there.
  notFound,

  /// The amount's unit can't be turned into this food's amount.
  unsupportedUnit,

  /// A saved meal can't be split yet.
  unsupportedShare,

  /// No slot to copy or save from.
  noSource,

  /// "Save this" on a card that isn't logged yet.
  logFirst,

  /// Nothing would change.
  noChange,

  /// The batch is closed or expired.
  notOpen,

  /// The batch's whole weight isn't known.
  noTotalWeight,

  /// Nothing remembered matches.
  nothingToForget,

  /// The request breaks a rule (bounds, sanity, a missing member).
  invalid,
}

/// A note the card shows (codes; the app's ARB renders them).
enum RecordNote {
  /// A time was said but the entry keeps its time of day.
  timeIgnored,

  /// The batch's weight is its ingredients' raw sum (no cooked weight).
  rawWeight,

  /// This portion finishes the batch: it closes.
  closesBatch,

  /// The quick path: logged now, nothing kept.
  quickPath,

  /// Leftovers: the batch stays open for later portions.
  leftovers,

  /// A plate is counted as [batchPlateGrams] g.
  plateAssumed,

  /// An ingredient is an AI estimate.
  estimate,
}

/// A typical plate of a batch (DY-041: plates are estimated).
const batchPlateGrams = 350.0;

/// An amount and its energy.
final class RecordAmount {
  /// [input] (as typed) with [kcal].
  const new(this.input, this.kcal);

  /// The amount as typed.
  final Quantity input;

  /// Its kcal.
  final double kcal;

  @override
  String toString() => 'RecordAmount';
}

/// One line of a card: an entry before → after, or a new or removed one.
final class RecordLine {
  /// The line.
  const new({
    required this.names,
    this.before,
    this.after,
    this.newNames,
    this.date,
    this.slotId,
    this.toDate,
    this.toSlotId,
  });

  /// The food's names. User content.
  final FoodNames names;

  /// Before (`null` for a new line).
  final RecordAmount? before;

  /// After (`null` for a removed line).
  final RecordAmount? after;

  /// The new food's names (a swap).
  final FoodNames? newNames;

  /// Where it is.
  final LocalDate? date;

  /// Its slot.
  final String? slotId;

  /// Where it moves (a move or a copy).
  final LocalDate? toDate;

  /// Its new slot.
  final String? toSlotId;

  /// Whether the line goes.
  bool get removed => before != null && after == null;

  /// Whether the line is new.
  bool get added => before == null && after != null;

  @override
  String toString() => 'RecordLine';
}

/// An entry a which-one question offers (AI-091).
final class RecordChoice {
  /// The option.
  const new(this.entry);

  /// The entry.
  final DiaryEntry entry;

  /// Its ID.
  String get id => entry.id;

  @override
  String toString() => 'RecordChoice($id)';
}

/// A batch card's figures.
final class BatchView {
  /// The figures.
  const new({
    required this.name,
    required this.wholeGrams,
    required this.per100,
    this.path,
    this.eatenGrams,
    this.remainingGrams,
  });

  /// Its name. User content.
  final String name;

  /// The whole batch, g (`null` when unknown).
  final double? wholeGrams;

  /// Per 100 g.
  final Nutrients per100;

  /// The path (a new batch only).
  final BatchPath? path;

  /// Eaten now, g.
  final double? eatenGrams;

  /// Left afterwards, g.
  final double? remainingGrams;

  /// kcal of [eatenGrams].
  double? get eatenKcal =>
      eatenGrams == null ? null : per100.kcal * eatenGrams! / 100;

  @override
  String toString() => 'BatchView';
}

/// A personal-food card's figures (reviewed in the form).
final class FoodView {
  /// The figures.
  const new({
    required this.name,
    required this.aliases,
    required this.basis,
    this.per100,
    this.stated,
    this.totals,
  });

  /// The components' totals when their weight can't be told (a volume
  /// without a density): the form asks for the food's whole weight.
  final Nutrients? totals;

  /// Whether the form must ask for a serving size before saving: the
  /// figures are per serving (stated so, or the whole recipe) and the size
  /// isn't known (A67 review 3, 4).
  bool get needsServingSize =>
      totals != null ||
      (stated != null &&
          stated!.basis == 'perServing' &&
          !_validSize(stated!.servingG ?? stated!.servingMl));

  static bool _validSize(double? v) =>
      v != null &&
      v >= PersonalFoodBounds.minServing &&
      v <= PersonalFoodBounds.maxServing;

  /// Its name. User content.
  final String name;

  /// Other names.
  final List<String> aliases;

  /// g or ml.
  final NutrientBasis basis;

  /// Per 100 from the components, when built from them.
  final Nutrients? per100;

  /// The stated figures, when stated.
  final StatedFigures? stated;

  @override
  String toString() => 'FoodView';
}

/// A memory card's statement.
final class MemoryView {
  /// The statement.
  const new({
    required this.forget,
    required this.kind,
    required this.subject,
    this.dimension,
    this.value,
    this.items = const [],
  });

  /// Forget.
  final bool forget;

  /// The memory kind.
  final String kind;

  /// What it's about. User content.
  final String subject;

  /// `state`, `fat`, … (defaults).
  final String? dimension;

  /// The value. User content.
  final String? value;

  /// The items a forget removes.
  final List<MemoryItem> items;

  @override
  String toString() => 'MemoryView';
}

/// A weigh-in card's figures.
final class WeighInView {
  /// The figures.
  const new({required this.draft, this.trendDeltaKg});

  /// The weigh-in.
  final WeighInDraft draft;

  /// kg against the latest trend weight, when there is one.
  final double? trendDeltaKg;

  @override
  String toString() => 'WeighInView';
}

/// What a record card shows. User content: never logged.
final class RecordView {
  /// The view.
  const new({
    required this.kind,
    this.date,
    this.slotId,
    this.title,
    this.lines = const [],
    this.choices = const [],
    this.notes = const {},
    this.batch,
    this.food,
    this.memory,
    this.weighIn,
    this.savedMeal,
  });

  /// The kind.
  final RecordKind kind;

  /// The day it is about.
  final LocalDate? date;

  /// The slot.
  final String? slotId;

  /// A name (saved meal, batch, food). User content.
  final String? title;

  /// Before → after lines.
  final List<RecordLine> lines;

  /// Which-one options (the card waits for a pick).
  final List<RecordChoice> choices;

  /// Notes.
  final Set<RecordNote> notes;

  /// Batch figures.
  final BatchView? batch;

  /// Personal-food figures.
  final FoodView? food;

  /// Memory statement.
  final MemoryView? memory;

  /// Weigh-in figures.
  final WeighInView? weighIn;

  /// The saved meal logged.
  final SavedMeal? savedMeal;

  /// kcal after − before over the lines.
  double get kcalDelta => lines.fold(
    0,
    (sum, l) => sum + (l.after?.kcal ?? 0) - (l.before?.kcal ?? 0),
  );

  @override
  String toString() => 'RecordView(${kind.code})';
}

/// A card's plan: what it shows and the ops its confirm writes (with the
/// versions it showed), or why it can't be one.
final class RecordPlan {
  /// A buildable plan.
  new(RecordView this.view, this.ops) : kind = view.kind, issue = null;

  /// Not a card.
  const new failed(this.kind, RecordIssue this.issue)
    : view = null,
      ops = const [];

  /// The kind.
  final RecordKind kind;

  /// What it shows; `null` when it failed.
  final RecordView? view;

  /// What its confirm writes (empty: waits for a pick, or confirmed in
  /// the personal-food form).
  final List<ChangeOp> ops;

  /// Why it can't be a card.
  final RecordIssue? issue;

  /// Whether it waits for a which-one pick.
  bool get needsChoice => view?.choices.isNotEmpty ?? false;

  /// Whether the card can be confirmed with one tap.
  bool get canConfirm => issue == null && ops.isNotEmpty;

  @override
  String toString() => 'RecordPlan(${issue?.name ?? 'ok'})';
}

/// A batch on the phone: a personal food with `createdFrom` [openCode]
/// or [closedCode] (A67 D7).
final class BatchFacts {
  /// The batch's food, with [eatenGrams] already logged of it.
  const new({
    required this.food,
    required this.eatenGrams,
    required this.createdAt,
    this.consumption = const [],
  });

  /// The live diary entries of the food that [eatenGrams] sums, as read:
  /// a portion pins them, so a portion logged meanwhile re-plans the card.
  final List<VersionedId> consumption;

  /// `createdFrom` of an open batch.
  static const openCode = 'batch';

  /// `createdFrom` of a closed batch.
  static const closedCode = 'batchClosed';

  /// How long a batch stays open (DY-044).
  static const openFor = Duration(days: 7);

  /// The food.
  final PersonalFood food;

  /// Grams of live diary entries of it.
  final double eatenGrams;

  /// When it was created, UTC.
  final DateTime createdAt;

  /// The whole batch, g (its `serving`), or `null`.
  double? get wholeGrams =>
      food.servings.where((s) => s.unit == 'serving').firstOrNull?.amount;

  /// What's left, g, or `null` when the whole is unknown.
  double? get remainingGrams => switch (wholeGrams) {
    final w? => (w - eatenGrams) < 0 ? 0 : w - eatenGrams,
    null => null,
  };

  /// Whether it's still open at [nowUtc].
  bool openAt(DateTime nowUtc) =>
      food.createdFrom == openCode &&
      nowUtc.difference(createdAt) <= openFor &&
      (remainingGrams ?? 1) > 0;

  @override
  String toString() => 'BatchFacts';
}

/// One engine line the app built from a contract food item (an
/// ingredient, a component or a replacement).
final class RecordFoodLine {
  /// The line.
  const new({
    required this.food,
    required this.amount,
    required this.snapshot,
    this.estimate = false,
    this.density,
  });

  /// Grams per ml when known (a volume converts only through it).
  final double? density;

  /// Its weight in grams: the amount on a gram basis, a volume through
  /// [density]; `null` when it can't be told (A67 review 4).
  double? get grams => amount.basis == NutrientBasis.per100g
      ? amount.amount
      : density == null
      ? null
      : amount.amount * density!;

  /// The food.
  final EntryFood food;

  /// Its amount.
  final EntryAmount amount;

  /// Its nutrients.
  final Nutrients snapshot;

  /// An AI estimate.
  final bool estimate;

  @override
  String toString() => 'RecordFoodLine';
}

/// The local rows a plan reads, frozen in one snapshot. User content:
/// never logged.
final class RecordFacts {
  /// The facts.
  new({
    required this.now,
    required Iterable<MealSlot> slots,
    this.mode = SlotMode.normal,
    this.normalize = _plain,
    this.entries = const {},
    this.dayEntries = const [],
    this.groups = const [],
    this.savedMeal,
    this.batch,
    this.replacements = const {},
    this.foodLines = const [],
    this.memory = const [],
    this.trendKg,
    this.cardEntries,
  }) : slots = List.unmodifiable(slots);

  static String _plain(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  /// The message's time (today and "now").
  final EntryTime now;

  /// The slots.
  final List<MealSlot> slots;

  /// Normal or Ramadan slots.
  final SlotMode mode;

  /// The app's `normalizeKey`.
  final String Function(String) normalize;

  /// The entries the request names, by ID.
  final Map<String, DiaryEntry> entries;

  /// The live entries of the day a lookup or copy reads.
  final List<DiaryEntry> dayEntries;

  /// The live dish groups of that day.
  final List<DishGroup> groups;

  /// The saved meal a log names.
  final SavedMeal? savedMeal;

  /// The batch a portion or close names.
  final BatchFacts? batch;

  /// Each edit target's replacement food, by entry ID.
  final Map<String, RecordFoodLine> replacements;

  /// A batch's ingredients or a food's components.
  final List<RecordFoodLine> foodLines;

  /// Live memory items.
  final List<MemoryItem> memory;

  /// The latest trend weight, kg.
  final double? trendKg;

  /// The logged entries of an `activeProposal` card (`null`: not logged).
  final List<DiaryEntry>? cardEntries;

  @override
  String toString() => 'RecordFacts(redacted)';
}
