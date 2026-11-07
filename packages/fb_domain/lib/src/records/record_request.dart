import 'package:fb_domain/src/chat/memory_item_ops.dart';
import 'package:fb_domain/src/units/food_measures.dart';

/// The record kinds Buddy proposes besides food logs (A67, `spec/10`
/// §4.6, §7–§9). Each code is the contract's intent `kind`.
enum RecordKind {
  /// Change entries (AI-050).
  diaryEdit('diaryEdit'),

  /// Delete entries (AI-051).
  diaryDelete('diaryDelete'),

  /// Which entry? then edit or delete it (AI-091).
  ambiguousReference('ambiguousReference'),

  /// Copy a meal (AI-090).
  diaryCopy('diaryCopy'),

  /// Log a saved meal (DY-031).
  savedMealLog('savedMealLog'),

  /// Save entries as a meal (DY-032).
  savedMealCreate('savedMealCreate'),

  /// A home-cooked batch (AI-100).
  batch('batch'),

  /// A portion of an open batch (AI-102).
  batchPortion('batchPortion'),

  /// Close a batch (DY-044).
  batchClose('batchClose'),

  /// A personal food (AI-054).
  personalFoodCreate('personalFoodCreate'),

  /// Remember or forget (AI-055).
  memoryChange('memoryChange'),

  /// A weigh-in (AI-052).
  weighIn('weighIn');

  new(this.code);

  /// The intent kind.
  final String code;

  /// The kind of [code], or `null` for another one.
  static RecordKind? fromCode(Object? code) {
    for (final k in values) {
      if (k.code == code) return k;
    }
    return null;
  }
}

/// A day, slot and time as Buddy said them (the contract's `BuddyDayHint`).
final class RecordDayHint {
  /// The hints; every member optional.
  const new({this.dateHint, this.slotHint, this.timeHint});

  /// The closed day grammar (`DayHint`), or `null` (today).
  final String? dateHint;

  /// A slot name, default key or ID, or `null`.
  final String? slotHint;

  /// A literal time phrase (not resolved in R1).
  final String? timeHint;

  @override
  String toString() => 'RecordDayHint';
}

/// How the message named diary entries (`BuddyEntryReference`).
final class RecordReference {
  /// The reference.
  const new({required this.mention, required this.when, this.all = false});

  /// The user's words. User content.
  final String mention;

  /// The day and slot it named.
  final RecordDayHint when;

  /// `scope: all`.
  final bool all;

  @override
  String toString() => 'RecordReference';
}

/// An amount as stated: [value] of [unit] (a unit code).
final class RecordAmountInput {
  /// The amount.
  const new(this.value, this.unit);

  /// The number.
  final double value;

  /// The unit code (`g`, `kg`, `ml`, `piece`, `plate`, …).
  final String unit;

  /// As a typed quantity, or `null` when it can't be one.
  Quantity? get quantity =>
      value.isFinite && value > 0 ? Quantity(value, unit) : null;

  @override
  String toString() => 'RecordAmountInput';
}

/// A portion of a batch (`BuddyPortion`): grams/plates, or a share.
final class RecordPortion {
  /// The portion; at least one member.
  const new({this.amount, this.fraction, this.people});

  /// Grams, plates, …
  final RecordAmountInput? amount;

  /// A fraction of the whole batch.
  final double? fraction;

  /// "We were N": one Nth of the whole batch.
  final int? people;

  @override
  String toString() => 'RecordPortion';
}

/// What a record card is asked to do, typed from the contract's intent
/// (the app maps the generated `BuddyIntent`). User content: never logged.
sealed class RecordRequest {
  const new _();

  /// The kind.
  RecordKind get kind;
}

/// `diaryEdit`: [targets] (empty: look up by [reference]) get the new
/// [amount], a replacement food (built by the app, `RecordFacts`) when
/// [replace], and/or a [move].
final class EditRecord extends RecordRequest {
  /// The edit.
  const new({
    required this.targets,
    required this.reference,
    this.amount,
    this.replace = false,
    this.move,
  }) : super._();

  /// Entry IDs.
  final List<String> targets;

  /// How they were named.
  final RecordReference reference;

  /// The new absolute amount.
  final RecordAmountInput? amount;

  /// Whether the food is swapped.
  final bool replace;

  /// Where to move them.
  final RecordDayHint? move;

  @override
  RecordKind get kind => RecordKind.diaryEdit;
}

/// `diaryDelete`.
final class DeleteRecord extends RecordRequest {
  /// The delete.
  const new({required this.targets, required this.reference}) : super._();

  /// Entry IDs.
  final List<String> targets;

  /// How they were named.
  final RecordReference reference;

  @override
  RecordKind get kind => RecordKind.diaryDelete;
}

/// `ambiguousReference`: one of [candidates], then [then] on it.
final class AmbiguousRecord extends RecordRequest {
  /// The question.
  const new({
    required this.candidates,
    required this.reference,
    required this.then,
  }) : super._();

  /// Entry IDs.
  final List<String> candidates;

  /// How they were named.
  final RecordReference reference;

  /// The edit or delete for the picked entry (its targets are ignored).
  final RecordRequest then;

  @override
  RecordKind get kind => RecordKind.ambiguousReference;
}

/// `diaryCopy`: the meal at [source] to [target].
final class CopyRecord extends RecordRequest {
  /// The copy.
  const new({required this.source, required this.target}) : super._();

  /// Where from (a slot is required).
  final RecordDayHint source;

  /// Where to (`null` members: today, the source's slot).
  final RecordDayHint target;

  @override
  RecordKind get kind => RecordKind.diaryCopy;
}

/// `savedMealLog`.
final class SavedMealLogRecord extends RecordRequest {
  /// The log.
  const new({
    required this.savedMealId,
    required this.when,
    this.shared = false,
  }) : super._();

  /// The saved meal.
  final String savedMealId;

  /// When.
  final RecordDayHint when;

  /// A share was stated (not supported yet).
  final bool shared;

  @override
  RecordKind get kind => RecordKind.savedMealLog;
}

/// `savedMealCreate`: [name] from [targets], a [source] slot, or the
/// [activeProposal] card's logged entries.
final class SavedMealCreateRecord extends RecordRequest {
  /// The save.
  const new({
    required this.name,
    this.targets = const [],
    this.source,
    this.activeProposal,
  }) : super._();

  /// The meal's name. User content.
  final String name;

  /// Entry IDs.
  final List<String> targets;

  /// A day and slot.
  final RecordDayHint? source;

  /// A card ID.
  final String? activeProposal;

  @override
  RecordKind get kind => RecordKind.savedMealCreate;
}

/// Quick or leftovers (AI-100).
enum BatchPath {
  /// Log now and be done (DY-042).
  quick,

  /// Keep it open for later portions (DY-043).
  leftovers,
}

/// `batch`: ingredients come as the app's engine lines (`RecordFacts`).
final class BatchRecord extends RecordRequest {
  /// The batch.
  const new({
    required this.when,
    this.name,
    this.cooked,
    this.path,
    this.eatenNow,
  }) : super._();

  /// Its name, or `null` (the ingredients name it). User content.
  final String? name;

  /// The cooked weight stated.
  final RecordAmountInput? cooked;

  /// The path Buddy suggested.
  final BatchPath? path;

  /// What was eaten now.
  final RecordPortion? eatenNow;

  /// When it was eaten.
  final RecordDayHint when;

  @override
  RecordKind get kind => RecordKind.batch;
}

/// `batchPortion`: [portion], or the [rest].
final class BatchPortionRecord extends RecordRequest {
  /// The portion.
  const new({
    required this.batchId,
    required this.when,
    this.portion,
    this.rest = false,
  }) : super._();

  /// The batch (a personal food ID).
  final String batchId;

  /// How much.
  final RecordPortion? portion;

  /// The rest of it.
  final bool rest;

  /// When.
  final RecordDayHint when;

  @override
  RecordKind get kind => RecordKind.batchPortion;
}

/// `batchClose`.
final class BatchCloseRecord extends RecordRequest {
  /// The close.
  const new(this.batchId) : super._();

  /// The batch.
  final String batchId;

  @override
  RecordKind get kind => RecordKind.batchClose;
}

/// The figures a user stated for a personal food (TD-092).
final class StatedFigures {
  /// The figures; `null` members weren't stated.
  const new({
    required this.basis,
    this.servingG,
    this.servingMl,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
  });

  /// `per100g`, `per100ml` or `perServing`.
  final String basis;

  /// Serving grams.
  final double? servingG;

  /// Serving ml.
  final double? servingMl;

  /// kcal.
  final double? kcal;

  /// Protein g.
  final double? protein;

  /// Carbs g.
  final double? carbs;

  /// Fat g.
  final double? fat;

  /// Fiber g.
  final double? fiber;

  @override
  String toString() => 'StatedFigures';
}

/// `personalFoodCreate`: components come as engine lines (`RecordFacts`).
final class PersonalFoodRecord extends RecordRequest {
  /// The food.
  const new({required this.name, this.aliases = const [], this.stated})
    : super._();

  /// Its name. User content.
  final String name;

  /// Other names.
  final List<String> aliases;

  /// Stated figures.
  final StatedFigures? stated;

  @override
  RecordKind get kind => RecordKind.personalFoodCreate;
}

/// `memoryChange` (AI-055).
final class MemoryRecord extends RecordRequest {
  /// The statement.
  const new({
    required this.forget,
    required this.memoryKind,
    this.subject,
    this.dimension,
    this.value,
    this.amount,
    this.foodGroup,
    this.foodName,
  }) : super._();

  /// Forget rather than remember.
  final bool forget;

  /// `default`, `portion`, `alias`, `brand`, `nickname`.
  final String memoryKind;

  /// The user's words for the subject.
  final String? subject;

  /// `state`, `fat`, `variant`, `portion` (defaults only).
  final String? dimension;

  /// The value.
  final String? value;

  /// A portion or fat amount.
  final RecordAmountInput? amount;

  /// The matched food's yield group or key.
  final String? foodGroup;

  /// The matched food's name.
  final String? foodName;

  @override
  RecordKind get kind => RecordKind.memoryChange;
}

/// `weighIn` (AI-052).
final class WeighInRecord extends RecordRequest {
  /// The weigh-in.
  const new({required this.value, required this.unit, required this.when})
    : super._();

  /// The value as said.
  final double value;

  /// `kg` or `lb`.
  final String unit;

  /// When.
  final RecordDayHint when;

  @override
  RecordKind get kind => RecordKind.weighIn;
}

/// The memory kinds a `memoryChange` names (the contract's enum).
const Set<String> memoryChangeKinds = {
  MemoryKinds.defaultValue,
  MemoryKinds.portion,
  MemoryKinds.alias,
  MemoryKinds.brand,
  MemoryKinds.nickname,
};
