import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/features/body/application/measurement_form.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/measurement_harness.dart';

Measurement _stored(int n, MeasurementDraft draft, {int version = 1}) =>
    Measurement(
      id: mId(n),
      version: version,
      type: draft.type,
      time: draft.time,
      localDate: draft.localDate,
      value: draft.value,
      input: draft.input,
    );

void main() {
  final clock = ManualClock(measureNow, offsetMinutes: 180);
  final now = EntryTime.now(clock);

  test('WB-040 a new entry starts now in the unit setting, prefilled with the '
      "type's latest entry (as typed, or converted to one decimal)", () {
    final latest = _stored(1, measureDraft(92.25));
    final metric = MeasurementFormState.create(
      type: waistRef,
      lengthUnit: LengthUnit.centimeter,
      now: now,
      latest: latest,
    );
    expect(metric.text, '92.25');
    expect(metric.unit, MeasurementUnit.cm);
    expect(metric.time, now);
    expect(metric.isEdit, isFalse);
    expect(metric.issue, isNull);
    expect(
      metric.draft!.input,
      const MeasurementInput(92.25, MeasurementUnit.cm),
    );

    // LC-010: the imperial setting defaults lengths to inches.
    final imperial = MeasurementFormState.create(
      type: waistRef,
      lengthUnit: LengthUnit.inch,
      now: now,
      latest: latest,
    );
    expect(imperial.unit, MeasurementUnit.inch);
    expect(imperial.text, '36.3');
    // A value typed in cm stays cm.
    final cm = imperial.withUnit(MeasurementUnit.cm).withText('92');
    expect(cm.draft!.input, const MeasurementInput(92, MeasurementUnit.cm));

    // WB-042: body fat is % only.
    final bodyFat = metric.withType(
      MeasurementTypeRef.builtIn(MeasurementKind.bodyFat),
    );
    expect(bodyFat.unit, MeasurementUnit.percent);
    expect(bodyFat.units, [MeasurementUnit.percent]);
    expect(bodyFat.text, '');
    expect(bodyFat.issue, MeasurementFormIssue.empty);
    expect(bodyFat.withUnit(MeasurementUnit.cm).unit, MeasurementUnit.percent);
    expect(bodyFat.withText('18.4').issue, isNull);
    expect(bodyFat.withText('80').issue, MeasurementFormIssue.outOfRange);

    // A past date gets 08:00 local; today gets now.
    final past = metric.withDate(
      measureDay.plusDays(-3),
      now: now,
      clock: clock,
    );
    expect(past.time.localDateTime.hour, 8);
    expect(past.time.localDate, measureDay.plusDays(-3));
    expect(past.withDate(measureDay, now: now, clock: clock).time, now);
  });

  test('WB-040 editing an older entry while a newer one exists opens with the '
      "older entry's exact value, unit, date, time and offset (PA3)", () {
    final older = _stored(
      1,
      MeasurementDraft(
        type: waistRef,
        time: EntryTime.local(
          LocalDateTime(measureDay.plusDays(-30), hour: 21, minute: 15),
          -300,
        ),
        input: const MeasurementInput(36.25, MeasurementUnit.inch),
      ),
    );
    final form = MeasurementFormState.edit(
      older,
      lengthUnit: LengthUnit.centimeter,
    );
    expect(form.isEdit, isTrue);
    expect(form.text, '36.25');
    expect(form.unit, MeasurementUnit.inch);
    expect(form.time, older.time);
    expect(form.time.tzOffsetMin, -300);
    expect(form.draft, older.draft);
    // An edit keeps its type.
    expect(
      form.withType(MeasurementTypeRef.builtIn(MeasurementKind.chest)).type,
      waistRef,
    );
  });

  test('WB-040 opening an entry and saving without a change writes nothing '
      '(the stored input is kept, PA3)', () {
    // 92.257 isn't what the field shows (two decimals): untouched, the
    // stored input is kept as it is.
    final stored = _stored(1, measureDraft(92.257));
    final form = MeasurementFormState.edit(
      stored,
      lengthUnit: LengthUnit.centimeter,
    );
    expect(form.text, '92.26');
    expect(form.draft, stored.draft);
    // Retyping the same text isn't a change; another value is.
    expect(form.withText('92.26').draft, stored.draft);
    expect(form.withText('92.25').draft!.input.value, 92.25);
  });

  test('WB-040 a date-only change keeps the value as stored, the local time '
      "of day and the row's offset", () {
    final stored = _stored(
      1,
      MeasurementDraft(
        type: waistRef,
        time: EntryTime.local(
          LocalDateTime(measureDay.plusDays(-2), hour: 6, minute: 40),
          120,
        ),
        input: const MeasurementInput(92.257, MeasurementUnit.cm),
      ),
    );
    final moved = MeasurementFormState.edit(
      stored,
      lengthUnit: LengthUnit.centimeter,
    ).withDate(measureDay.plusDays(-5), now: now, clock: clock);
    final draft = moved.draft!;
    expect(draft.input, stored.input);
    expect(draft.time.tzOffsetMin, 120);
    expect(draft.time.localDateTime.hour, 6);
    expect(draft.time.localDateTime.minute, 40);
    expect(draft.localDate, measureDay.plusDays(-5));
  });

  test('numberText shows at most two decimals without trailing zeros', () {
    expect(MeasurementFormState.numberText(92), '92');
    expect(MeasurementFormState.numberText(92.5), '92.5');
    expect(MeasurementFormState.numberText(92.25), '92.25');
    expect(MeasurementFormState.numberText(92.2), '92.2');
    expect(
      MeasurementFormState.create(
        type: waistRef,
        lengthUnit: LengthUnit.centimeter,
        now: now,
      ).toString(),
      'MeasurementFormState(waist, cm)',
    );
  });
}
