import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/body.dart';

void main() {
  test('WB-003 a weigh-in keeps value, unit, time, local date and note', () {
    final time = morningOf(dayN(3), hour: 6, minute: 42);
    final weighIn = WeighIn(
      id: weighInA,
      version: 2,
      time: time,
      localDate: dayN(3),
      kg: 97.4,
      input: const WeighInInput(97.4, MassUnit.kilogram),
      note: 'after Eid',
      preferredForDay: true,
    );
    expect(weighIn.id, weighInA);
    expect(weighIn.version, 2);
    expect(weighIn.time, time);
    expect(weighIn.localDate, dayN(3));
    expect(weighIn.kg, 97.4);
    expect(weighIn.input, const WeighInInput(97.4, MassUnit.kilogram));
    expect(weighIn.note, 'after Eid');
    expect(weighIn.preferredForDay, isTrue);
    expect(weighIn.versionedId, VersionedId(weighInA, 2));
    expect(
      weighIn.draft,
      WeighInDraft(
        time: time,
        input: const WeighInInput(97.4, MassUnit.kilogram),
        note: 'after Eid',
      ),
    );
    expect(storedOn(dayN(3), 97.4).preferredForDay, isFalse);
    expect(storedOn(dayN(3), 97.4).note, isNull);

    final draft = draftOn(dayN(3), 97.4, note: 'after Eid');
    expect(draft.kg, 97.4);
    expect(draft.localDate, dayN(3));
    expect(draft.validate(), isNull);

    expect(
      () => WeighIn(
        id: 'not-a-uuid',
        version: 1,
        time: time,
        localDate: dayN(3),
        kg: 97.4,
        input: const WeighInInput(97.4, MassUnit.kilogram),
      ),
      throwsArgumentError,
    );
    expect(() => storedOn(dayN(3), 97.4, version: 0), throwsArgumentError);
  });

  test('WB-003 lb input is stored as kg rounded once '
      '(214 lb → 97.07 kg, shown back as 214.0 lb)', () {
    const input = WeighInInput(214, MassUnit.pound);
    expect(input.kg, 97.07);
    expect(input.value, 214);
    expect(input.unit, MassUnit.pound);
    expect(input.value.toStringAsFixed(1), '214.0');
    expect(input.validate(), isNull);
    expect(const WeighInInput(97.25, MassUnit.kilogram).kg, 97.25);
    // Rounded once, from the typed value: not from a rounded kg.
    expect(const WeighInInput(220.5, MassUnit.pound).kg, 100.02);
  });

  test('WeighInDraft rejects values outside 20–500 kg, non-finite values '
      'and units other than kg/lb', () {
    WeighInIssue? issue(double value, [MassUnit unit = MassUnit.kilogram]) =>
        draftOn(dayN(0), value, unit: unit).validate();

    expect(issue(20), isNull);
    expect(issue(500), isNull);
    expect(issue(19.99), WeighInIssue.outOfRange);
    expect(issue(500.01), WeighInIssue.outOfRange);
    expect(issue(19.996), isNull, reason: 'rounds to 20.00 kg');
    expect(issue(0), WeighInIssue.outOfRange);
    expect(issue(-80), WeighInIssue.outOfRange);
    expect(issue(1e300), WeighInIssue.outOfRange);
    expect(issue(double.nan), WeighInIssue.outOfRange);
    expect(issue(double.infinity), WeighInIssue.outOfRange);
    expect(issue(double.negativeInfinity), WeighInIssue.outOfRange);

    expect(issue(44.1, MassUnit.pound), isNull);
    expect(issue(1102.3, MassUnit.pound), isNull);
    expect(issue(44, MassUnit.pound), WeighInIssue.outOfRange);
    expect(issue(1102.4, MassUnit.pound), WeighInIssue.outOfRange);

    expect(issue(97, MassUnit.gram), WeighInIssue.unit);
    expect(issue(97, MassUnit.ounce), WeighInIssue.unit);
    expect(issue(double.nan, MassUnit.gram), WeighInIssue.unit);

    // Stored rows: the read bound (synced rows outside it are skipped).
    expect(WeighInBounds.isReadableKg(97), isTrue);
    expect(WeighInBounds.isReadableKg(WeighInBounds.readMaxKg), isTrue);
    for (final kg in [0.0, -1.0, 1e6 + 1, 1e306, double.nan, double.infinity]) {
      expect(WeighInBounds.isReadableKg(kg), isFalse, reason: '$kg');
    }

    expect(WeighInBounds.minIn(MassUnit.kilogram), 20);
    expect(WeighInBounds.maxIn(MassUnit.kilogram), 500);
    expect(WeighInBounds.minIn(MassUnit.pound), 44.1);
    expect(WeighInBounds.maxIn(MassUnit.pound), 1102.3);
  });

  test('PA9 WeighInDraft rejects a time before 1970 (time)', () {
    WeighInDraft at(int ms) => WeighInDraft(
      time: EntryTime(DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true), 0),
      input: const WeighInInput(80, MassUnit.kilogram),
    );
    expect(at(0).validate(), isNull);
    expect(at(-1).validate(), WeighInIssue.time);
    // The input is checked first.
    expect(
      WeighInDraft(
        time: at(-1).time,
        input: const WeighInInput(5, MassUnit.kilogram),
      ).validate(),
      WeighInIssue.outOfRange,
    );
  });

  test('a measured time more than 5 minutes after now is in the future', () {
    final now = DateTime.utc(2026, 10, 28, 7);
    WeighInDraft at(DateTime utc) => WeighInDraft(
      time: EntryTime(utc, 180),
      input: const WeighInInput(80, MassUnit.kilogram),
    );
    expect(at(now).isInFuture(now), isFalse);
    expect(at(now.subtract(const Duration(days: 3))).isInFuture(now), isFalse);
    expect(at(now.add(const Duration(minutes: 5))).isInFuture(now), isFalse);
    expect(
      at(now.add(const Duration(minutes: 5, milliseconds: 1))).isInFuture(now),
      isTrue,
    );
  });

  test('WeighInDraft note is trimmed, empty becomes null, at most 200 '
      'characters, no control characters', () {
    expect(draftOn(day0, 80, note: '  after Eid \t').note, 'after Eid');
    expect(draftOn(day0, 80, note: '   ').note, isNull);
    expect(draftOn(day0, 80, note: '').note, isNull);
    expect(draftOn(day0, 80).note, isNull);

    final max = 'a' * WeighInBounds.noteMax;
    expect(draftOn(day0, 80, note: max).validate(), isNull);
    expect(
      draftOn(day0, 80, note: '${max}b').validate(),
      WeighInIssue.noteTooLong,
    );
    // Counted in code points, like the wire's maxLength.
    expect(draftOn(day0, 80, note: '😀' * 200).validate(), isNull);
    expect(
      draftOn(day0, 80, note: '😀' * 201).validate(),
      WeighInIssue.noteTooLong,
    );

    for (final control in ['\u0000', '\n', '\u0007', '\u007f', '\u009f']) {
      expect(
        draftOn(day0, 80, note: 'after${control}Eid').validate(),
        WeighInIssue.noteInvalid,
        reason: 'U+${control.codeUnitAt(0).toRadixString(16)}',
      );
    }
    // The value is checked before the note.
    expect(
      draftOn(day0, 5, note: 'a\u0000').validate(),
      WeighInIssue.outOfRange,
    );
  });

  test('a note with an emoji ZWJ sequence or RLM is accepted', () {
    const family = '\u{1f468}\u200d\u{1f469}\u200d\u{1f467}';
    const mixed = 'بعد العيد\u200f after Eid \u200eok';
    expect(draftOn(day0, 80, note: family).validate(), isNull);
    expect(draftOn(day0, 80, note: mixed).validate(), isNull);
    expect(draftOn(day0, 80, note: 'a\u2066b\u2069').validate(), isNull);
  });

  test('weigh-in toString carries no value and no note', () {
    final draft = draftOn(day0, 214.6, unit: MassUnit.pound, note: 'secret');
    final stored = storedOn(day0, 214.6, unit: MassUnit.pound, note: 'secret');
    final texts = [
      draft.toString(),
      draft.input.toString(),
      stored.toString(),
      CreateWeighIn(weighInA, draft).toString(),
      UpdateWeighIn(weighInA, 3, draft).toString(),
      DeleteWeighIn(stored.versionedId).toString(),
      ChooseTrendWeighIn(
        day0,
        chosen: stored.versionedId,
        dayWeighIns: [stored.versionedId],
      ).toString(),
      LikelyOtherUnit(
        suggestedUnit: MassUnit.pound,
        suggestedKg: 97.34,
        reference: stored,
      ).toString(),
      LargeChange(reference: stored, diffKg: 3.21).toString(),
      const Plausible().toString(),
    ];
    for (final text in texts) {
      expect(text, isNot(contains('214')), reason: text);
      expect(text, isNot(contains('97')), reason: text);
      expect(text, isNot(contains('3.2')), reason: text);
      expect(text, isNot(contains('secret')), reason: text);
    }
    expect(draft.input.toString(), 'WeighInInput(lb)');
    expect(stored.toString(), 'WeighIn($weighInA@v1)');
  });

  test('weigh-in values have value equality', () {
    const input = WeighInInput(80, MassUnit.kilogram);
    expect(input, const WeighInInput(80, MassUnit.kilogram));
    expect(input.hashCode, const WeighInInput(80, MassUnit.kilogram).hashCode);
    expect(input == const WeighInInput(80, MassUnit.pound), isFalse);
    expect(input == const WeighInInput(80.1, MassUnit.kilogram), isFalse);

    final draft = draftOn(day0, 80, note: 'n');
    expect(draft, draftOn(day0, 80, note: ' n '));
    expect(draft.hashCode, draftOn(day0, 80, note: 'n').hashCode);
    expect(draft == draftOn(day0, 80), isFalse);
    expect(draft == draftOn(day0, 81, note: 'n'), isFalse);
    expect(draft == draftOn(day0, 80, note: 'n', hour: 8), isFalse);

    final stored = storedOn(day0, 80, note: 'n');
    expect(stored, storedOn(day0, 80, note: 'n'));
    expect(stored.hashCode, storedOn(day0, 80, note: 'n').hashCode);
    for (final other in [
      storedOn(day0, 80, note: 'n', id: weighInB),
      storedOn(day0, 80, note: 'n', version: 2),
      storedOn(day0, 80, note: 'n', hour: 8),
      storedOn(dayN(1), 80, note: 'n'),
      storedOn(day0, 80, note: 'n', kg: 80.01),
      storedOn(day0, 80, note: 'n', unit: MassUnit.pound, kg: 80),
      storedOn(day0, 80),
      storedOn(day0, 80, note: 'n', preferred: true),
    ]) {
      expect(stored == other, isFalse);
    }
  });

  test('WB-003 several weigh-ins on one day: the earliest is the day '
      'choice', () {
    final early = storedOn(dayN(1), 97.2, id: weighInB, hour: 6);
    final late = storedOn(dayN(1), 96.8, hour: 20);
    final other = storedOn(dayN(0), 97.5, id: weighInC);
    final choices = DayChoice.of([late, other, early]);
    expect(choices, [other, early]);
    expect(() => choices.add(late), throwsUnsupportedError);
    expect(DayChoice.of([]), isEmpty);
  });

  test('WB-003 a preferred weigh-in wins over the earliest; two preferred '
      'after a sync: the earliest preferred', () {
    final early = storedOn(dayN(1), 97.2, hour: 6);
    final mid = storedOn(dayN(1), 97, id: weighInB, hour: 12, preferred: true);
    final late = storedOn(
      dayN(1),
      96.8,
      id: weighInC,
      hour: 20,
      preferred: true,
    );
    expect(DayChoice.of([early, late]), [late]);
    expect(DayChoice.of([late, early, mid]), [mid]);
    expect(DayChoice.of([mid, late, early]), [mid]);
  });

  test('WB-003 equal times break ties by id', () {
    final a = storedOn(dayN(1), 97.2);
    final b = storedOn(dayN(1), 97, id: weighInB);
    expect(DayChoice.of([b, a]), [a]);
    expect(DayChoice.of([a, b]), [a]);
    final pa = storedOn(dayN(1), 97.2, preferred: true);
    final pb = storedOn(dayN(1), 97, id: weighInB, preferred: true);
    expect(DayChoice.of([pb, pa]), [pa]);
  });
}
