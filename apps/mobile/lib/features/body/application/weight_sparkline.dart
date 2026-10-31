import 'package:fb_domain/fb_domain.dart';

/// Last measured value per day, in the 30 days ending on [date] (WB-011).
/// This is a raw-value sparkline, deliberately independent of trend DayChoice.
List<double> sparklineValues(List<WeighIn> values, LocalDate date) {
  final start = date.plusDays(-29);
  final ordered =
      values
          .where(
            (w) =>
                w.isReadable &&
                !w.localDate.isBefore(start) &&
                !w.localDate.isAfter(date),
          )
          .toList()
        ..sort((a, b) {
          final time = a.time.occurredAtUtc.compareTo(b.time.occurredAtUtc);
          return time != 0 ? time : a.id.compareTo(b.id);
        });
  final days = <LocalDate, double>{};
  for (final w in ordered) {
    days[w.localDate] = w.kg;
  }
  final dates = days.keys.toList()..sort();
  return dates.length < 2 ? [] : [for (final d in dates) days[d]!];
}
