import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/today/application/today_date.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'today_controller.g.dart';

/// Null follows today across midnight; a historical date stays fixed.
@Riverpod(keepAlive: true)
class TodayController extends _$TodayController {
  @override
  LocalDate? build() => null;
  LocalDate get _today =>
      ref.read(todayProvider).asData?.value ??
      EntryTime.now(ref.read(clockProvider)).localDate;

  /// The current page date, resolved against today's date.
  LocalDate get _viewed => state ?? _today;

  /// Clamps picker dates and restores follow-today on the newest page.
  void goTo(LocalDate date) {
    final day = _today;
    final clamped = DayPager(day).dateAt(DayPager(day).indexOf(date));
    state = clamped == day ? null : clamped;
  }

  /// Previous calendar day, bounded by the pager.
  void previous() => goTo(_viewed.plusDays(-1));

  /// Next calendar day, never after today.
  void next() => goTo(_viewed.plusDays(1));

  /// Hook for the screen's midnight listener; past dates retain identity.
  void onTodayChanged(LocalDate today) {
    if (state != null && !state!.isBefore(today)) state = null;
  }
}
