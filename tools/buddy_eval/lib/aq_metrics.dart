/// B09b engine-level AQ metrics. The raw `/v1/buddy/interpret` response map
/// (exactly what the phone decodes, D17) runs through the real fb_domain
/// `ProposalEvaluation` with production policy, and the result is compared
/// with the case's `aq` block (D18–D24, PA17–PA22).
///
/// Reports carry case IDs, item indexes, catalog keys, counts and closed
/// reason codes only: never message text, mentions or food names.
library;

import 'dart:convert';

import 'package:buddy_eval/public_eval.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_text/fb_text.dart';

/// The metrics the checker gates (thresholds live only in the checker, D22).
const List<String> aqGatedMetrics = [
  'AQ-02',
  'AQ-03',
  'AQ-04',
  'AQ-06',
  'AQ-07',
  'AQ-08',
  'AQ-10',
];

/// Per-language breakdown keys (AQ-11 is reported only in R1).
const List<String> aqLanguageGroups = ['en', 'ar', 'arabizi'];

/// AQ-06 `asks` vocabulary: engine dimension kinds plus a routed clarify
/// (PA17).
final Set<String> aqAskKinds = {
  for (final kind in ProposalDimensionKind.values) kind.name,
  'clarify',
};

/// The request's zone offset (`publicInterpretBody` sends 180).
const int aqTzOffsetMin = 180;

/// Release facts the adapter reads: the imported pack's version, its dish
/// count (AQ-05) and its yield rows (D19).
final class AqRelease {
  const new({
    required this.version,
    required this.dishes,
    required this.yields,
  });

  final int version;
  final int dishes;
  final List<YieldFactor> yields;
}

/// Parses `release/manifest.json` and `release/yields.jsonl` (pure; the CLI
/// reads the files). The yield row count must equal the manifest's (S2).
AqRelease parseAqRelease({
  required String manifest,
  required String yieldsJsonl,
}) {
  final root = jsonDecode(manifest) as PublicJson;
  final files = root['files'] as PublicJson;
  final expected = (files['yields.jsonl'] as PublicJson)['count'] as int;
  final rows = [
    for (final line in const LineSplitter().convert(yieldsJsonl))
      if (line.trim().isNotEmpty) jsonDecode(line) as PublicJson,
  ];
  if (rows.length != expected) {
    throw const FormatException('Yield rows differ from the manifest count.');
  }
  FoodState state(Object? code) =>
      FoodState.fromCode(code! as String) ??
      (throw const FormatException('Unknown yield state.'));
  return AqRelease(
    version: root['catalog_version'] as int,
    dishes: (root['counts'] as PublicJson)['dishes'] as int,
    yields: [
      for (final row in rows)
        YieldFactor(
          group: row['yield_group'] as String,
          from: state(row['from_state']),
          to: state(row['to_state']),
          factor: (row['factor'] as num).toDouble(),
        ),
    ],
  );
}

/// The production policy: `/v1/config` thresholds, built-in defaults for
/// absent keys (0.20 / 50 kcal, TD-081; S1).
ProposalPolicy aqPolicy(Map<String, double> thresholds) =>
    ProposalPolicy.fromThresholds(thresholds);

/// Deterministic per-case allocator: `019a0000-0001-7000-8000-<n:12>` (D18).
final class AqIdSource implements ProposalIdSource {
  var _next = 0;

  @override
  String next() {
    final suffix = (++_next).toRadixString(16).padLeft(12, '0');
    return '019a0000-0001-7000-8000-$suffix';
  }
}

/// One expected food item or generated component (D21).
final class AqItem {
  const new({
    required this.estimate,
    this.keys = const {},
    this.at,
    this.amount,
    this.weighed,
  });

  factory fromJson(PublicJson json) {
    final at = json['at'] as String?;
    final amount = json['amount'] as PublicJson?;
    final weighed = json['weighed'] as PublicJson?;
    final parts = at?.split('/');
    return AqItem(
      estimate: json['estimate'] == true,
      keys: {...?(json['keys'] as List<dynamic>?)?.cast<String>()},
      at: parts == null ? null : (int.parse(parts[0]), int.parse(parts[1])),
      amount: amount == null
          ? null
          : Quantity(
              (amount['value'] as num).toDouble(),
              amount['unit'] as String,
            ),
      weighed: weighed == null ? null : AqWeighed.fromJson(weighed),
    );
  }

  /// Expected an AI estimate line (the food is absent from the release).
  final bool estimate;

  /// Allowed catalog/personal keys (spec meaning + release facts, D23).
  final Set<String> keys;

  /// Intent/item index in the case's own `parsed` fixture (PA20).
  final (int, int)? at;

  /// Explicit amount and unit stated in the message (AQ-03).
  final Quantity? amount;

  /// AQ-04 fact stamp, when the item is weighed with a database match.
  final AqWeighed? weighed;

  /// Whether [line] identifies this food.
  bool accepts(ProposalLine line) {
    final food = line.entry.food;
    return estimate
        ? food.ref.kind == FoodRefKind.estimate &&
              food.provenance.source == FoodSource.estimate
        : keys.contains(food.ref.id);
  }
}

/// D24 drift guard: the reference kcal and the per-100 g kcal of every
/// allowed key at stamping time, plus the yield factor of a converted item.
final class AqWeighed {
  const new({required this.kcal, required this.per100Kcal, this.yieldFactor});

  factory fromJson(PublicJson json) => AqWeighed(
    kcal: (json['kcal'] as num).toDouble(),
    per100Kcal: {
      for (final e in (json['per100Kcal'] as PublicJson).entries)
        e.key: (e.value as num).toDouble(),
    },
    yieldFactor: (json['yieldFactor'] as num?)?.toDouble(),
  );

  final double kcal;
  final Map<String, double> per100Kcal;
  final double? yieldFactor;
}

/// A case's `aq` block.
final class AqExpectation {
  const new({
    required this.ambiguous,
    required this.asks,
    required this.savedDefaults,
    required this.items,
    required this.components,
  });

  factory fromCase(PublicJson test) {
    final aq = test['aq'] as PublicJson;
    List<AqItem> list(String key) => [
      for (final raw in (aq[key] as List<dynamic>?) ?? const <dynamic>[])
        AqItem.fromJson(raw as PublicJson),
    ];
    return AqExpectation(
      ambiguous: aq['ambiguous'] as bool?,
      asks: [...?(aq['asks'] as List<dynamic>?)?.cast<String>()],
      savedDefaults: {
        ...?(aq['savedDefaults'] as PublicJson?)?.cast<String, String>(),
      },
      items: list('items'),
      components: list('components'),
    );
  }

  /// `true` = designed ambiguous (AQ-06), `false` = unambiguous (AQ-07),
  /// `null` = the spec says "only if"/"or" (neither).
  final bool? ambiguous;
  final List<String> asks;

  /// Engine vocabulary (questionKind → option value/code), not request memory.
  final Map<String, String> savedDefaults;
  final List<AqItem> items;
  final List<AqItem> components;
}

/// Case → `ProposalRequest` (D18): production policy, default slots, the
/// release's yields, embedded server facts (`packAvailable: false`, D20) and
/// the case's personal foods. No cooking-fat IDs: the release has none (D16).
ProposalRequest aqRequest({
  required PublicJson test,
  required Map<String, Object?> response,
  required String messageId,
  required DateTime now,
  required List<YieldFactor> yields,
  required ProposalPolicy policy,
}) => ProposalRequest(
  interpretation: response,
  messageId: messageId,
  idSource: AqIdSource(),
  context: ProposalContext(
    referenceTime: EntryTime(now.toUtc(), aqTzOffsetMin),
    slots: DefaultSlots.all,
    yields: yields,
    savedDefaults: AqExpectation.fromCase(test).savedDefaults,
    normalize: normalizeKey,
  ),
  facts: ProposalFacts(personal: aqPersonalFoods(test)),
  policy: policy,
);

/// The case's request `context.personalFoods` as local personal rows
/// (personal version 1), the way the app's loader maps its own table.
Map<String, ProposalFood> aqPersonalFoods(PublicJson test) {
  final context = test['context'] as PublicJson?;
  final rows = ((context?['personalFoods'] as List<dynamic>?) ?? const [])
      .cast<PublicJson>();
  return {for (final row in rows) row['id'] as String: _personalFood(row)};
}

ProposalFood _personalFood(PublicJson row) {
  double number(Object? v) => (v! as num).toDouble();
  final n = row['nutrients'] as PublicJson;
  return ProposalFood(
    key: row['id'] as String,
    names: FoodNames((row['names'] as List<dynamic>).first as String),
    state:
        FoodState.fromCode(row['state'] as String) ??
        (throw const FormatException('Unknown personal food state.')),
    source: FoodSource.yours,
    per100: Nutrients(
      kcal: number(n['kcal']),
      protein: number(n['proteinG']),
      carbs: number(n['carbsG']),
      fat: number(n['fatG']),
      fiber: number(n['fiberG']),
    ),
    origin: ProposalFactOrigin.localPersonal,
    personalVersion: 1,
    servings: [
      for (final s in (row['servings'] as List<dynamic>).cast<PublicJson>())
        ProposalServing(
          s['unitCode'] as String,
          number(s['g'] ?? s['ml']),
          s['g'] != null ? NutrientBasis.per100g : NutrientBasis.per100ml,
          null,
          null,
        ),
    ],
  );
}

/// One graded unit: an item (`T02#1`), a case (`T11`) or an unbound line
/// (`T07#L2`), with a closed reason code when it missed.
typedef AqUnit = ({String metric, String unit, bool passed, String? code});

/// A case's graded units plus content-free run facts.
final class AqCaseResult {
  const new({
    required this.id,
    required this.group,
    required this.units,
    required this.facts,
  });

  final String id;
  final String group;
  final List<AqUnit> units;

  /// Question/clarify counts, the whole-message issue, card and line counts.
  final PublicJson facts;
}

/// Grades one case (D21, PA17–PA22). Never throws on engine outcomes: every
/// rejection is a miss with a code (R16).
AqCaseResult evaluateAqCase({
  required PublicJson test,
  required Map<String, Object?> response,
  required String messageId,
  required DateTime now,
  required List<YieldFactor> yields,
  required ProposalPolicy policy,
}) {
  final id = test['id'] as String;
  final aq = AqExpectation.fromCase(test);
  final request = aqRequest(
    test: test,
    response: response,
    messageId: messageId,
    now: now,
    yields: yields,
    policy: policy,
  );
  final evaluation = ProposalEvaluation.evaluate(request);
  final session = evaluation.result.value;
  final failure = evaluation.result.issue == null
      ? null
      : 'decode:${evaluation.result.issue!.name}';
  final decoded = request.interpretation.value?.intents;
  final raw = ((response['intents'] as List<dynamic>?) ?? const <dynamic>[])
      .cast<PublicJson>();
  final units = <AqUnit>[];
  void add(String metric, String unit, String? missCode) => units.add((
    metric: metric,
    unit: unit,
    passed: missCode == null,
    code: missCode,
  ));

  ProposalItem? decodedItem((int, int)? at) {
    if (decoded == null || at == null || at.$1 >= decoded.length) return null;
    final items = decoded[at.$1].items;
    return at.$2 < items.length ? items[at.$2] : null;
  }

  String? clarifyAt((int, int)? at) {
    if (at == null || at.$1 >= raw.length) return null;
    final intent = raw[at.$1];
    return intent['kind'] == 'clarify' ? 'clarify:${intent['reason']}' : null;
  }

  final placed = <({ProposalCard card, ProposalLine line, int index})>[];
  for (final card in session?.cards ?? const <ProposalCard>[]) {
    for (final line in card.lines) {
      placed.add((card: card, line: line, index: placed.length));
    }
  }
  final consumed = <int>{};
  ({ProposalCard card, ProposalLine line, int index})? take(AqItem item) {
    final hit = placed
        .where((p) => !consumed.contains(p.index) && item.accepts(p.line))
        .firstOrNull;
    if (hit != null) consumed.add(hit.index);
    return hit;
  }

  String keyOf(ProposalLine line) => line.entry.food.ref.id ?? 'estimate';

  // AQ-02: ordered greedy match, each expected item takes the first
  // unconsumed line with its identity (D21). Misses name the most specific
  // closed cause: whole message, clarified intent, missing item, the item's
  // own line (by its dimension IDs) or match with another key, card issue.
  final bound = <int, ({ProposalCard card, ProposalLine line, int index})>{};
  final aq02Codes = <int, String>{};
  for (final (k, item) in aq.items.indexed) {
    final hit = take(item);
    if (hit != null) {
      bound[k] = hit;
      add('AQ-02', '$id#$k', null);
      continue;
    }
    final source = decodedItem(item.at);
    String code;
    if (failure != null) {
      code = failure;
    } else if (clarifyAt(item.at) case final clarify?) {
      code = clarify;
    } else if (source == null) {
      code = 'noItem';
    } else {
      final own = placed
          .where(
            (p) =>
                !consumed.contains(p.index) &&
                p.line.dimensions.any(
                  (d) =>
                      d.kind != ProposalDimensionKind.oilRetention &&
                      d.id.startsWith('${source.id}/'),
                ),
          )
          .firstOrNull;
      final matched = source.match?.key;
      if (own != null) {
        code = 'key:${keyOf(own.line)}';
      } else if (item.estimate
          ? matched != null
          : !item.keys.contains(matched)) {
        code = 'key:${matched ?? 'estimate'}';
      } else {
        code = firstCardIssueCode(session);
      }
    }
    aq02Codes[k] = code;
    add('AQ-02', '$id#$k', code);
  }

  // Components (S4): generated lines (e.g. oil from a saved default), any
  // order, outside AQ-02's denominator.
  for (final (k, component) in aq.components.indexed) {
    add(
      'components',
      '$id#c$k',
      take(component) != null ? null : failure ?? firstCardIssueCode(session),
    );
  }

  // AQ-03: the decoded item bound by `at` (PA20).
  for (final (k, item) in aq.items.indexed) {
    final expected = item.amount;
    if (expected == null) continue;
    final source = decodedItem(item.at);
    add(
      'AQ-03',
      '$id#$k',
      source == null
          ? failure ?? clarifyAt(item.at) ?? 'noItem'
          : !source.explicit
          ? 'amount:implicit'
          : source.quantity != expected
          ? 'amount:${_quantityCode(source.quantity)}'
          : null,
    );
  }

  // AQ-04: weighed database matches; the state is settled by authoring
  // (PA21), the stamp guards drift (D24), the card must be clean.
  for (final (k, item) in aq.items.indexed) {
    final weighed = item.weighed;
    if (weighed == null) continue;
    final hit = bound[k];
    String? code;
    if (hit == null) {
      code = aq02Codes[k];
    } else {
      final line = hit.line;
      final per100 = line.entry.food.per100.kcal;
      final stamp = weighed.per100Kcal[line.entry.food.ref.id];
      final factor = line.yieldNote?.factor;
      if (stamp == null || per100 != stamp) {
        code =
            'stale:${_number(per100)}/'
            '${stamp == null ? 'none' : _number(stamp)}';
      } else if (weighed.yieldFactor != null && factor != weighed.yieldFactor) {
        code =
            'stale:yield:${factor == null ? 'none' : _number(factor)}/'
            '${_number(weighed.yieldFactor!)}';
      } else if (hit.card.issues.isNotEmpty) {
        code = 'cardIssue:${hit.card.issues.first.name}';
      } else if ((line.snapshot.kcal - weighed.kcal).abs() >
          0.10 * weighed.kcal) {
        code =
            'kcal:${_number(line.snapshot.kcal)}/'
            '${_number(weighed.kcal)}';
      }
    }
    add('AQ-04', '$id#$k', code);
  }

  // AQ-06/07/08: engine questions plus routed clarifies (PA18).
  final asked = [
    for (final q in session?.budget.questions ?? const <ProposalQuestion>[])
      q.questionKind.split(':').first,
    if (session != null)
      for (final intent in session.routing)
        if (intent.kind == 'clarify') 'clarify',
  ];
  final askedCode = 'asked:${asked.join('+')}';
  if (aq.ambiguous == true) {
    add(
      'AQ-06',
      id,
      failure ??
          (asked.isEmpty
              ? 'notAsked'
              : aq.asks.every(asked.contains)
              ? null
              : askedCode),
    );
  } else if (aq.ambiguous == false) {
    add('AQ-07', id, failure ?? (asked.isEmpty ? null : askedCode));
  }
  add('AQ-08', id, asked.length > 2 ? askedCode : null);

  // AQ-10: every estimate/reference line, and every line produced by a
  // decoded item with an assumed amount (PA22), whatever its identity.
  units.addAll(
    aq10Units(
      id: id,
      lines: [for (final p in placed) p.line],
      items: [
        for (final (i, intent) in (decoded ?? const []).indexed)
          for (final (j, item) in intent.items.indexed)
            (at: (i, j), item: item),
      ],
      expected: aq.items,
    ),
  );

  return AqCaseResult(
    id: id,
    group: languageGroup(test),
    units: units,
    facts: {
      'questions': evaluation.questionCount,
      'clarify': asked.where((k) => k == 'clarify').length,
      'issue': evaluation.result.issue?.name,
      'cards': session?.cards.length ?? 0,
      'lines': placed.length,
    },
  );
}

/// A decoded item and its intent/item index in the response.
typedef AqDecodedItem = ({(int, int) at, ProposalItem item});

/// Binds produced lines to the decoded items that made them, independently
/// of whether the identity is right (AQ-02's business): items in message
/// order each take the first unconsumed line whose food is the item's own
/// match, one of its state/variant option foods, or an estimate for an
/// unmatched item. Generated component lines (oil) bind to no item.
Map<int, AqDecodedItem> aqLineSources(
  List<ProposalLine> lines,
  List<AqDecodedItem> items,
) {
  final sources = <int, AqDecodedItem>{};
  for (final source in items) {
    final item = source.item;
    final keys = {
      ?item.match?.key,
      for (final d in item.dimensions)
        for (final o in d.options)
          if (o.effect case ProposalFoodEffect(:final food)) food.key,
    };
    for (final (n, line) in lines.indexed) {
      if (sources.containsKey(n)) continue;
      final ref = line.entry.food.ref;
      final own = item.match == null
          ? ref.kind == FoodRefKind.estimate
          : keys.contains(ref.id);
      if (own) {
        sources[n] = source;
        break;
      }
    }
  }
  return sources;
}

/// AQ-10 units: every estimate/reference line and every line whose source
/// item's amount was assumed (`!explicit || quantity == null`, PA22) must be
/// marked. Lines of an expected item are named `case#k`, others `case#Ln`.
List<AqUnit> aq10Units({
  required String id,
  required List<ProposalLine> lines,
  required List<AqDecodedItem> items,
  required List<AqItem> expected,
}) {
  final sources = aqLineSources(lines, items);
  final units = <AqUnit>[];
  for (final (n, line) in lines.indexed) {
    final source = sources[n];
    final assumed =
        source != null &&
        (!source.item.explicit || source.item.quantity == null);
    if (!aq10Eligible(line, assumed: assumed)) continue;
    final k = source == null
        ? -1
        : expected.indexWhere((e) => e.at == source.at);
    final marked = aq10Marked(line);
    units.add((
      metric: 'AQ-10',
      unit: k < 0 ? '$id#L$n' : '$id#$k',
      passed: marked,
      code: marked ? null : 'unmarked',
    ));
  }
  return units;
}

/// The first card issue as a code, or `noLine` when every card is clean.
String firstCardIssueCode(ProposalSession? session) {
  final issue = (session?.cards ?? const <ProposalCard>[])
      .expand((c) => c.issues)
      .firstOrNull;
  return issue == null ? 'noLine' : 'cardIssue:${issue.name}';
}

/// AQ-10 eligibility: an estimate ref, an estimate/reference source, or an
/// assumed amount (PA22).
bool aq10Eligible(ProposalLine line, {required bool assumed}) {
  final food = line.entry.food;
  return assumed ||
      food.ref.kind == FoodRefKind.estimate ||
      food.provenance.source == FoodSource.estimate ||
      food.provenance.source == FoodSource.reference;
}

/// AQ-10 pass: marked as an estimate and carrying a range.
bool aq10Marked(ProposalLine line) =>
    line.entry.food.provenance.isEstimate &&
    line.entry.food.provenance.range != null;

/// `passed/eligible`, or `n/a` for an empty group.
String aqRate(PublicJson counts) => counts['eligible'] == 0
    ? 'n/a'
    : '${counts['passed']}/${counts['eligible']}';

/// The AQ report (`kind: aq`): counts per metric overall and per language,
/// misses as `unit code`, plus content-free rows.
PublicJson summarizeAq({
  required List<PublicJson> rows,
  required List<AqCaseResult> results,
  required String mode,
  required String caseFile,
  required AqRelease release,
  required ProposalPolicy policy,
}) {
  PublicJson block(String metric) {
    final units = [
      for (final r in results)
        for (final u in r.units)
          if (u.metric == metric) (group: r.group, unit: u),
    ];
    PublicJson counts(Iterable<({String group, AqUnit unit})> selected) => {
      'passed': selected.where((u) => u.unit.passed).length,
      'eligible': selected.length,
    };
    return {
      'overall': counts(units),
      for (final group in aqLanguageGroups)
        group: counts(units.where((u) => u.group == group)),
      'misses': [
        for (final u in units)
          if (!u.unit.passed) '${u.unit.unit} ${u.unit.code}',
      ],
    };
  }

  final times = rows.map((r) => r['elapsedMs'] as int).toList()..sort();
  return {
    'kind': 'aq',
    'mode': mode,
    'caseFile': caseFile,
    'scope':
        'Engine-level AQ metrics: recorded interpretations through the real '
        'API, catalog and fb_domain ProposalEngine; fixtures, not model '
        'quality.',
    'catalog': {'version': release.version, 'dishes': release.dishes},
    'policy': {
      'relativeDelta': policy.relativeDelta,
      'kcalDelta': policy.kcalDelta,
    },
    'cases': rows.length,
    'p90Ms': times.isEmpty ? null : times[(times.length * .9).ceil() - 1],
    'metrics': {
      'AQ-01': {'status': 'structural', 'reason': 'evalPathHasNoApplier'},
      for (final metric in aqGatedMetrics.take(3)) metric: block(metric),
      'AQ-05': {
        'status': 'n/a',
        'reason': 'noReferenceDishes',
        'dishes': release.dishes,
      },
      for (final metric in aqGatedMetrics.skip(3)) metric: block(metric),
    },
    'components': block('components'),
    'rows': rows,
  };
}

String _number(double value) =>
    value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

String _quantityCode(Quantity? quantity) => quantity == null
    ? 'none'
    : '${_number(quantity.amount)}${quantity.unitCode}';
