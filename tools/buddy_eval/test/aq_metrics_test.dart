import 'dart:convert';
import 'dart:io';

import 'package:buddy_eval/aq_metrics.dart';
import 'package:buddy_eval/public_eval.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

String _path(String relative) => Directory.current.path.endsWith('buddy_eval')
    ? relative
    : 'tools/buddy_eval/$relative';

/// Hand-built public responses with release-v6 facts (no server, no model).
PublicJson _fixture(String name) =>
    jsonDecode(File(_path('test/fixtures/aq/$name.json')).readAsStringSync())
        as PublicJson;

const _cooked = 'usda:rice_white_long_grain_cooked';
const _raw = 'usda:rice_white_long_grain_raw';
const _chicken = 'usda:chicken_breast_skinless_raw';
const _onion = 'usda:onion_raw';
const _oil = 'usda:olive_oil';
const _milk = 'usda:milk_whole';
const _message = '019a0000-0000-7000-8000-000000000001';
final _now = DateTime.utc(2026, 10, 21, 10);

PublicJson _clarify() => {
  'promptVersion': 'interpret-v2',
  'model': 'fixture',
  'intents': [
    {
      'kind': 'clarify',
      'language': 'english',
      'script': 'latin',
      'reason': 'unclear',
    },
  ],
};

PublicJson _case(
  PublicJson aq, {
  String id = 'T02',
  String text = '200g rice, 200g chicken breast raw, cooked with an onion',
  String script = 'latin',
}) => {
  'id': id,
  'text': text,
  'language': script == 'latin' ? 'english' : 'arabic',
  'script': script,
  'aq': aq,
};

PublicJson _aq({
  bool? ambiguous,
  List<String> asks = const [],
  Map<String, String> savedDefaults = const {},
  List<PublicJson> items = const [],
  List<PublicJson> components = const [],
}) => {
  'ambiguous': ambiguous,
  'asks': asks,
  'savedDefaults': savedDefaults,
  'items': items,
  'components': components,
};

PublicJson _item(String at, List<String> keys, {PublicJson? extra}) => {
  'at': at,
  'keys': keys,
  ...?extra,
};

AqCaseResult _run(
  PublicJson test,
  PublicJson response, {
  ProposalPolicy? policy,
}) => evaluateAqCase(
  test: test,
  response: response,
  messageId: _message,
  now: _now,
  yields: const [],
  policy: policy ?? aqPolicy(const {}),
);

List<AqUnit> _units(AqCaseResult result, String metric) =>
    result.units.where((u) => u.metric == metric).toList();

List<String?> _codes(AqCaseResult result, String metric) => [
  for (final u in _units(result, metric)) u.code,
];

AqRelease _release() =>
    const AqRelease(version: 6, dishes: 0, yields: <YieldFactor>[]);

PublicJson _summary(List<AqCaseResult> results) => summarizeAq(
  rows: [
    for (final r in results) {'id': r.id, 'elapsedMs': 5, 'engine': r.facts},
  ],
  results: results,
  mode: 'fixture',
  caseFile: 'm3',
  release: _release(),
  policy: aqPolicy(const {}),
);

ProposalLine _line(Provenance provenance, FoodRef ref) => ProposalLine(
  entry: NewDiaryEntry(
    id: '019a0000-0001-7000-8000-000000000001',
    when: EntryWhen.at(EntryTime(_now, aqTzOffsetMin)),
    food: EntryFood(
      ref: ref,
      names: FoodNames('synthetic'),
      per100: Nutrients.zero,
      provenance: provenance,
    ),
    amount: EntryAmount(
      input: Quantity(100, 'g'),
      amount: 100,
      basis: NutrientBasis.per100g,
    ),
  ),
  snapshot: Nutrients.zero,
  factOrigin: ProposalFactOrigin.embeddedServer,
  chips: const [],
);

void main() {
  test('AQ-02 line key in the expected set passes; wrong key, missing line '
      'and decode failure miss with their codes', () {
    final all = _run(
      _case(
        _aq(
          items: [
            _item('0/0', [_cooked, _raw]),
            _item('0/1', [_chicken]),
            _item('0/2', [_onion]),
          ],
        ),
      ),
      _fixture('rice_chicken'),
    );
    expect(_codes(all, 'AQ-02'), [null, null, null]);

    final wrong = _run(
      _case(
        _aq(
          items: [
            _item('0/1', ['usda:chicken_breast_raw']),
          ],
        ),
      ),
      _fixture('rice_chicken'),
    );
    expect(_codes(wrong, 'AQ-02'), ['key:$_chicken']);

    // 500 ml on a per-100 g food without a density: the breakfast card has an
    // issue and no milk line.
    final missing = _run(
      _case(
        _aq(
          items: [
            _item('1/0', [_milk]),
          ],
        ),
        id: 'T06',
      ),
      _fixture('dish_milk'),
    );
    expect(_codes(missing, 'AQ-02'), ['cardIssue:needsConversion']);

    final broken = _fixture('rice_chicken')..['promptVersion'] = 'interpret-x';
    final decode = _run(
      _case(
        _aq(
          ambiguous: false,
          items: [
            _item('0/1', [_chicken]),
          ],
        ),
      ),
      broken,
    );
    expect(_codes(decode, 'AQ-02'), ['decode:invalidInput']);
    expect(_codes(decode, 'AQ-07'), ['decode:invalidInput']);
  });

  test('AQ-02 expected estimate passes only on an estimate line', () {
    final estimate = _run(
      _case(
        _aq(
          items: [
            {'at': '0/0', 'estimate': true},
          ],
        ),
        id: 'T07',
      ),
      _fixture('dish_milk'),
    );
    expect(_codes(estimate, 'AQ-02'), [null]);

    final matched = _run(
      _case(
        _aq(
          items: [
            {'at': '0/1', 'estimate': true},
          ],
        ),
      ),
      _fixture('rice_chicken'),
    );
    expect(_codes(matched, 'AQ-02'), ['key:$_chicken']);
  });

  test('AQ-03 explicit amount and unit come from the decoded item; wrong unit '
      'misses', () {
    final result = _run(
      _case(
        _aq(
          items: [
            _item(
              '0/0',
              [_cooked, _raw],
              extra: {
                'amount': {'value': 200, 'unit': 'g'},
              },
            ),
            _item(
              '0/2',
              [_onion],
              extra: {
                'amount': {'value': 1, 'unit': 'g'},
              },
            ),
          ],
        ),
      ),
      _fixture('rice_chicken'),
    );
    expect(_codes(result, 'AQ-03'), [null, 'amount:1piece']);

    final implicit = _fixture('rice_chicken');
    final items =
        ((implicit['intents'] as List<dynamic>).first as PublicJson)['items']
            as List<dynamic>;
    ((items[2] as PublicJson)['amount'] as PublicJson)['explicit'] = false;
    final assumed = _run(
      _case(
        _aq(
          items: [
            _item(
              '0/2',
              [_onion],
              extra: {
                'amount': {'value': 1, 'unit': 'piece'},
              },
            ),
          ],
        ),
      ),
      implicit,
    );
    expect(_codes(assumed, 'AQ-03'), ['amount:implicit']);
    // PA22: the assumed-amount line is AQ-10 eligible and the engine marks
    // it as an estimate with a range.
    expect(
      _units(assumed, 'AQ-10').where((u) => u.unit == 'T02#0'),
      hasLength(1),
    );
    expect(_codes(assumed, 'AQ-10'), everyElement(isNull));
  });

  test('AQ-04 weighed database match within 10 percent passes; 11 percent '
      'and a stale per-100 stamp miss', () {
    List<String?> weighed(PublicJson stamp) => _codes(
      _run(
        _case(
          _aq(
            items: [
              _item('0/1', [_chicken], extra: {'weighed': stamp}),
            ],
          ),
        ),
        _fixture('rice_chicken'),
      ),
      'AQ-04',
    );
    // 200 g × 120 kcal/100 g = 240 kcal.
    expect(
      weighed({
        'kcal': 264,
        'per100Kcal': {_chicken: 120},
      }),
      [null],
    );
    expect(
      weighed({
        'kcal': 270,
        'per100Kcal': {_chicken: 120},
      }),
      ['kcal:240/270'],
    );
    expect(
      weighed({
        'kcal': 240,
        'per100Kcal': {_chicken: 121},
      }),
      ['stale:120/121'],
    );
    expect(
      weighed({
        'kcal': 240,
        'per100Kcal': {_chicken: 120},
        'yieldFactor': 0.72,
      }),
      ['stale:yield:none/0.72'],
    );
  });

  test('AQ-05 reported not applicable without reference dishes', () {
    final report = _summary([_run(_case(_aq()), _fixture('rice_chicken'))]);
    expect((report['metrics'] as PublicJson)['AQ-05'], {
      'status': 'n/a',
      'reason': 'noReferenceDishes',
      'dishes': 0,
    });
  });

  test('AQ-06 ambiguous case asks the expected kind; a clarify counts as '
      'asking', () {
    PublicJson ambiguous(List<String> asks) =>
        _case(_aq(ambiguous: true, asks: asks));
    // Rice raw vs cooked spreads 260–730 kcal, unstated oil 0–119 kcal: both
    // exceed 50 kcal and 20 %, highest impact first.
    expect(
      _codes(_run(ambiguous(['state']), _fixture('rice_chicken')), 'AQ-06'),
      [null],
    );
    expect(
      _codes(_run(ambiguous(['variant']), _fixture('rice_chicken')), 'AQ-06'),
      ['asked:state+fat'],
    );
    expect(
      _codes(
        _run(
          _case(_aq(ambiguous: true, asks: ['clarify']), id: 'T11'),
          _clarify(),
        ),
        'AQ-06',
      ),
      [null],
    );
    expect(
      _codes(
        _run(
          _case(_aq(ambiguous: true, asks: ['state'])),
          _fixture('dish_milk'),
        ),
        'AQ-06',
      ),
      ['notAsked'],
    );
  });

  test('AQ-07 a question or clarify on an unambiguous case misses', () {
    expect(
      _codes(
        _run(_case(_aq(ambiguous: false)), _fixture('rice_chicken')),
        'AQ-07',
      ),
      ['asked:state+fat'],
    );
    expect(
      _codes(
        _run(_case(_aq(ambiguous: false), id: 'T40'), _clarify()),
        'AQ-07',
      ),
      ['asked:clarify'],
    );
    final neither = _run(_case(_aq()), _fixture('rice_chicken'));
    expect(_units(neither, 'AQ-06'), isEmpty);
    expect(_units(neither, 'AQ-07'), isEmpty);
  });

  test('AQ-08 engine questions plus clarify above two are counted', () {
    expect(_codes(_run(_case(_aq()), _fixture('rice_chicken')), 'AQ-08'), [
      null,
    ]);
    final third = _fixture('rice_chicken');
    (third['intents'] as List<dynamic>).add(
      (_clarify()['intents'] as List<dynamic>).first,
    );
    final result = _run(_case(_aq()), third);
    expect(_codes(result, 'AQ-08'), ['asked:state+fat+clarify']);
    expect(result.facts['questions'], 2);
    expect(result.facts['clarify'], 1);
  });

  test('AQ-10 an unmarked estimate or reference line misses', () {
    final unrangedEstimate = _line(
      Provenance(source: FoodSource.estimate),
      FoodRef.estimate(),
    );
    final reference = _line(
      Provenance(source: FoodSource.reference),
      FoodRef(FoodRefKind.catalog, id: 'ref:mansaf'),
    );
    final database = _line(
      Provenance(source: FoodSource.database),
      FoodRef(FoodRefKind.catalog, id: _chicken),
    );
    expect(aq10Eligible(unrangedEstimate, assumed: false), isTrue);
    expect(aq10Marked(unrangedEstimate), isFalse);
    expect(aq10Eligible(reference, assumed: false), isTrue);
    expect(aq10Marked(reference), isFalse);
    expect(aq10Eligible(database, assumed: false), isFalse);
    expect(aq10Eligible(database, assumed: true), isTrue);
    expect(aq10Marked(database), isFalse);

    // The engine marks its own estimate line with the item's range.
    final dish = _run(
      _case(
        _aq(
          items: [
            {'at': '0/0', 'estimate': true},
          ],
        ),
        id: 'T07',
      ),
      _fixture('dish_milk'),
    );
    expect(_units(dish, 'AQ-10').map((u) => (u.unit, u.code)), [
      ('T07#0', null),
    ]);
  });

  test('AQ-10 a wrongly matched line with an assumed amount is still graded: '
      'unmarked misses', () {
    // "white cheese" resolved to egg white (wrong key for AQ-02) with no
    // stated amount: PA22 eligibility comes from the decoded item, not from
    // the identity outcome.
    final eggWhite = ProposalFood(
      key: 'usda:egg_white_raw',
      names: FoodNames('synthetic'),
      state: FoodState.raw,
      source: FoodSource.database,
      per100: Nutrients.zero,
    );
    final item = ProposalItem(
      id: '0/1',
      displayName: 'synthetic',
      match: eggWhite,
      quantity: null,
      explicit: false,
      alternatives: const [],
      dimensions: const [],
    );
    final line = _line(
      Provenance(source: FoodSource.database),
      FoodRef(FoodRefKind.catalog, id: 'usda:egg_white_raw'),
    );
    final expected = AqExpectation.fromCase(
      _case(
        _aq(
          items: [
            _item('0/1', ['usda:feta_cheese']),
          ],
        ),
      ),
    ).items;
    expect(expected.single.accepts(line), isFalse);
    final units = aq10Units(
      id: 'T05',
      lines: [line],
      items: [(at: (0, 1), item: item)],
      expected: expected,
    );
    expect(units.map((u) => (u.unit, u.code)), [('T05#0', 'unmarked')]);
    // The same line from a stated amount isn't an AQ-10 unit.
    final stated = ProposalItem(
      id: '0/1',
      displayName: 'synthetic',
      match: eggWhite,
      quantity: Quantity(30, 'g'),
      explicit: true,
      alternatives: const [],
      dimensions: const [],
    );
    expect(
      aq10Units(
        id: 'T05',
        lines: [line],
        items: [(at: (0, 1), item: stated)],
        expected: expected,
      ),
      isEmpty,
    );
  });

  test('B09 adapter calls ProposalEvaluation only with production '
      'thresholds', () {
    final defaults = aqPolicy(const {});
    expect(defaults.relativeDelta, .20);
    expect(defaults.kcalDelta, 50);
    expect(aqPolicy(const {'proposalQuestionKcalDelta': 80}).kcalDelta, 80);
    final request = aqRequest(
      test: _case(_aq()),
      response: _fixture('rice_chicken'),
      messageId: _message,
      now: _now,
      yields: const [],
      policy: defaults,
    );
    expect(request.policy, ProposalPolicy.fromThresholds(const {}));
    expect(request.facts.packAvailable, isFalse);
    expect(request.facts.cookingFatIds, isEmpty);
    expect(request.context.slots, DefaultSlots.all);
    expect(request.context.referenceTime.tzOffsetMin, aqTzOffsetMin);
    // The supplied policy is the one evaluated: a 500 kcal threshold leaves
    // both spreads (470 and 119 kcal) unasked.
    final relaxed = _run(
      _case(_aq()),
      _fixture('rice_chicken'),
      policy: aqPolicy(const {'proposalQuestionKcalDelta': 500}),
    );
    expect(relaxed.facts['questions'], 0);
  });

  test('B09 adapter applies T03 saved defaults: no question, oil from the '
      'default', () {
    final result = _run(
      _case(
        _aq(
          ambiguous: false,
          savedDefaults: {'state:rice': 'dry', 'fat:rice': 'oil:1.0:tbsp'},
          items: [
            _item(
              '0/0',
              [_raw],
              extra: {
                'weighed': {
                  'kcal': 730,
                  'per100Kcal': {_raw: 365},
                },
              },
            ),
            _item('0/1', [_chicken]),
            _item('0/2', [_onion]),
          ],
          components: [
            {
              'keys': [_oil],
            },
          ],
        ),
        id: 'T03',
      ),
      _fixture('rice_chicken'),
    );
    expect(result.facts['questions'], 0);
    expect(result.facts['lines'], 4);
    expect(_codes(result, 'AQ-07'), [null]);
    expect(_codes(result, 'AQ-02'), [null, null, null]);
    expect(_codes(result, 'AQ-04'), [null]);
    expect(_codes(result, 'components'), [null]);
  });

  test('B09 AQ breakdown keys are en ar arabizi; an empty language is n/a', () {
    final report = _summary([
      _run(
        _case(
          _aq(
            items: [
              _item('0/0', [_cooked, _raw]),
              _item('0/1', [_chicken]),
              _item('0/2', [_onion]),
            ],
          ),
        ),
        _fixture('rice_chicken'),
      ),
    ]);
    final metrics = report['metrics'] as PublicJson;
    for (final metric in aqGatedMetrics) {
      expect((metrics[metric] as PublicJson).keys, [
        'overall',
        'en',
        'ar',
        'arabizi',
        'misses',
      ]);
    }
    final aq02 = metrics['AQ-02'] as PublicJson;
    expect(aqRate(aq02['en'] as PublicJson), '3/3');
    expect(aqRate(aq02['ar'] as PublicJson), 'n/a');
    expect(aqRate(aq02['arabizi'] as PublicJson), 'n/a');
    expect(report['kind'], 'aq');
    expect(report['catalog'], {'version': 6, 'dishes': 0});
  });

  test('B09 AQ report is content free', () {
    final response = _fixture('rice_chicken');
    final intent = (response['intents'] as List<dynamic>).first as PublicJson;
    intent['dishGroup'] = 'canary-dish';
    void rename(Object? node) {
      if (node is Map<String, dynamic>) {
        for (final key in ['mention', 'nameEn', 'nameAr']) {
          if (node[key] != null) node[key] = 'canary-$key';
        }
        node.values.forEach(rename);
      } else if (node is List<dynamic>) {
        node.forEach(rename);
      }
    }

    rename(response);
    final result = _run(
      _case(
        _aq(
          ambiguous: false,
          items: [
            _item('0/0', ['usda:none']),
            _item('0/1', [_chicken]),
          ],
        ),
        text: 'canary-text',
      ),
      response,
    );
    final report = jsonEncode(_summary([result]));
    expect(report, isNot(contains('canary')));
    expect(report, contains('T02#0 key:$_cooked'));
  });

  test('B09 release yields loader parses rows', () {
    const manifest =
        '{"catalog_version": 6, "files": {"yields.jsonl": {"count": 2}}, '
        '"counts": {"dishes": 0}}';
    const rows =
        '{"yield_group":"rice","from_state":"dry","to_state":"cooked",'
        '"factor":2.8,"source":"usda"}\n'
        '{"yield_group":"chicken","from_state":"raw","to_state":"cooked",'
        '"factor":0.72,"source":"usda"}\n';
    final release = parseAqRelease(manifest: manifest, yieldsJsonl: rows);
    expect(release.version, 6);
    expect(release.dishes, 0);
    expect(release.yields, hasLength(2));
    expect(release.yields.first.group, 'rice');
    expect(release.yields.first.from, FoodState.dry);
    expect(release.yields.first.to, FoodState.cooked);
    expect(release.yields.last.factor, .72);
    expect(
      () => parseAqRelease(
        manifest: manifest,
        yieldsJsonl: rows.split('\n').first,
      ),
      throwsFormatException,
    );
  });

  test('AQ-01 adapter imports no write path, I/O or app code: the eval only '
      'builds draft ops', () {
    final source = File(_path('lib/aq_metrics.dart')).readAsStringSync();
    final imports = RegExp(
      "^import '([^']+)';",
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)).toSet();
    expect(imports, {
      'dart:convert',
      'package:buddy_eval/public_eval.dart',
      'package:fb_domain/fb_domain.dart',
      'package:fb_text/fb_text.dart',
    });
    expect(source, isNot(contains('ChangeSet')));
  });
}
