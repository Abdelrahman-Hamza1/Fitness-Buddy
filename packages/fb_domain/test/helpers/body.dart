import 'package:fb_domain/fb_domain.dart';

/// Fixed weigh-in IDs.
const weighInA = '0199e3c2-5b1a-7000-8000-0000000000a1';
const weighInB = '0199e3c2-5b1a-7000-8000-0000000000b2';
const weighInC = '0199e3c2-5b1a-7000-8000-0000000000c3';

/// The [n]th of a run of distinct weigh-in IDs.
String weighInId(int n) =>
    '0199e3c2-5b1a-7000-8000-${n.toRadixString(16).padLeft(12, '0')}';

/// The day zero of the body tests (a Thursday).
final LocalDate day0 = LocalDate(2026, 1, 1);

/// [n] days after [day0].
LocalDate dayN(int n) => day0.plusDays(n);

/// [date] at [hour]:[minute] local time in UTC+03:00.
EntryTime morningOf(LocalDate date, {int hour = 7, int minute = 0}) =>
    EntryTime.local(LocalDateTime(date, hour: hour, minute: minute), 180);

/// A new weigh-in of [value] [unit] on [date].
WeighInDraft draftOn(
  LocalDate date,
  double value, {
  MassUnit unit = MassUnit.kilogram,
  int hour = 7,
  String? note,
}) => WeighInDraft(
  time: morningOf(date, hour: hour),
  input: WeighInInput(value, unit),
  note: note,
);

/// A stored weigh-in of [value] [unit] on [date]; [kg] defaults to the
/// value converted and rounded once.
WeighIn storedOn(
  LocalDate date,
  double value, {
  String id = weighInA,
  MassUnit unit = MassUnit.kilogram,
  double? kg,
  int hour = 7,
  int minute = 0,
  bool preferred = false,
  String? note,
  int version = 1,
}) {
  final input = WeighInInput(value, unit);
  return WeighIn(
    id: id,
    version: version,
    time: morningOf(date, hour: hour, minute: minute),
    localDate: date,
    kg: kg ?? input.kg,
    input: input,
    note: note,
    preferredForDay: preferred,
  );
}
