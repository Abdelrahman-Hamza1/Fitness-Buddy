import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

SearchableExercise _ex(
  String id,
  List<String> keys, {
  MuscleGroup? group,
  bool cardio = false,
}) => SearchableExercise(id: id, keys: keys, group: group, isCardio: cardio);

final List<SearchableExercise> _candidates = [
  _ex('ex:barbell_bench_press', [
    'barbell bench press',
    'bench',
    'flat bench',
  ], group: MuscleGroup.chest),
  _ex('ex:cable_crossover', [
    'cable crossover',
    'cable fly',
  ], group: MuscleGroup.chest),
  _ex('ex:dumbbell_bench_press', [
    'dumbbell bench press',
    'db bench',
  ], group: MuscleGroup.chest),
  _ex('ex:lat_pulldown', ['lat pulldown'], group: MuscleGroup.back),
  _ex(
    'ex:treadmill',
    ['treadmill', 'running'],
    group: MuscleGroup.legs,
    cardio: true,
  ),
  _ex('ex:burpee', ['burpee']),
];

List<String> _ids(List<SearchableExercise> found) => [
  for (final e in found) e.id,
];

void main() {
  test('WO-001 search matches aliases, prefix before substring', () {
    // "bench": an alias equal to the query (prefix tier) beats word-prefix
    // matches; ties keep the candidates' order.
    expect(_ids(ExerciseSearch.search('bench', _candidates)), [
      'ex:barbell_bench_press',
      'ex:dumbbell_bench_press',
    ]);
    // "db": only the alias.
    expect(_ids(ExerciseSearch.search('db', _candidates)), [
      'ex:dumbbell_bench_press',
    ]);
    // "fly": a word prefix of an alias.
    expect(_ids(ExerciseSearch.search('fly', _candidates)), [
      'ex:cable_crossover',
    ]);
    // "down": a substring only, after any prefix match.
    expect(_ids(ExerciseSearch.search('down', _candidates)), [
      'ex:lat_pulldown',
    ]);
    // Word prefixes of equal rank keep the candidates' order.
    expect(_ids(ExerciseSearch.search('press', _candidates)), [
      'ex:barbell_bench_press',
      'ex:dumbbell_bench_press',
    ]);
    expect(ExerciseSearch.search('zzz', _candidates), isEmpty);
    // An empty query lists everything in order.
    expect(ExerciseSearch.search('', _candidates), hasLength(6));
  });

  test('WO-001 group chip filters by primary group; Cardio chip by type', () {
    expect(
      _ids(
        ExerciseSearch.search(
          '',
          _candidates,
          filter: ExerciseFilter.group(MuscleGroup.chest),
        ),
      ),
      [
        'ex:barbell_bench_press',
        'ex:cable_crossover',
        'ex:dumbbell_bench_press',
      ],
    );
    expect(
      _ids(
        ExerciseSearch.search('', _candidates, filter: ExerciseFilter.cardio),
      ),
      ['ex:treadmill'],
    );
    // No primary muscle: only under "All".
    expect(_ids(ExerciseSearch.search('burpee', _candidates)), ['ex:burpee']);
    for (final group in MuscleGroup.values) {
      expect(
        _ids(
          ExerciseSearch.search(
            'burpee',
            _candidates,
            filter: ExerciseFilter.group(group),
          ),
        ),
        isEmpty,
      );
    }
    expect(
      _ids(
        ExerciseSearch.search(
          'bench',
          _candidates,
          filter: ExerciseFilter.group(MuscleGroup.back),
        ),
      ),
      isEmpty,
    );
  });
}
