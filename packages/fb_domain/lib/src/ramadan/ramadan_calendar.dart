import 'package:fb_domain/src/diary/meal_slot.dart';
import 'package:fb_domain/src/ramadan/ramadan_settings.dart';
import 'package:fb_domain/src/ramadan/umm_al_qura.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// Ramadan on the Gregorian calendar (LC-030, `09` §2): the Umm al-Qura
/// dates, the user's ±1-day shifts and on/off decisions, and what follows
/// from them for a date. Pure; the one place that decides "is this a
/// Ramadan day" for slots (DY-012), targets (TG-060), chart shading
/// (WB-021), adaptive confidence (TG-037), reminders (NT-008/009), the
/// comparison (IN-008) and the proposal (LC-031).
final class RamadanCalendar {
  /// The calendar over [settings], with Ramadan dates from [table]
  /// (Umm al-Qura by default).
  new(
    this.settings, {
    Iterable<LocalDate> notFasting = const [],
    Map<int, (LocalDate, LocalDate)>? table,
  }) : notFasting = Set.unmodifiable(notFasting),
       table = table ?? UmmAlQura.ramadan;

  /// How many days before the first day of Ramadan the switch-on proposal
  /// appears (LC-031; J11 shows it two days before, so it is there by then).
  static const int proposalLeadDays = 3;

  /// The user's decisions.
  final RamadanSettings settings;

  /// The days stored as [FastingMark.notFasting] (LC-034). Unmodifiable.
  final Set<LocalDate> notFasting;

  /// The first days of Ramadan and of Shawwal, by Hijri year.
  final Map<int, (LocalDate, LocalDate)> table;

  /// The calendar's Ramadan of [hijriYear] without the user's shifts, or
  /// null outside the table.
  RamadanPeriod? calendarPeriod(int hijriYear) {
    final row = table[hijriYear];
    if (row == null) return null;
    final (start, shawwal) = row;
    return RamadanPeriod(
      hijriYear: hijriYear,
      start: start,
      end: shawwal.plusDays(-1),
    );
  }

  /// The Ramadan of [hijriYear] with the user's shifts (decided or not),
  /// or null outside the table.
  RamadanPeriod? period(int hijriYear) {
    final base = calendarPeriod(hijriYear);
    if (base == null) return null;
    final season = settings[hijriYear];
    if (season == null) return base;
    return RamadanPeriod(
      hijriYear: hijriYear,
      start: base.start.plusDays(season.startShift),
      end: base.end.plusDays(season.endShift),
    );
  }

  /// The (shifted) Ramadans whose mode is on, oldest first.
  List<RamadanPeriod> get onPeriods => [
    for (final season in settings.seasons)
      if (season.on) ?period(season.hijriYear),
  ];

  /// The Ramadan that matters on [today]: the one in progress (or one that
  /// just ended but could still be extended to include today: the end
  /// shift goes up to +1, and moon sighting is only known that evening),
  /// else the next one in the table, else null (past the table's range).
  /// Uses the shifted dates.
  RamadanPeriod? relevant(LocalDate today) {
    RamadanPeriod? best;
    for (final year in table.keys) {
      final p = period(year);
      if (p == null) continue;
      final latest = calendarPeriod(year)!.end.plusDays(RamadanSeason.maxShift);
      if (p.end.isBefore(today) && latest.isBefore(today)) continue;
      if (best == null || p.start.isBefore(best.start)) best = p;
    }
    return best;
  }

  /// The Ramadan (on or not) containing [date], or null.
  RamadanPeriod? periodContaining(LocalDate date) {
    for (final year in table.keys) {
      final p = period(year);
      if (p != null && p.contains(date)) return p;
    }
    return null;
  }

  /// The Ramadan with mode on that contains [date], or null.
  RamadanPeriod? onPeriodContaining(LocalDate date) {
    final p = periodContaining(date);
    return p != null && (settings[p.hijriYear]?.on ?? false) ? p : null;
  }

  /// Whether [date] is in a Ramadan whose mode is on (charts, comparison).
  bool isOn(LocalDate date) => onPeriodContaining(date) != null;

  /// Whether the user marked [date], a day of a Ramadan with the mode on,
  /// "not fasting" (LC-034).
  bool notFastingOn(LocalDate date) => notFasting.contains(date) && isOn(date);

  /// Whether [date] is a fasting day as far as the app knows: in a Ramadan
  /// whose mode is on and not marked "not fasting" (LC-034). Slots,
  /// targets and reminders follow this.
  bool isFastingDay(LocalDate date) => isOn(date) && !notFastingOn(date);

  /// The meal slots in use on [date] (DY-012, LC-034).
  SlotMode slotModeOn(LocalDate date) =>
      isFastingDay(date) ? .ramadan : .normal;

  /// Whether "maintain during Ramadan" applies on [date] (TG-060/061): a
  /// fasting day of a season where the user chose it.
  bool maintainOn(LocalDate date) {
    if (!isFastingDay(date)) return false;
    final p = onPeriodContaining(date)!;
    return settings[p.hijriYear]!.maintain;
  }

  /// The Ramadan to propose switching on for, on [today] (LC-031): the
  /// relevant one when it is undecided and [today] is from
  /// [proposalLeadDays] before its first day to its last day. Null
  /// otherwise: a decision (on or off) is never asked again.
  RamadanPeriod? proposalOn(LocalDate today) {
    final p = relevant(today);
    if (p == null || settings[p.hijriYear] != null) return null;
    if (today.isAfter(p.end)) return null;
    return today.isBefore(p.start.plusDays(-proposalLeadDays)) ? null : p;
  }

  /// The Ramadan whose targets offer (TG-060) is due on [today]: a season
  /// switched on, in its first seven days (the first Ramadan weekly
  /// summary), not answered yet. Null otherwise.
  RamadanPeriod? targetsOfferOn(LocalDate today) {
    final p = onPeriodContaining(today);
    if (p == null || p.dayOf(today)! > 7) return null;
    return settings[p.hijriYear]!.targetsAnswered ? null : p;
  }
}
