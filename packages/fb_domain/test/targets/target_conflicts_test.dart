import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

String _id(int value) =>
    '0199e3c2-5b1a-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';
final _start = LocalDate(2026, 10, 17);

GoalPhase _phase(int id, int start, [int? end]) => GoalPhase(
  id: _id(id),
  name: 'Phase',
  start: _start.plusDays(start),
  end: end == null ? null : _start.plusDays(end),
  type: GoalType.lose,
  expression: GoalExpression.weekly(-.5),
);

SettingsVersionKey _key(int id, int day, {int revision = 1}) =>
    (id: _id(id), revision: revision, effectiveFrom: _start.plusDays(day));

(String, String) _pair(int a, int b) => (_id(a), _id(b));

bool _overlaps(GoalPhase a, GoalPhase b) {
  final aEnd = a.end?.epochDay ?? 1 << 40;
  final bEnd = b.end?.epochDay ?? 1 << 40;
  return a.start.epochDay <= bEnd && b.start.epochDay <= aEnd;
}

void main() {
  test('PA2 GoalHistory.conflicts returns every overlapping id pair and '
      'nothing for a clean timeline', () {
    // Clean: back-to-back closed phases, then an open one.
    expect(
      GoalHistory.conflicts([
        _phase(1, 0, 9),
        _phase(2, 10, 19),
        _phase(3, 20),
      ]),
      isEmpty,
    );
    expect(GoalHistory.conflicts([]), isEmpty);
    expect(GoalHistory.conflicts([_phase(1, 0)]), isEmpty);
    // Two open phases overlap; a closed phase overlaps on a shared day.
    expect(
      GoalHistory.conflicts([
        _phase(3, 5),
        _phase(1, 0, 5),
        _phase(2, 8),
        _phase(4, -10, -1),
      ]),
      {_pair(1, 3), _pair(2, 3)},
    );
    // Pairs are ordered by ID whatever the argument order.
    expect(GoalHistory.conflicts([_phase(9, 0), _phase(2, 3)]), {_pair(2, 9)});
    // A later phase inside an earlier closed one.
    expect(GoalHistory.conflicts([_phase(1, 0, 30), _phase(2, 10, 12)]), {
      _pair(1, 2),
    });
    // The same row twice is not a conflict with itself.
    expect(GoalHistory.conflicts([_phase(1, 0), _phase(1, 0)]), isEmpty);
  });

  test('PA2 TargetSettingsHistory.conflicts returns same-date id '
      'pairs', () {
    expect(
      TargetSettingsHistory.conflicts([_key(1, 0), _key(2, 1), _key(3, 2)]),
      isEmpty,
    );
    expect(
      TargetSettingsHistory.conflicts([
        _key(3, 0, revision: 2),
        _key(1, 0),
        _key(2, 0),
        _key(4, 1),
        _key(5, 1),
        _key(6, 2),
      ]),
      {_pair(1, 2), _pair(1, 3), _pair(2, 3), _pair(4, 5)},
    );
    expect(TargetSettingsHistory.conflicts([_key(1, 0), _key(1, 0)]), isEmpty);
    // The key of an A12 TargetSettings matches the record key shape.
    final settings = TargetSettings(
      id: _id(7),
      version: 3,
      effectiveFrom: _start,
      standard: TargetPlan(baseKcal: 2000, floorKcal: 1500),
    );
    expect(settings.key, _key(7, 0, revision: 3));
  });

  Glados3(
    any.listWithLengthInRange(
      0,
      7,
      any.combine2(
        any.intInRange(0, 20),
        any.intInRange(-1, 10),
        (s, l) => (s, l),
      ),
    ),
    any.listWithLengthInRange(0, 7, any.intInRange(0, 3)),
    any.intInRange(0, 7),
    propertyRuns,
  ).test('PA2 conflicts is symmetric and independent of input order', (
    spans,
    dates,
    rotation,
  ) {
    final phases = [
      for (final (i, (start, length)) in spans.indexed)
        _phase(i, start, length < 0 ? null : start + length),
    ];
    final versions = [for (final (i, day) in dates.indexed) _key(i, day)];
    List<T> reorder<T>(List<T> list) {
      if (list.isEmpty) return list;
      final k = rotation % list.length;
      return [...list.skip(k), ...list.take(k)].reversed.toList();
    }

    final phasePairs = GoalHistory.conflicts(phases);
    expect(GoalHistory.conflicts(reorder(phases)), phasePairs);
    final settingPairs = TargetSettingsHistory.conflicts(versions);
    expect(TargetSettingsHistory.conflicts(reorder(versions)), settingPairs);
    for (final pairs in [phasePairs, settingPairs]) {
      for (final (a, b) in pairs) {
        expect(a.compareTo(b), lessThan(0));
      }
    }
    // Exactly the brute-force relation, which is symmetric by construction.
    for (final a in phases) {
      for (final b in phases) {
        if (a.id.compareTo(b.id) >= 0) continue;
        expect(phasePairs.contains((a.id, b.id)), _overlaps(a, b));
      }
    }
    for (final a in versions) {
      for (final b in versions) {
        if (a.id.compareTo(b.id) >= 0) continue;
        expect(
          settingPairs.contains((a.id, b.id)),
          a.effectiveFrom == b.effectiveFrom,
        );
      }
    }
  });
}
