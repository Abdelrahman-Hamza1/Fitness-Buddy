import 'package:fb_domain/fb_domain.dart';

/// One option of a Buddy suggestion (AI-120) as the reply shows it: Buddy's
/// label, the `foodLog` intent a tap turns into a card, and the code's
/// numbers for it (kcal, protein) from a preview build. Holds user content:
/// content-free [toString].
final class SuggestionOption {
  /// An option.
  const new({
    required this.label,
    required this.intent,
    required this.kcal,
    required this.protein,
    this.unknownSource = false,
    this.picked = false,
  });

  /// Buddy's label (≤ 120, guarded by the server).
  final String label;

  /// The `foodLog` intent a tap builds the card from.
  final Map<String, Object?> intent;

  /// The option's energy, computed by the app.
  final double kcal;

  /// Its protein, computed by the app.
  final double protein;

  /// With the halal setting on: a food may hold gelatin or emulsifiers of
  /// unknown source (FD-081, a warning).
  final bool unknownSource;

  /// Tapped in this session (its card is in the thread).
  final bool picked;

  /// A copy, [picked] or not.
  SuggestionOption copyWith({required bool picked}) => SuggestionOption(
    label: label,
    intent: intent,
    kcal: kcal,
    protein: protein,
    unknownSource: unknownSource,
    picked: picked,
  );

  /// The JSON form (kept in the reply's local `answer_json`).
  Map<String, Object?> toJson() => {
    'label': label,
    'intent': intent,
    'kcal': kcal,
    'protein': protein,
    if (unknownSource) 'unknownSource': true,
  };

  /// The option of [json], or `null` when it isn't one.
  static SuggestionOption? fromJson(Object? json) => switch (json) {
    {
      'label': final String label,
      'intent': final Map<String, Object?> intent,
      'kcal': final num kcal,
      'protein': final num protein,
    }
        when intent['kind'] == 'foodLog' =>
      SuggestionOption(
        label: label,
        intent: intent,
        kcal: kcal.toDouble(),
        protein: protein.toDouble(),
        unknownSource: json['unknownSource'] == true,
      ),
    _ => null,
  };

  @override
  String toString() => 'SuggestionOption()';
}

/// A reply's suggestion card (AI-120, A68 D5): the options that fit, of the
/// [offered] Buddy proposed. None left → "none of these fit".
final class BuddySuggestion {
  /// A suggestion.
  new({required List<SuggestionOption> options, required this.offered})
    : options = List.unmodifiable(options);

  /// The options kept, in Buddy's order (≤ 4).
  final List<SuggestionOption> options;

  /// How many options Buddy offered.
  final int offered;

  /// Whether every offered option was dropped.
  bool get noneFit => options.isEmpty;

  /// A copy with option [index] [picked] or not.
  BuddySuggestion withPicked(int index, {required bool picked}) =>
      BuddySuggestion(
        options: [
          for (final (i, o) in options.indexed)
            if (i == index) o.copyWith(picked: picked) else o,
        ],
        offered: offered,
      );

  /// The JSON form.
  Map<String, Object?> toJson() => {
    'offered': offered,
    'options': [for (final o in options) o.toJson()],
  };

  /// The suggestion of [json], or `null`.
  static BuddySuggestion? fromJson(Object? json) => switch (json) {
    {'offered': final int offered, 'options': final List<Object?> options} =>
      BuddySuggestion(
        options: [
          for (final o in options.take(maxOptions))
            ?SuggestionOption.fromJson(o),
        ],
        offered: offered,
      ),
    _ => null,
  };

  /// The most options a card shows (AI-120: 2–4).
  static const int maxOptions = 4;

  /// The card of a `suggestion` [intent] (raw JSON): each option becomes a
  /// `foodLog` intent with its items and slot hint, is built by [preview]
  /// (never written) and kept only when the card builds, fits what's left
  /// today ([SuggestionFit]) and, with [halal] on, names no pork or
  /// alcohol (FD-082); unknown-source ingredients stay with a warning.
  /// `null` when [intent] isn't a suggestion.
  static Future<BuddySuggestion?> of(
    Map<String, Object?> intent, {
    required Future<ProposalCard?> Function(Map<String, Object?> foodLog)
    preview,
    required bool halal,
  }) async {
    if (intent['kind'] != 'suggestion') return null;
    final raw = intent['options'];
    final options = [
      if (raw is List<Object?>)
        for (final o in raw.take(maxOptions))
          if (o
              case {
                'label': final String label,
                'items': final List<Object?> items,
              }
              when items.isNotEmpty && label.length <= 120)
            (label: label, slotHint: o['slotHint'], items: items),
    ];
    final kept = <SuggestionOption>[];
    for (final o in options) {
      final foodLog = <String, Object?>{
        'kind': 'foodLog',
        'language': intent['language'] ?? 'english',
        'script': intent['script'] ?? 'latin',
        'timeHint': null,
        'slotHint': o.slotHint is String ? o.slotHint : null,
        'dateHint': null,
        'dishGroup': null,
        'items': o.items,
      };
      final card = await preview(foodLog);
      if (card == null || !card.canConfirm) continue;
      if (!SuggestionFit.fits(
        remainingKcal: card.preview.remainingKcal,
        targetKcal: card.preview.targetKcal,
      )) {
        continue;
      }
      final flags = halal
          ? {
              for (final line in card.lines)
                ...HalalCheck.check(
                  name: line.entry.food.names.en,
                  nameAr: line.entry.food.names.ar,
                ),
            }
          : const <HalalFlag>{};
      if (flags.contains(HalalFlag.pork) || flags.contains(HalalFlag.alcohol)) {
        continue;
      }
      kept.add(
        SuggestionOption(
          label: o.label,
          intent: foodLog,
          kcal: card.totals.kcal,
          protein: card.totals.protein,
          unknownSource: flags.contains(HalalFlag.unknownSource),
        ),
      );
    }
    return BuddySuggestion(options: kept, offered: options.length);
  }

  @override
  String toString() => 'BuddySuggestion(${options.length}/$offered)';
}
