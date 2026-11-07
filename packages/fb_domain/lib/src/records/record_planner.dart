import 'package:fb_domain/src/body/weigh_in.dart';
import 'package:fb_domain/src/body/weigh_in_ops.dart';
import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/chat/memory_item_ops.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/diary_ops.dart';
import 'package:fb_domain/src/diary/food_ref.dart';
import 'package:fb_domain/src/diary/meal_slot.dart';
import 'package:fb_domain/src/diary/provenance.dart';
import 'package:fb_domain/src/food/food_state.dart';
import 'package:fb_domain/src/food/personal_food.dart';
import 'package:fb_domain/src/food/personal_food_ops.dart';
import 'package:fb_domain/src/math/rounding.dart';
import 'package:fb_domain/src/nutrition/nutrients.dart';
import 'package:fb_domain/src/proposals/day_hint.dart';
import 'package:fb_domain/src/proposals/proposal_input.dart'
    show ProposalIdSource;
import 'package:fb_domain/src/records/record_plan.dart';
import 'package:fb_domain/src/records/record_request.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/units/food_measures.dart';
import 'package:fb_domain/src/units/units.dart';

/// The slot a hint names among the active slots of [mode]: by ID, default
/// key or name (normalized), as the food engine matches it. `null` when
/// none does.
String? matchSlotHint(
  String? hint,
  Iterable<MealSlot> slots,
  SlotMode mode,
  String Function(String) normalize,
) {
  if (hint == null || hint.trim().isEmpty) return null;
  final want = normalize(hint);
  return slots
      .where(
        (s) =>
            s.active &&
            s.mode == mode &&
            (normalize(s.id) == want ||
                normalize(s.defaultKey ?? '') == want ||
                normalize(s.name ?? '') == want),
      )
      .firstOrNull
      ?.id;
}

/// The memory key of a statement (A67 D11): a default's question kind
/// (`<dimension>:<group>`, the engine's), a portion's food, or the
/// normalized subject. `null` when it names nothing.
String? memoryKeyOf(MemoryRecord r, String Function(String) normalize) {
  final subject = r.subject == null ? '' : normalize(r.subject!);
  final group = r.foodGroup ?? (subject.isEmpty ? null : subject);
  switch (r.memoryKind) {
    case MemoryKinds.defaultValue:
      final dimension = r.dimension;
      if (dimension == null || group == null) return null;
      return '$dimension:$group';
    case MemoryKinds.portion:
      return group;
    default:
      return subject.isEmpty ? null : subject;
  }
}

/// Plans record cards (A67 D1–D11): pure, deterministic code over the
/// frozen [RecordFacts]. Every op pins the versions the card shows; new
/// rows get their IDs from [ProposalIdSource] here, once.
abstract final class RecordPlanner {
  /// The plan of [request] over [facts]. [choice] is a which-one pick;
  /// [path] the batch path the user chose on the card.
  static RecordPlan plan(
    RecordRequest request,
    RecordFacts facts,
    ProposalIdSource ids, {
    String? choice,
    BatchPath? path,
  }) {
    try {
      return switch (request) {
        EditRecord() => _edit(request, facts, choice),
        DeleteRecord() => _delete(request, facts, choice),
        AmbiguousRecord() => _ambiguous(request, facts, ids, choice),
        CopyRecord() => _copy(request, facts, ids),
        SavedMealLogRecord() => _savedMealLog(request, facts, ids),
        SavedMealCreateRecord() => _savedMealCreate(request, facts, ids),
        BatchRecord() => _batch(request, facts, ids, path),
        BatchPortionRecord() => _batchPortion(request, facts, ids),
        BatchCloseRecord() => _batchClose(request, facts),
        PersonalFoodRecord() => _personalFood(request, facts),
        MemoryRecord() => _memory(request, facts),
        WeighInRecord() => _weighIn(request, facts, ids),
      };
      // A value outside an op's rules (a bound, an ID) is a request this
      // version can't plan; its content never leaves here.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return RecordPlan.failed(request.kind, RecordIssue.invalid);
    }
  }

  // ---- days and slots ----

  /// The day [hint] names (today when `null`), or `null` when it can't.
  static LocalDate? _day(String? hint, RecordFacts f) =>
      hint == null ? f.now.localDate : DayHint.resolve(hint, f.now.localDate);

  static EntryWhen _when(LocalDate date, RecordFacts f) =>
      date == f.now.localDate ? EntryWhen.at(f.now) : EntryWhen.onDay(date);

  static String? _slot(String? hint, RecordFacts f) =>
      matchSlotHint(hint, f.slots, f.mode, f.normalize);

  static Set<String> _words(String text, RecordFacts f) => {
    for (final w in f.normalize(text).split(' '))
      if (w.length >= 2) w,
  };

  // ---- diary entries ----

  static RecordAmount _of(DiaryEntry e) =>
      RecordAmount(e.amount.input, e.snapshot.kcal);

  /// The entries [targets] name, or (none) the reference's day and slot
  /// whose names share a word with the mention (all of the slot when none
  /// does). `null` when a target is missing.
  static List<DiaryEntry>? _targets(
    List<String> targets,
    RecordReference reference,
    RecordFacts f,
  ) {
    if (targets.isNotEmpty) {
      final out = <DiaryEntry>[];
      for (final id in targets) {
        final e = f.entries[id];
        if (e == null) return null;
        out.add(e);
      }
      return out;
    }
    final day = _day(reference.when.dateHint, f);
    if (day == null) return null;
    final slot = _slot(reference.when.slotHint, f);
    final pool = [
      for (final e in f.dayEntries)
        if (e.localDate == day && (slot == null || e.slotId == slot)) e,
    ];
    final words = _words(reference.mention, f);
    final named = [
      for (final e in pool)
        if (_words(
          '${e.food.names.en} ${e.food.names.ar ?? ''}',
          f,
        ).intersection(words).isNotEmpty)
          e,
    ];
    if (named.isNotEmpty) return named;
    return slot == null ? const [] : pool;
  }

  /// Which entries a lookup gave: all of them ([all] or one), or a pick.
  static RecordPlan? _pick(
    RecordKind kind,
    List<DiaryEntry>? found,
    bool all,
    String? choice,
    void Function(List<DiaryEntry>) use,
  ) {
    if (found == null || found.isEmpty) {
      return RecordPlan.failed(kind, RecordIssue.notFound);
    }
    if (found.length == 1 || all) {
      use(found);
      return null;
    }
    final picked = found.where((e) => e.id == choice).firstOrNull;
    if (picked != null) {
      use([picked]);
      return null;
    }
    return RecordPlan(
      RecordView(
        kind: kind,
        choices: [for (final e in found.take(6)) RecordChoice(e)],
      ),
      const [],
    );
  }

  static RecordPlan _edit(EditRecord r, RecordFacts f, String? choice) {
    var entries = const <DiaryEntry>[];
    final asked = _pick(
      r.kind,
      _targets(r.targets, r.reference, f),
      r.reference.all || r.targets.isNotEmpty,
      choice,
      (e) => entries = e,
    );
    if (asked != null) return asked;
    return _editEntries(r, entries, f);
  }

  static RecordPlan _editEntries(
    EditRecord r,
    List<DiaryEntry> entries,
    RecordFacts f,
  ) {
    final kind = r.kind;
    LocalDate? toDate;
    String? toSlot;
    final notes = <RecordNote>{};
    if (r.move case final move?) {
      if (move.dateHint != null) {
        toDate = _day(move.dateHint, f);
        if (toDate == null) return RecordPlan.failed(kind, RecordIssue.invalid);
      }
      if (move.slotHint != null) {
        toSlot = _slot(move.slotHint, f);
        if (toSlot == null) return RecordPlan.failed(kind, RecordIssue.invalid);
      }
      if (move.timeHint != null) notes.add(RecordNote.timeIgnored);
    }
    final ops = <ChangeOp>[];
    final lines = <RecordLine>[];
    for (final e in entries) {
      EntryAmount? amount;
      EntryFood? food;
      if (r.replace) {
        final swap = f.replacements[e.id];
        if (swap == null) return RecordPlan.failed(kind, RecordIssue.notFound);
        food = swap.food;
        amount = swap.amount;
        if (swap.estimate) notes.add(RecordNote.estimate);
      }
      if (r.amount case final stated?) {
        amount = _amount(e, stated, food);
        if (amount == null) {
          return RecordPlan.failed(kind, RecordIssue.unsupportedUnit);
        }
      }
      final date = toDate != null && toDate != e.localDate ? toDate : null;
      final slot = toSlot != null && toSlot != e.slotId ? toSlot : null;
      final sameAmount =
          amount == null ||
          (amount.amount == e.amount.amount &&
              amount.input == e.amount.input &&
              food == null);
      if (sameAmount && food == null && date == null && slot == null) continue;
      ops.add(
        UpdateDiaryEntry(
          e.id,
          e.version,
          EntryPatch(
            amount: sameAmount && food == null ? null : amount,
            food: food,
            slotId: slot,
            localDate: date,
          ),
        ),
      );
      final per100 = (food ?? e.food).per100;
      final after = amount ?? e.amount;
      lines.add(
        RecordLine(
          names: e.food.names,
          newNames: food?.names,
          before: _of(e),
          after: RecordAmount(after.input, per100.kcal * after.amount / 100),
          date: e.localDate,
          slotId: e.slotId,
          toDate: date,
          toSlotId: slot,
        ),
      );
    }
    if (ops.isEmpty) return RecordPlan.failed(kind, RecordIssue.noChange);
    return RecordPlan(
      RecordView(
        kind: kind,
        date: entries.first.localDate,
        slotId: entries.first.slotId,
        lines: lines,
        notes: notes,
      ),
      ops,
    );
  }

  /// [stated] as [e]'s amount (on [food]'s basis when it's swapped): the
  /// entry's own unit by ratio, else a mass or volume on its basis.
  static EntryAmount? _amount(
    DiaryEntry e,
    RecordAmountInput stated,
    EntryFood? food,
  ) {
    final q = stated.quantity;
    if (q == null) return null;
    final basis = e.amount.basis;
    final input = e.amount.input;
    double? amount;
    if (q.unitCode == input.unitCode && input.amount > 0) {
      amount = e.amount.amount * q.amount / input.amount;
    } else {
      final own =
          MassUnit.fromCode(input.unitCode) == null &&
          VolumeUnit.fromCode(input.unitCode) == null &&
          input.amount > 0 &&
          e.amount.amount > 0;
      final per = own ? e.amount.amount / input.amount : 0.0;
      final measures = FoodMeasures(
        basis: basis,
        servingUnits: [
          if (own && basis == NutrientBasis.per100g)
            ServingUnit.grams(input.unitCode, per)
          else if (own)
            ServingUnit.milliliters(input.unitCode, per),
        ],
      );
      if (measures.resolve(q) case Resolved(amount: final a)) {
        amount = a;
      }
    }
    if (amount == null || !amount.isFinite || amount <= 0) return null;
    return EntryAmount(
      input: q,
      amount: StoragePrecision.round(amount),
      basis: basis,
    );
  }

  static RecordPlan _delete(DeleteRecord r, RecordFacts f, String? choice) {
    var entries = const <DiaryEntry>[];
    final asked = _pick(
      r.kind,
      _targets(r.targets, r.reference, f),
      r.reference.all || r.targets.isNotEmpty,
      choice,
      (e) => entries = e,
    );
    if (asked != null) return asked;
    return _deleteEntries(r.kind, entries);
  }

  static RecordPlan _deleteEntries(RecordKind kind, List<DiaryEntry> entries) =>
      RecordPlan(
        RecordView(
          kind: kind,
          date: entries.first.localDate,
          slotId: entries.first.slotId,
          lines: [
            for (final e in entries)
              RecordLine(
                names: e.food.names,
                before: _of(e),
                date: e.localDate,
                slotId: e.slotId,
              ),
          ],
        ),
        [
          DeleteEntries([
            for (final e in entries) VersionedId(e.id, e.version),
          ]),
        ],
      );

  static RecordPlan _ambiguous(
    AmbiguousRecord r,
    RecordFacts f,
    ProposalIdSource ids,
    String? choice,
  ) {
    final candidates = [for (final id in r.candidates) ?f.entries[id]];
    if (candidates.isEmpty) {
      return RecordPlan.failed(r.kind, RecordIssue.notFound);
    }
    final picked = candidates.where((e) => e.id == choice).firstOrNull;
    if (picked == null) {
      return RecordPlan(
        RecordView(
          kind: r.kind,
          choices: [for (final e in candidates.take(6)) RecordChoice(e)],
        ),
        const [],
      );
    }
    final plan = switch (r.then) {
      final EditRecord edit => _editEntries(edit, [picked], f),
      _ => _deleteEntries(r.kind, [picked]),
    };
    final view = plan.view;
    if (view == null) return plan;
    return RecordPlan(
      RecordView(
        kind: r.kind,
        date: view.date,
        slotId: view.slotId,
        lines: view.lines,
        notes: view.notes,
      ),
      plan.ops,
    );
  }

  // ---- copy and saved meals ----

  static RecordPlan _copy(CopyRecord r, RecordFacts f, ProposalIdSource ids) {
    final fromDate = _day(r.source.dateHint, f);
    final fromSlot = _slot(r.source.slotHint, f);
    if (fromDate == null) return RecordPlan.failed(r.kind, RecordIssue.invalid);
    if (fromSlot == null) {
      return RecordPlan.failed(r.kind, RecordIssue.noSource);
    }
    final toDate = _day(r.target.dateHint, f);
    if (toDate == null) return RecordPlan.failed(r.kind, RecordIssue.invalid);
    final toSlot = r.target.slotHint == null
        ? null
        : _slot(r.target.slotHint, f);
    if (r.target.slotHint != null && toSlot == null) {
      return RecordPlan.failed(r.kind, RecordIssue.invalid);
    }
    final entries = [
      for (final e in f.dayEntries)
        if (e.localDate == fromDate && e.slotId == fromSlot) e,
    ];
    if (entries.isEmpty) return RecordPlan.failed(r.kind, RecordIssue.notFound);
    if (toDate == fromDate && (toSlot == null || toSlot == fromSlot)) {
      return RecordPlan.failed(r.kind, RecordIssue.noChange);
    }
    final groupIds = {for (final e in entries) ?e.dishGroupId};
    final groups = [
      for (final g in f.groups)
        if (groupIds.contains(g.id) ||
            (g.localDate == fromDate && g.slotId == fromSlot))
          VersionedId(g.id, g.version),
    ];
    final expected = SourceVersions(
      entries: [for (final e in entries) VersionedId(e.id, e.version)],
      groups: groups,
    );
    final notes = {if (r.target.timeHint != null) RecordNote.timeIgnored};
    return RecordPlan(
      RecordView(
        kind: r.kind,
        date: fromDate,
        slotId: fromSlot,
        notes: notes,
        lines: [
          for (final e in entries)
            RecordLine(
              names: e.food.names,
              after: _of(e),
              date: fromDate,
              slotId: fromSlot,
              toDate: toDate,
              toSlotId: toSlot ?? fromSlot,
            ),
        ],
      ),
      [
        CopyMeal(
          MealSource.slot(fromDate, fromSlot),
          toDate: toDate,
          toSlotId: toSlot,
          expected: expected,
          copyIds: {
            for (final e in expected.entries) e.id: ids.next(),
            for (final g in expected.groups) g.id: ids.next(),
          },
        ),
      ],
    );
  }

  static RecordPlan _savedMealLog(
    SavedMealLogRecord r,
    RecordFacts f,
    ProposalIdSource ids,
  ) {
    final meal = f.savedMeal;
    if (meal == null || meal.id != r.savedMealId) {
      return RecordPlan.failed(r.kind, RecordIssue.notFound);
    }
    if (r.shared) {
      return RecordPlan.failed(r.kind, RecordIssue.unsupportedShare);
    }
    final versions = meal.versions;
    if (versions == null) return RecordPlan.failed(r.kind, RecordIssue.invalid);
    final date = _day(r.when.dateHint, f);
    if (date == null) return RecordPlan.failed(r.kind, RecordIssue.invalid);
    final slot = _slot(r.when.slotHint, f);
    return RecordPlan(
      RecordView(
        kind: r.kind,
        date: date,
        slotId: slot,
        title: meal.name,
        savedMeal: meal,
        notes: {if (r.when.timeHint != null) RecordNote.timeIgnored},
        lines: [
          for (final i in meal.items)
            RecordLine(
              names: i.food.names,
              after: RecordAmount(i.amount.input, i.snapshot.kcal),
              toDate: date,
              toSlotId: slot,
            ),
        ],
      ),
      [
        LogSavedMeal(
          expected: versions,
          entryIds: {for (final i in meal.items) i.id: ids.next()},
          when: _when(date, f),
          slotId: slot,
        ),
      ],
    );
  }

  static RecordPlan _savedMealCreate(
    SavedMealCreateRecord r,
    RecordFacts f,
    ProposalIdSource ids,
  ) {
    var name = r.name.trim();
    if (name.length > 60) name = name.substring(0, 60).trim();
    if (name.isEmpty) return RecordPlan.failed(r.kind, RecordIssue.invalid);
    List<DiaryEntry> entries;
    if (r.activeProposal != null) {
      final logged = f.cardEntries;
      if (logged == null) {
        return RecordPlan.failed(r.kind, RecordIssue.logFirst);
      }
      entries = logged;
    } else if (r.targets.isNotEmpty) {
      entries = [];
      for (final id in r.targets) {
        final e = f.entries[id];
        if (e == null) return RecordPlan.failed(r.kind, RecordIssue.notFound);
        entries.add(e);
      }
    } else {
      final source = r.source;
      final date = source == null ? null : _day(source.dateHint, f);
      final slot = source == null ? null : _slot(source.slotHint, f);
      if (date == null || slot == null) {
        return RecordPlan.failed(r.kind, RecordIssue.noSource);
      }
      entries = [
        for (final e in f.dayEntries)
          if (e.localDate == date && e.slotId == slot) e,
      ];
    }
    if (entries.isEmpty) return RecordPlan.failed(r.kind, RecordIssue.notFound);
    return RecordPlan(
      RecordView(
        kind: r.kind,
        date: entries.first.localDate,
        slotId: entries.first.slotId,
        title: name,
        lines: [
          for (final e in entries)
            RecordLine(names: e.food.names, after: _of(e)),
        ],
      ),
      [
        SaveMeal(
          savedMealId: ids.next(),
          name: name,
          source: MealSource.entries([for (final e in entries) e.id]),
          expected: SourceVersions(
            entries: [for (final e in entries) VersionedId(e.id, e.version)],
          ),
        ),
      ],
    );
  }

  // ---- batches ----

  /// Grams of [portion] of a batch weighing [whole] g; `null` when it
  /// can't be told.
  static double? _portionGrams(
    RecordPortion portion,
    double? whole,
    Set<RecordNote> notes,
  ) {
    if (portion.amount case final a?) {
      final q = a.quantity;
      if (q == null) return null;
      if (q.unitCode == 'plate') {
        notes.add(RecordNote.plateAssumed);
        return q.amount * batchPlateGrams;
      }
      if (MassUnit.fromCode(q.unitCode) case final mass?) {
        return q.amount * mass.grams;
      }
      return null;
    }
    if (whole == null) return null;
    if (portion.fraction case final fr? when fr > 0 && fr <= 1) {
      return whole * fr;
    }
    if (portion.people case final n? when n > 0) return whole / n;
    return null;
  }

  static NewDiaryEntry _batchEntry(
    String id,
    PersonalFoodDraft draft,
    String foodId,
    double grams,
    RecordDayHint when,
    RecordFacts f,
  ) {
    final date = _day(when.dateHint, f) ?? f.now.localDate;
    final g = StoragePrecision.round(grams);
    return NewDiaryEntry(
      id: id,
      when: _when(date, f),
      slotId: _slot(when.slotHint, f),
      food: EntryFood(
        ref: FoodRef.personal(foodId),
        names: draft.names,
        per100: draft.per100,
        provenance: Provenance(source: FoodSource.yours),
      ),
      amount: EntryAmount(
        input: Quantity(g, 'g'),
        amount: g,
        basis: NutrientBasis.per100g,
      ),
    );
  }

  static PersonalFoodDraft _withCreatedFrom(
    PersonalFoodDraft d,
    String createdFrom,
  ) => PersonalFoodDraft(
    names: d.names,
    per100: d.per100,
    state: d.state,
    basis: d.basis,
    aliases: d.aliases,
    brand: d.brand,
    barcodes: d.barcodes,
    servings: d.servings,
    entryServing: d.entryServing,
    createdFrom: createdFrom,
  );

  static RecordPlan _batch(
    BatchRecord r,
    RecordFacts f,
    ProposalIdSource ids,
    BatchPath? picked,
  ) {
    final lines = f.foodLines;
    if (lines.isEmpty) return RecordPlan.failed(r.kind, RecordIssue.invalid);
    final notes = <RecordNote>{};
    var total = Nutrients.zero;
    var raw = 0.0;
    var rawKnown = true;
    for (final l in lines) {
      total = total + l.snapshot;
      // A volume counts through its density only (A67 review 4).
      if (l.grams case final g?) {
        raw += g;
      } else {
        rawKnown = false;
      }
      if (l.estimate) notes.add(RecordNote.estimate);
    }
    double? whole;
    if (r.cooked?.quantity case final q?) {
      final mass = MassUnit.fromCode(q.unitCode);
      if (mass == null) {
        return RecordPlan.failed(r.kind, RecordIssue.unsupportedUnit);
      }
      whole = q.amount * mass.grams;
    } else {
      if (!rawKnown) {
        return RecordPlan.failed(r.kind, RecordIssue.noTotalWeight);
      }
      whole = raw;
      notes.add(RecordNote.rawWeight);
    }
    if (whole <= 0) return RecordPlan.failed(r.kind, RecordIssue.invalid);
    var name = (r.name ?? '').trim();
    if (name.isEmpty) {
      name = [for (final l in lines.take(3)) l.food.names.en].join(', ');
    }
    if (name.length > PersonalFoodBounds.name) {
      name = name.substring(0, PersonalFoodBounds.name).trim();
    }
    final path =
        picked ??
        r.path ??
        (r.eatenNow == null ? BatchPath.leftovers : BatchPath.quick);
    double? eaten;
    if (r.eatenNow case final portion?) {
      eaten = _portionGrams(portion, whole, notes);
      if (eaten == null) {
        return RecordPlan.failed(r.kind, RecordIssue.unsupportedUnit);
      }
    } else if (path == BatchPath.quick) {
      eaten = whole;
    }
    if (eaten != null && eaten > whole) eaten = whole;
    final remaining = whole - (eaten ?? 0);
    final closed = path == BatchPath.quick || remaining <= 0;
    notes.add(
      path == BatchPath.quick ? RecordNote.quickPath : RecordNote.leftovers,
    );
    final per100 = total.scale(100 / whole);
    final draft = PersonalFoodDraft(
      names: FoodNames(name),
      per100: per100,
      state: FoodState.cooked,
      servings: [
        if (whole >= PersonalFoodBounds.minServing &&
            whole <= PersonalFoodBounds.maxServing)
          PersonalFoodServing('serving', StoragePrecision.round(whole)),
      ],
      createdFrom: closed ? BatchFacts.closedCode : BatchFacts.openCode,
    );
    if (draft.validate() != null) {
      return RecordPlan.failed(r.kind, RecordIssue.invalid);
    }
    final foodId = ids.next();
    return RecordPlan(
      RecordView(
        kind: r.kind,
        date: _day(r.when.dateHint, f),
        slotId: _slot(r.when.slotHint, f),
        title: name,
        notes: notes,
        lines: [
          for (final l in lines)
            RecordLine(
              names: l.food.names,
              after: RecordAmount(l.amount.input, l.snapshot.kcal),
            ),
        ],
        batch: BatchView(
          name: name,
          wholeGrams: whole,
          per100: per100,
          path: path,
          eatenGrams: eaten,
          remainingGrams: closed ? 0 : remaining,
        ),
      ),
      [
        CreatePersonalFood(foodId, draft),
        if (eaten != null && eaten > 0)
          LogEntries([
            _batchEntry(ids.next(), draft, foodId, eaten, r.when, f),
          ]),
      ],
    );
  }

  static RecordPlan _batchPortion(
    BatchPortionRecord r,
    RecordFacts f,
    ProposalIdSource ids,
  ) {
    final batch = f.batch;
    if (batch == null || batch.food.id != r.batchId) {
      return RecordPlan.failed(r.kind, RecordIssue.notFound);
    }
    if (!batch.openAt(f.now.occurredAtUtc)) {
      return RecordPlan.failed(r.kind, RecordIssue.notOpen);
    }
    final notes = <RecordNote>{};
    final remaining = batch.remainingGrams;
    double? grams;
    if (r.rest) {
      if (remaining == null) {
        return RecordPlan.failed(r.kind, RecordIssue.noTotalWeight);
      }
      grams = remaining;
    } else if (r.portion case final p?) {
      grams = _portionGrams(p, batch.wholeGrams, notes);
      if (grams == null) {
        return RecordPlan.failed(
          r.kind,
          p.amount == null
              ? RecordIssue.noTotalWeight
              : RecordIssue.unsupportedUnit,
        );
      }
    }
    if (grams == null || grams <= 0) {
      return RecordPlan.failed(r.kind, RecordIssue.invalid);
    }
    final left = remaining == null ? null : remaining - grams;
    final closes = r.rest || (left != null && left <= 0.5);
    if (closes) notes.add(RecordNote.closesBatch);
    final food = batch.food;
    return RecordPlan(
      RecordView(
        kind: r.kind,
        date: _day(r.when.dateHint, f),
        slotId: _slot(r.when.slotHint, f),
        title: food.names.en,
        notes: notes,
        batch: BatchView(
          name: food.names.en,
          wholeGrams: batch.wholeGrams,
          per100: food.per100,
          eatenGrams: grams,
          remainingGrams: left == null ? null : (left < 0 ? 0 : left),
        ),
      ),
      [
        // The remainder this portion was planned on (A67 review 2).
        RequirePersonalFood(
          VersionedId(food.id, food.version),
          consumption: batch.consumption,
        ),
        if (closes)
          UpdatePersonalFood(
            food.id,
            food.version,
            _withCreatedFrom(food.draft, BatchFacts.closedCode),
          ),
        LogEntries([
          _batchEntry(ids.next(), food.draft, food.id, grams, r.when, f),
        ]),
      ],
    );
  }

  static RecordPlan _batchClose(BatchCloseRecord r, RecordFacts f) {
    final batch = f.batch;
    if (batch == null || batch.food.id != r.batchId) {
      return RecordPlan.failed(r.kind, RecordIssue.notFound);
    }
    final food = batch.food;
    if (food.createdFrom != BatchFacts.openCode) {
      return RecordPlan.failed(r.kind, RecordIssue.notOpen);
    }
    return RecordPlan(
      RecordView(
        kind: r.kind,
        title: food.names.en,
        batch: BatchView(
          name: food.names.en,
          wholeGrams: batch.wholeGrams,
          per100: food.per100,
          remainingGrams: batch.remainingGrams,
        ),
      ),
      [
        UpdatePersonalFood(
          food.id,
          food.version,
          _withCreatedFrom(food.draft, BatchFacts.closedCode),
        ),
      ],
    );
  }

  // ---- personal foods, memory, weigh-ins ----

  static RecordPlan _personalFood(PersonalFoodRecord r, RecordFacts f) {
    final name = r.name.trim();
    if (name.isEmpty) return RecordPlan.failed(r.kind, RecordIssue.invalid);
    Nutrients? per100;
    var basis = NutrientBasis.per100g;
    final notes = <RecordNote>{};
    Nutrients? totals;
    if (f.foodLines.isNotEmpty) {
      var total = Nutrients.zero;
      double? grams = 0;
      for (final l in f.foodLines) {
        total = total + l.snapshot;
        final g = l.grams;
        grams = grams == null || g == null ? null : grams + g;
        if (l.estimate) notes.add(RecordNote.estimate);
      }
      // A volume without a density: never added as grams; the form asks
      // for the whole weight instead (A67 review 4).
      if (grams != null && grams > 0) {
        per100 = total.scale(100 / grams);
      } else {
        totals = total;
      }
    }
    if (r.stated case final s?) {
      basis =
          s.basis == 'per100ml' ||
              (s.basis == 'perServing' &&
                  s.servingG == null &&
                  s.servingMl != null)
          ? NutrientBasis.per100ml
          : NutrientBasis.per100g;
    }
    if (per100 == null && totals == null && r.stated == null) {
      return RecordPlan.failed(r.kind, RecordIssue.invalid);
    }
    return RecordPlan(
      RecordView(
        kind: r.kind,
        title: name,
        notes: notes,
        food: FoodView(
          name: name.length > PersonalFoodBounds.name
              ? name.substring(0, PersonalFoodBounds.name).trim()
              : name,
          aliases: [
            for (final a in r.aliases)
              if (a.trim().isNotEmpty &&
                  a.trim().length <= PersonalFoodBounds.name)
                a.trim(),
          ],
          basis: basis,
          per100: per100,
          stated: r.stated,
          totals: r.stated == null ? totals : null,
        ),
      ),
      // Confirmed in the personal-food form (A67 D8).
      const [],
    );
  }

  static RecordPlan _memory(MemoryRecord r, RecordFacts f) {
    if (!memoryChangeKinds.contains(r.memoryKind)) {
      return RecordPlan.failed(r.kind, RecordIssue.invalid);
    }
    final key = memoryKeyOf(r, f.normalize);
    final subject = (r.foodName ?? r.subject ?? '').trim();
    if (r.forget) {
      final group =
          r.foodGroup ?? (r.subject == null ? null : f.normalize(r.subject!));
      final matches = [
        for (final m in f.memory)
          if (m.kind == r.memoryKind &&
              (m.key == key ||
                  (r.memoryKind == MemoryKinds.defaultValue &&
                      r.dimension == null &&
                      group != null &&
                      m.key.endsWith(':$group'))))
            m,
      ];
      if (matches.isEmpty) {
        return RecordPlan.failed(r.kind, RecordIssue.nothingToForget);
      }
      return RecordPlan(
        RecordView(
          kind: r.kind,
          memory: MemoryView(
            forget: true,
            kind: r.memoryKind,
            subject: subject.isEmpty ? matches.first.key : subject,
            dimension: r.dimension,
            items: matches,
          ),
        ),
        [for (final m in matches) DeleteMemoryItem(m.id, m.version)],
      );
    }
    if (key == null) return RecordPlan.failed(r.kind, RecordIssue.invalid);
    String? value;
    switch (r.memoryKind) {
      case MemoryKinds.portion:
        if (r.amount?.quantity case final q?) {
          value = '${_number(q.amount)} ${q.unitCode}';
        }
      case MemoryKinds.defaultValue:
        value = r.value?.trim();
        if (r.amount?.quantity case final q? when value != null) {
          // The engine's option code for a fat amount.
          value = '$value:${q.amount}:${q.unitCode}';
        }
      default:
        value = r.value?.trim();
    }
    if (value == null || value.isEmpty) {
      return RecordPlan.failed(r.kind, RecordIssue.invalid);
    }
    // The row as this card shows it (A67 review): confirm refuses when it
    // changed or went meanwhile.
    final shown = f.memory
        .where((m) => m.kind == r.memoryKind && m.key == _cut(key))
        .firstOrNull;
    final op = SaveMemoryItem(
      kind: r.memoryKind,
      key: _cut(key),
      value: _cut(value),
      checked: true,
      expectedVersion: shown?.version,
    );
    if (op.validate() != null) {
      return RecordPlan.failed(r.kind, RecordIssue.invalid);
    }
    return RecordPlan(
      RecordView(
        kind: r.kind,
        memory: MemoryView(
          forget: false,
          kind: r.memoryKind,
          subject: subject.isEmpty ? key : subject,
          dimension: r.dimension,
          value: r.memoryKind == MemoryKinds.portion ? value : r.value?.trim(),
        ),
      ),
      [op],
    );
  }

  static String _cut(String s) => s.length <= MemoryItemOp.maxText
      ? s
      : s.substring(0, MemoryItemOp.maxText);

  static String _number(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  static RecordPlan _weighIn(
    WeighInRecord r,
    RecordFacts f,
    ProposalIdSource ids,
  ) {
    final unit = MassUnit.fromCode(r.unit);
    if (unit == null || !WeighInInput.units.contains(unit)) {
      return RecordPlan.failed(r.kind, RecordIssue.unsupportedUnit);
    }
    final date = _day(r.when.dateHint, f);
    if (date == null) return RecordPlan.failed(r.kind, RecordIssue.invalid);
    final time = date == f.now.localDate ? f.now : f.now.onDate(date);
    final draft = WeighInDraft(time: time, input: WeighInInput(r.value, unit));
    if (draft.validate() != null) {
      return RecordPlan.failed(r.kind, RecordIssue.invalid);
    }
    return RecordPlan(
      RecordView(
        kind: r.kind,
        date: date,
        notes: {if (r.when.timeHint != null) RecordNote.timeIgnored},
        weighIn: WeighInView(
          draft: draft,
          trendDeltaKg: f.trendKg == null ? null : draft.kg - f.trendKg!,
        ),
      ),
      [CreateWeighIn(ids.next(), draft)],
    );
  }
}
