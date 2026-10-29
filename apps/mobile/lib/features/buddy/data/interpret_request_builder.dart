import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_text/fb_text.dart';

/// B08's request bounds (`InterpretRequest.Validate`, the contract's
/// operation description). The builder never sends a list or value outside
/// them: oversized lists are cut, values that can't fit are skipped.
abstract final class InterpretBounds {
  /// Slots.
  static const slots = 12;

  /// Personal foods.
  static const personalFoods = 30;

  /// Names per personal food.
  static const names = 5;

  /// Aliases per personal food.
  static const aliases = 10;

  /// Servings per personal food.
  static const servings = 20;

  /// Any name or value, in UTF-16 units (and never blank).
  static const value = 200;

  /// A per-100 nutrient value.
  static const double nutrient = 10000;

  /// A serving amount (exclusive of 0).
  static const double serving = 100000;
}

/// One interpret request, frozen when it's first sent: Try again replays
/// exactly this body with the same Idempotency-Key ([requestId], the user
/// message's ID). Holds user content: never logged.
final class PreparedInterpret {
  /// [body], keyed by its `requestId`.
  new(this.body);

  /// The request body.
  final InterpretRequest body;

  /// The Idempotency-Key and chat message ID.
  String get requestId => body.requestId;

  /// The wire JSON, nested maps only.
  Map<String, Object?> toJson() => body.toJson();

  @override
  String toString() => 'PreparedInterpret($requestId)';
}

/// Builds the minimum interpret context (A22 D10, `06` §1.3, AC-041) from
/// values already read: no I/O, so the request corpus
/// (`contracts/testdata/buddy/interpret-requests.json`) is generated from
/// exactly this code.
///
/// Sends the active slots of [SlotMode] (name = the user's name or the
/// default key; `window` when the slot has one), and the personal foods
/// whose normalized names or aliases share a word with the message. Saved
/// meals, open batches, memory, recent entries and custom exercises stay
/// empty (A25–A27, A37); Ramadan is inactive (A41); no active proposal
/// (A22b). No IDs other than row IDs, no account data.
abstract final class InterpretRequestBuilder {
  /// The request for message [requestId] with [text] (already sanitized:
  /// 1–1000 UTF-16 units, not blank) at [now].
  static PreparedInterpret build({
    required String requestId,
    required String text,
    required EntryTime now,
    required Iterable<MealSlot> slots,
    required Iterable<PersonalFood> personalFoods,
    SlotMode mode = SlotMode.normal,
  }) => PreparedInterpret(
    InterpretRequest(
      requestId: requestId,
      text: text,
      now: now.occurredAtUtc,
      tzOffsetMin: now.tzOffsetMin,
      ramadan: const BuddyRamadan(active: false, fajr: null, maghrib: null),
      slots: [
        for (final slot in slots)
          if (slot.active && slot.mode == mode) ?_slot(slot),
      ].take(InterpretBounds.slots).toList(),
      activeProposal: null,
      context: BuddyContext(
        personalFoods: matchingFoods(text, personalFoods),
        savedMeals: const [],
        openBatches: const [],
        memory: const [],
        recentEntries: const [],
        customExercises: const [],
      ),
    ),
  );

  /// The personal foods to send for [text]: those sharing a normalized word
  /// (2+ characters) with it, most shared words first, then by ID; at most
  /// [InterpretBounds.personalFoods], each within B08's bounds (matching
  /// aliases first when they must be cut). A food that can't be sent valid
  /// is skipped.
  static List<BuddyPersonalFood> matchingFoods(
    String text,
    Iterable<PersonalFood> foods,
  ) {
    final words = _words(text);
    if (words.isEmpty) return const [];
    final scored = <(int, PersonalFood)>[];
    for (final food in foods) {
      final shared = {
        for (final name in [..._names(food), ...food.aliases]) ..._words(name),
      }.intersection(words).length;
      if (shared > 0) scored.add((shared, food));
    }
    scored.sort(
      (a, b) =>
          a.$1 != b.$1 ? b.$1.compareTo(a.$1) : a.$2.id.compareTo(b.$2.id),
    );
    final out = <BuddyPersonalFood>[];
    for (final (_, food) in scored) {
      if (out.length == InterpretBounds.personalFoods) break;
      if (_food(food, words) case final f?) out.add(f);
    }
    return out;
  }

  static BuddySlot? _slot(MealSlot slot) {
    final name = (slot.name ?? slot.defaultKey ?? '').trim();
    if (!_fits(name)) return null;
    return BuddySlot(
      id: slot.id,
      name: name,
      window: switch (slot.window) {
        final w? => '${_hhmm(w.startMin)}-${_hhmm(w.endMin)}',
        null => null,
      },
    );
  }

  static BuddyPersonalFood? _food(PersonalFood food, Set<String> words) {
    final names = [
      for (final n in _names(food))
        if (n.trim() case final t when t.isNotEmpty) t,
    ];
    final matched = <String>[];
    final rest = <String>[];
    for (final alias in food.aliases.map((a) => a.trim())) {
      (_words(alias).intersection(words).isEmpty ? rest : matched).add(alias);
    }
    final aliases = [
      ...matched,
      ...rest,
    ].take(InterpretBounds.aliases).toList();
    final p = food.per100;
    final nutrients = [p.kcal, p.protein, p.carbs, p.fat, p.fiber];
    final units = [
      ...food.servings,
      if (food.entryServing case final e?)
        if (!food.servings.any((s) => s.unit == e.unit)) e,
    ];
    final servings = [
      for (final s in units)
        BuddyServing(
          unitCode: s.unit,
          g: food.basis == NutrientBasis.per100g ? s.amount : null,
          ml: food.basis == NutrientBasis.per100ml ? s.amount : null,
          rangeLo: null,
          rangeHi: null,
          source: 'personal',
        ),
    ];
    if (names.isEmpty ||
        names.length > InterpretBounds.names ||
        !names.every(_fits) ||
        !aliases.every(_fits) ||
        !_fits(food.state.code) ||
        servings.length > InterpretBounds.servings ||
        !nutrients.every(
          (v) => v.isFinite && v >= 0 && v <= InterpretBounds.nutrient,
        ) ||
        !units.every(
          (s) =>
              s.amount.isFinite &&
              s.amount > 0 &&
              s.amount <= InterpretBounds.serving,
        )) {
      return null;
    }
    return BuddyPersonalFood(
      id: food.id,
      names: names,
      aliases: aliases,
      state: food.state.code,
      nutrients: BuddyNutrients(
        kcal: p.kcal,
        proteinG: p.protein,
        carbsG: p.carbs,
        fatG: p.fat,
        fiberG: p.fiber,
      ),
      servings: servings,
    );
  }

  static List<String> _names(PersonalFood food) => [
    food.names.en,
    ?food.names.ar,
  ];

  /// The words of [text] that can tie it to a food: normalized, 2+
  /// characters, not a joining word ("rice with chicken" never pulls in
  /// "coffee with milk", A22a review).
  static Set<String> _words(String text) => {
    for (final w in normalizeKey(text).split(' '))
      if (w.length >= 2 && !_stopwords.contains(w)) w,
  };

  /// Joining words in English, Arabic and Arabizi, normalized like food
  /// names.
  static final Set<String> _stopwords = {
    for (final w in const [
      'with', 'and', 'of', 'the', 'an', 'in', 'on', 'or', 'some', 'my',
      'for', 'to', 'at', 'plus', 'without', //
      'مع', 'في', 'من', 'على', 'او', 'أو', 'بدون', //
      'ma3', 'm3', 'wa', 'fi', 'min', 'mn', '3la', 'aw', 'bdoon', 'bdun',
    ])
      normalizeKey(w),
  };

  static bool _fits(String value) =>
      value.trim().isNotEmpty && value.length <= InterpretBounds.value;

  static String _hhmm(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:'
      '${(minute % 60).toString().padLeft(2, '0')}';
}
