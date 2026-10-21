import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

String _id(int value) =>
    '0199e3c2-5b1a-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';
final _start = LocalDate(2026, 10, 17);
TargetSettings _settings(int id, int version, int day, double kcal) =>
    TargetSettings(
      id: _id(id),
      version: version,
      effectiveFrom: _start.plusDays(day),
      standard: TargetPlan(baseKcal: kcal, floorKcal: 1500),
    );
GoalPhase _phase(int id, int day, {int version = 1, int? end}) => GoalPhase(
  id: _id(id),
  name: 'Phase',
  start: _start.plusDays(day),
  end: end == null ? null : _start.plusDays(end),
  version: version,
  type: GoalType.lose,
  expression: GoalExpression.weekly(-.5),
);

Iterable<List<T>> _permutations<T>(List<T> rows) sync* {
  if (rows.isEmpty) {
    yield <T>[];
    return;
  }
  for (var i = 0; i < rows.length; i++) {
    for (final rest in _permutations([...rows.take(i), ...rows.skip(i + 1)])) {
      yield [rows[i], ...rest];
    }
  }
}

void main() {
  test(
    'TG-060 G10 concurrent settings use date/revision/ID in any input order',
    () {
      final lowRevisionHighId = _settings(9, 1, 0, 2000);
      final higherRevision = _settings(2, 2, 0, 2100);
      final higherId = _settings(3, 2, 0, 2200);
      final laterDateLowRevision = _settings(1, 1, 3, 2300);
      for (final rows in _permutations([
        lowRevisionHighId,
        higherRevision,
        higherId,
        laterDateLowRevision,
      ])) {
        final history = TargetSettingsHistory(rows);
        expect(history.versions, [
          lowRevisionHighId,
          higherRevision,
          higherId,
          laterDateLowRevision,
        ]);
        expect(history.at(_start.plusDays(-1)), isNull);
        expect(history.at(_start), higherId);
        expect(history.at(_start.plusDays(2)), higherId);
        expect(history.at(_start.plusDays(3)), laterDateLowRevision);
        final day = history.at(_start)!.plan().day(date: _start, weightKg: 70);
        expect(day.kcal, closeTo(2200, 1e-7));
        expect(history.versions.clear, throwsUnsupportedError);
      }
      // Row revisions need not be globally unique across an effective timeline.
      TargetSettingsHistory.validateForWrite([
        _settings(1, 1, 0, 2000),
        _settings(2, 1, 1, 2100),
      ]);
      expect(
        () =>
            TargetSettingsHistory.validateForWrite([higherId, higherRevision]),
        throwsArgumentError,
      );
      expect(
        () => TargetSettingsHistory.validateForWrite([
          _settings(1, 1, 0, 2000),
          _settings(1, 2, 1, 2100),
        ]),
        throwsArgumentError,
      );
      expect(
        () => TargetSettings(
          id: 'invalid',
          version: 1,
          effectiveFrom: _start,
          standard: higherId.standard,
        ),
        throwsArgumentError,
      );
      expect(higherId.id, _id(3));
    },
  );

  test(
    'TG-012 conflicting phases project deterministically without resurrection',
    () {
      final earlier = _phase(1, 0);
      final sameDateLowRevision = _phase(9, 2, end: 6);
      final sameDateHighRevision = _phase(2, 2, version: 2, end: 5);
      final sameDateHighId = _phase(3, 2, version: 2, end: 4);
      for (final rows in _permutations([
        earlier,
        sameDateLowRevision,
        sameDateHighRevision,
        sameDateHighId,
      ])) {
        final history = GoalHistory(rows);
        expect(history.records, [
          earlier,
          sameDateLowRevision,
          sameDateHighRevision,
          sameDateHighId,
        ]);
        expect(history.phases.length, 2);
        final projected = history.phases.first;
        expect(projected.id, earlier.id);
        expect(projected.end, _start.plusDays(1));
        expect(projected.version, earlier.version);
        expect(projected.name, earlier.name);
        expect(projected.type, earlier.type);
        expect(projected.expression, earlier.expression);
        expect(history.at(_start.plusDays(-1)), isNull);
        expect(history.at(_start), projected);
        expect(history.at(_start.plusDays(1)), projected);
        expect(history.at(_start.plusDays(2)), sameDateHighId);
        expect(history.at(_start.plusDays(4)), sameDateHighId);
        // The earlier open phase never resumes after its successor ended.
        expect(history.at(_start.plusDays(5)), isNull);
        expect(earlier.end, isNull);
        expect(history.records.clear, throwsUnsupportedError);
        expect(history.phases.clear, throwsUnsupportedError);
      }
      final finiteOverlap = GoalHistory([_phase(1, 0, end: 7), _phase(2, 2)]);
      expect(finiteOverlap.phases.first.end, _start.plusDays(1));
      final noOverlap = GoalHistory([_phase(1, 0, end: 1), _phase(2, 3)]);
      expect(noOverlap.at(_start.plusDays(2)), isNull);
      expect(GoalHistory([]).at(_start), isNull);
      GoalHistory.validateForWrite(noOverlap.records);
      expect(
        () => GoalHistory.validateForWrite([earlier, sameDateHighId]),
        throwsArgumentError,
      );
      expect(
        () => GoalHistory.validateForWrite([
          sameDateHighId,
          sameDateHighRevision,
        ]),
        throwsArgumentError,
      );
      expect(
        () =>
            GoalHistory.validateForWrite([_phase(1, 0, end: 1), _phase(1, 3)]),
        throwsArgumentError,
      );
      expect(() => _phase(1, 0, version: 0), throwsArgumentError);
      expect(
        () => GoalPhase(
          id: _id(1),
          name: '',
          start: _start,
          type: GoalType.maintain,
          expression: GoalExpression.weekly(0),
        ),
        throwsArgumentError,
      );
    },
  );

  test('TG-011 weekly rates convert back to the actual calendar month', () {
    for (final (date, days) in [
      (LocalDate(2026, 2, 1), 28),
      (LocalDate(2024, 2, 20), 29),
      (LocalDate(2026, 4, 1), 30),
      (LocalDate(2026, 1, 1), 31),
      (LocalDate(9999, 12, 31), 31),
    ]) {
      final requested = ResolvedGoal.resolve(
        type: GoalType.lose,
        expression: GoalExpression.monthly(-2, date),
        currentKg: 80,
        date: date,
      );
      expect(
        monthlyKgFromWeeklyRate(requested.requestedKgPerWeek, date),
        closeTo(-2, 1e-12),
      );
      expect(monthlyKgFromWeeklyRate(.5, date), days / 14);
      expect(monthlyKgFromWeeklyRate(0, date), 0);
    }
    expect(
      () => monthlyKgFromWeeklyRate(double.nan, _start),
      throwsArgumentError,
    );
  });
}
