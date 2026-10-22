import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/diary.dart';
import '../helpers/property.dart';

Hlc stamp(int n) => Hlc(wallMs: n, counter: 0, deviceId: entryA);
SearchCandidate<String> candidate(
  String id, {
  Iterable<String>? keys,
  SourceTier tier = SourceTier.database,
  MatchStrength strength = MatchStrength.words,
  int uses = 0,
  int? last,
  int length = 10,
  bool defaultVariant = false,
}) => SearchCandidate(
  keys: keys ?? [id],
  tier: tier,
  strength: strength,
  uses: uses,
  lastUsedHlc: last == null ? null : stamp(last),
  nameLength: length,
  isDefaultVariant: defaultVariant,
  id: id,
  payload: id,
);

void main() {
  test('FD-020 cached query corrections match every candidate', () {
    const corrections = {
      'rcie': ['rice'],
    };
    for (final name in ['white rice', 'brown rice', 'rice white']) {
      expect(
        NameMatcher.match('rcie', ['rcie'], name, corrections: corrections),
        MatchStrength.fuzzy,
      );
    }
    // An explicitly empty cache is authoritative, even with an index supplied.
    expect(
      NameMatcher.match(
        'rcie',
        ['rcie'],
        'rice',
        corrections: const {'rcie': []},
        fuzzyIndex: FuzzyIndex.build(['rice']),
      ),
      isNull,
    );
  });

  test('FD-020 NameMatcher strengths and whole query matching', () {
    final fuzzy = FuzzyIndex.build(['rice', 'chicken', 'breast']);
    MatchStrength? match(String q, String n) =>
        NameMatcher.match(q, q.split(' '), n, fuzzyIndex: fuzzy);
    expect(match('rice', 'rice'), MatchStrength.exact);
    expect(match('rice', 'rice white'), MatchStrength.prefix);
    expect(match('white ri', 'rice white'), MatchStrength.words);
    expect(match('rcie', 'rice white'), MatchStrength.fuzzy);
    expect(match('tea', 'steak'), MatchStrength.substring);
    expect(match('rice absent', 'rice white'), MatchStrength.partial);
    expect(match('absent rice', 'rice white'), MatchStrength.partial);
    expect(match('absent', 'rice white'), isNull);
    expect(match('', 'rice'), isNull);
    expect(match('rice', ''), isNull);
    expect(NameMatcher.match('rice', [], 'rice'), isNull);
    expect(NameMatcher.match('rcie', ['rcie'], 'rice'), isNull);
    expect(match('chiken breast', 'chicken breast'), MatchStrength.fuzzy);
    expect(match('rcie white', 'rice white'), MatchStrength.fuzzy);
  });
  test('FD-020 OSA deletion, transposition, runes and cutoff', () {
    expect(osaDistance('chiken', 'chicken', 1), 1);
    expect(osaDistance('rcie', 'rice', 1), 1);
    expect(osaDistance('abcdefg', 'abcxyfg', 2), 2);
    expect(osaDistance('😀رز', 'رز😀', 2), 2);
    expect(osaDistance('', 'a', 1), 1);
    expect(osaDistance('a', '', 1), 1);
    expect(osaDistance('a', 'abcdef', 1), 2);
    expect(osaDistance('aaa', 'bbb', 1), 2);
    expect(osaDistance('', '', 0), 0);
    expect(() => osaDistance('a', 'b', -1), throwsArgumentError);
  });
  test(
    'FD-020 fuzzy retrieval, prefix guard, deterministic correction order',
    () {
      final index = FuzzyIndex.build([
        '',
        'pi',
        'rice',
        'chicken',
        'abcdefg',
        'abcdefghijklmno',
        'ripe',
        'ride',
        'rick',
        'rime',
        'rite',
        'rile',
      ]);
      expect(index.corrections('rcie'), ['rice']);
      expect(index.corrections('chiken'), ['chicken']);
      expect(index.corrections('abcxyfg'), ['abcdefg']);
      expect(index.corrections('abcdefghijkxzzz'), ['abcdefghijklmno']);
      expect(index.corrections('chick'), isEmpty);
      expect(index.isWordPrefix('chick'), isTrue);
      expect(index.isWordPrefix('pi'), isTrue);
      expect(index.isWordPrefix('zzz'), isFalse);
      expect(index.corrections('rie'), isEmpty);
      expect(index.corrections('xyzz'), isEmpty);
      expect(index.corrections('rize'), [
        'rice',
        'ride',
        'rile',
        'rime',
        'ripe',
      ]);
      expect(index.corrections('rize', limit: 1), ['rice']);
      expect(index.corrections('rize', limit: 0), isEmpty);
      expect(index.corrections('chixxx'), isEmpty);
      expect(FuzzyIndex.build(['abcdef']).corrections('abxyef'), isEmpty);
      expect(
        FuzzyIndex.build(['abcdxfg', 'abcdefg', 'abcdefgx'])
            .corrections('abcxefg'),
        ['abcdefg', 'abcdxfg', 'abcdefgx'],
      );
      expect(FuzzyIndex.build(['😀abcd']).corrections('😀abdc'), ['😀abcd']);
      expect(FuzzyIndex.build([]).isWordPrefix('x'), isFalse);
    },
  );
  test('FD-020 fuzzy index bounds drop distance two and never exceed cap', () {
    final words = ['abcdefg', 'chicken', 'rice'];
    final one = FuzzyIndex.build(words, maxWords: 2);
    expect(one.distanceTwoEnabled, isFalse);
    expect(one.corrections('abcxyfg'), isEmpty);
    expect(one.corrections('chiken'), ['chicken']);
    final bounded = FuzzyIndex.build(words, maxDeletionKeys: 25);
    expect(bounded.distanceTwoEnabled, isFalse);
    expect(bounded.deletionKeyCount, lessThanOrEqualTo(25));
    expect(bounded.corrections('chiken'), ['chicken']);
    final disabled = FuzzyIndex.build(words, maxDeletionKeys: 1);
    expect(disabled.deletionKeyCount, 0);
    expect(disabled.corrections('chiken'), isEmpty);
    expect(disabled.distanceTwoEnabled, isFalse);
    expect(() => FuzzyIndex.build([], maxWords: -1), throwsArgumentError);
    expect(
      () => FuzzyIndex.build([], maxDeletionKeys: -1),
      throwsArgumentError,
    );
  });
  test('FD-021 good band personal > history > database > reference', () {
    expect(
      FoodSearchRanker.rank([
        candidate('reference', tier: .reference, strength: .exact),
        candidate('database', strength: .prefix),
        candidate('history', tier: .history),
        candidate('personal', tier: .personal),
      ]),
      ['personal', 'history', 'database', 'reference'],
    );
  });
  test('FD-011 FD-021 personal represents heavily used catalog duplicate', () {
    expect(
      FoodSearchRanker.rank([
        candidate(
          'catalog:rice',
          keys: ['catalog:rice', 'name:rice|raw|-'],
          uses: 50,
          last: 50,
          strength: .exact,
        ),
        candidate(
          'personal:rice',
          tier: .personal,
          keys: ['personal:rice', 'name:rice|raw|-'],
        ),
        candidate('other', tier: .history, strength: .exact),
      ]),
      ['personal:rice', 'other'],
    );
  });
  test(
    'FD-021 Arabic identity folds merge; state and brand remain distinct',
    () {
      // Keys are produced with fb_text.identityKey at the adapter boundary.
      expect(
        FoodSearchRanker.rank([
          candidate('catalog:ar', keys: ['catalog:ar', 'name:ارز|raw|-']),
          candidate(
            'personal:ar',
            tier: .personal,
            keys: ['personal:ar', 'name:ارز|raw|-'],
          ),
          candidate('cooked', keys: ['cooked', 'name:ارز|cooked|-']),
          candidate('brand', keys: ['brand', 'name:ارز|raw|brand']),
        ]),
        ['personal:ar', 'brand', 'cooked'],
      );
    },
  );
  test('FD-021 metadata-less history merges only by FoodRef', () {
    expect(
      FoodSearchRanker.rank([
        candidate('history', tier: .history, keys: ['catalog:1']),
        candidate('same', keys: ['catalog:1', 'name:rice|raw|-']),
        candidate('different', keys: ['catalog:2', 'name:rice|raw|-']),
        candidate('unknown', tier: .history, keys: ['catalog:3']),
      ]),
      ['history', 'unknown'],
    );
  });
  test('FD-021 word beats history substring; fuzzy beats mid-word', () {
    expect(
      FoodSearchRanker.rank([
        candidate('steak', tier: .history, strength: .substring),
        candidate('tea'),
        candidate('typo', tier: .reference, strength: .fuzzy),
        candidate('partial', tier: .personal, strength: .partial),
      ]),
      ['tea', 'typo', 'steak', 'partial'],
    );
  });
  test('FD-021 ties use strength, uses, recency, length, then identity', () {
    expect(
      FoodSearchRanker.rank([
        candidate('z'),
        candidate('a'),
        candidate('short', length: 1),
        candidate('recent', last: 2),
        candidate('old', last: 1),
        candidate('used', uses: 2),
        candidate('exact', strength: .exact),
      ]),
      ['exact', 'used', 'recent', 'old', 'short', 'a', 'z'],
    );
    expect(FoodSearchRanker.rank([candidate('x')], limit: 0), isEmpty);
    expect(FoodSearchRanker.rank<String>([]), isEmpty);
    expect(() => candidate('x', keys: []), throwsArgumentError);
  });
  test(
    'FD-021 dish used variant, then best match, then default represents',
    () {
      List<String> variants({int? last, MatchStrength strength = .words}) =>
          FoodSearchRanker.rank([
            candidate('default', keys: ['dish:1'], defaultVariant: true),
            candidate('stew', keys: ['dish:1'], last: last, strength: strength),
          ]);
      expect(variants(last: 1), ['stew']);
      expect(variants(strength: .exact), ['stew']);
      expect(variants(), ['default']);
      expect(
        FoodSearchRanker.rank([
          candidate('a', keys: ['dish:1']),
          candidate('b', keys: ['dish:1']),
        ]),
        ['a'],
      );
    },
  );
  test('FD-021 merged group takes best strength, max uses, latest use', () {
    expect(
      FoodSearchRanker.rank([
        candidate(
          'personal',
          keys: ['merged'],
          tier: .personal,
          strength: .partial,
        ),
        candidate(
          'alias',
          keys: ['merged'],
          uses: 50,
          last: 10,
          strength: .exact,
        ),
        candidate('rival', tier: .personal, strength: .exact, uses: 49),
      ]),
      ['personal', 'rival'],
    );
    expect(
      FoodSearchRanker.rank([
        candidate('a', keys: ['merged'], last: 5),
        candidate('b', keys: ['merged'], last: 10),
        candidate('rival', last: 9),
      ]),
      ['b', 'rival'],
    );
  });
  test('FD-021 adversarial caps apply only after ranking and merging', () {
    final noise = List.generate(
      650,
      (i) => candidate('noise$i', strength: .substring),
    );
    expect(
      FoodSearchRanker.rank([
        ...noise,
        candidate('exact', strength: .exact),
        candidate('prefix', strength: .prefix),
        candidate('history', tier: .history),
      ]).take(3),
      ['history', 'exact', 'prefix'],
    );
    expect(
      FoodSearchRanker.rank([
        for (var i = 0; i < 601; i++) candidate('prefix$i', strength: .prefix),
        candidate('exact', strength: .exact),
      ]).first,
      'exact',
    );
    expect(
      FoodSearchRanker.rank([
        for (var i = 0; i < 400; i++) candidate('alias$i', keys: ['one']),
        candidate('second'),
      ]),
      ['alias0', 'second'],
    );
    expect(
      FoodSearchRanker.rank([
        for (var i = 0; i < 301; i++) candidate('word$i'),
        candidate('prefix', strength: .prefix),
      ]).first,
      'prefix',
    );
  });
  Glados(
    any.listWithLengthInRange(0, 70, any.intInRange(0, 10000)),
    propertyRuns,
  ).test('FD-021 merge/rank deterministic, order independent, unique keys', (
    values,
  ) {
    final rows = [
      for (var i = 0; i < values.length; i++)
        candidate(
          'id$i',
          keys: ['group${values[i] % 13}', if (i % 7 == 0) 'bridge'],
          tier: SourceTier.values[values[i] % 4],
          strength: MatchStrength.values[values[i] % 6],
          uses: values[i] % 8,
          last: values[i] % 5,
          length: values[i] % 20,
          defaultVariant: values[i].isEven,
        ),
    ];
    final ranked = FoodSearchRanker.rank(rows);
    expect(FoodSearchRanker.rank(rows.reversed), ranked);
    expect(FoodSearchRanker.rank(rows), ranked);
    // Independently compute connected components by set expansion.
    final components = <Set<String>>[];
    for (final row in rows) {
      final keys = {...row.keys};
      final overlapping = components
          .where((c) => c.intersection(keys).isNotEmpty)
          .toList();
      for (final group in overlapping) {
        keys.addAll(group);
        components.remove(group);
      }
      components.add(keys);
    }
    final selected = ranked
        .map((id) => rows.firstWhere((r) => r.id == id))
        .toList();
    for (final component in components) {
      expect(
        selected.where((r) => r.keys.intersection(component).isNotEmpty).length,
        lessThanOrEqualTo(1),
      );
    }
    expect(ranked.length, components.length);
  });
}
