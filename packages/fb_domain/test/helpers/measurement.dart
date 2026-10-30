import 'package:fb_domain/fb_domain.dart';

import 'body.dart';

/// Fixed measurement and type IDs.
const measurementA = '0199e3c2-5b1a-7000-8000-00000000ea01';
const measurementB = '0199e3c2-5b1a-7000-8000-00000000eb02';
const typeA = '0199e3c2-5b1a-7000-8000-0000000071a1';
const typeB = '0199e3c2-5b1a-7000-8000-0000000071b2';

/// The [n]th of a run of distinct measurement IDs.
String measurementId(int n) {
  final tail = (0xe0000 + n).toRadixString(16).padLeft(12, '0');
  return '0199e3c2-5b1a-7000-8000-$tail';
}

/// The built-in waist series.
final MeasurementTypeRef waist = MeasurementTypeRef.builtIn(
  MeasurementKind.waist,
);

/// A draft of [value] [unit] of [type] on [date] at [hour] (UTC+03:00).
MeasurementDraft measureOn(
  LocalDate date,
  double value, {
  MeasurementTypeRef? type,
  MeasurementUnit unit = MeasurementUnit.cm,
  int hour = 7,
}) => MeasurementDraft(
  type: type ?? waist,
  time: morningOf(date, hour: hour),
  input: MeasurementInput(value, unit),
);

/// A stored measurement of [value] [unit] on [date].
Measurement measuredOn(
  LocalDate date,
  double value, {
  String id = measurementA,
  MeasurementTypeRef? type,
  MeasurementUnit unit = MeasurementUnit.cm,
  int hour = 7,
  int version = 1,
}) {
  final input = MeasurementInput(value, unit);
  return Measurement(
    id: id,
    version: version,
    type: type ?? waist,
    time: morningOf(date, hour: hour),
    localDate: date,
    value: input.canonical,
    input: input,
  );
}
