import 'package:fb_domain/src/time/local_date.dart';

/// The user's decision for one Ramadan (LC-030, LC-031, TG-060, A41a D3):
/// whether Ramadan mode is on for it, the ±1-day shifts of its start and
/// end (moon sighting differs by country) and the Ramadan targets choice.
/// The days the user isn't fasting are separate per-date settings
/// ([RamadanFasting]), never part of this value.
/// No season stored for a year means "not decided yet": the app proposes
/// switching on shortly before it starts.
final class RamadanSeason {
  /// The season of Hijri year [hijriYear]. Throws an `ArgumentError` for a
  /// shift outside −1…+1.
  new({
    required this.hijriYear,
    required this.on,
    this.startShift = 0,
    this.endShift = 0,
    this.maintain = false,
    this.targetsAnswered = false,
  }) {
    for (final (name, shift) in [
      ('startShift', startShift),
      ('endShift', endShift),
    ]) {
      if (shift < -maxShift || shift > maxShift) {
        throw RangeError.range(shift, -maxShift, maxShift, name);
      }
    }
  }

  /// The largest shift either way, in days (LC-030).
  static const int maxShift = 1;

  /// The Hijri year whose Ramadan this is.
  final int hijriYear;

  /// Whether Ramadan mode is on (false: declined or switched off).
  final bool on;

  /// Days added to the calendar's first day of Ramadan (−1, 0 or +1).
  final int startShift;

  /// Days added to the calendar's last day of Ramadan (−1, 0 or +1).
  final int endShift;

  /// Whether the user chose "maintain during Ramadan" (TG-060): the goal's
  /// deficit or surplus is left out on Ramadan days.
  final bool maintain;

  /// Whether the user answered the Ramadan targets offer (TG-060: shown in
  /// the first Ramadan weekly summary until answered).
  final bool targetsAnswered;

  /// A copy with the given fields replaced.
  RamadanSeason copyWith({
    bool? on,
    int? startShift,
    int? endShift,
    bool? maintain,
    bool? targetsAnswered,
  }) => RamadanSeason(
    hijriYear: hijriYear,
    on: on ?? this.on,
    startShift: startShift ?? this.startShift,
    endShift: endShift ?? this.endShift,
    maintain: maintain ?? this.maintain,
    targetsAnswered: targetsAnswered ?? this.targetsAnswered,
  );

  Map<String, Object> _toJson() => {
    'on': on,
    if (startShift != 0) 'startShift': startShift,
    if (endShift != 0) 'endShift': endShift,
    if (maintain) 'maintain': true,
    if (targetsAnswered) 'targetsAnswered': true,
  };

  @override
  bool operator ==(Object other) =>
      other is RamadanSeason &&
      other.hijriYear == hijriYear &&
      other.on == on &&
      other.startShift == startShift &&
      other.endShift == endShift &&
      other.maintain == maintain &&
      other.targetsAnswered == targetsAnswered;

  @override
  int get hashCode => Object.hash(
    hijriYear,
    on,
    startShift,
    endShift,
    maintain,
    targetsAnswered,
  );

  @override
  String toString() =>
      'RamadanSeason($hijriYear, on: $on, shift $startShift/$endShift'
      '${maintain ? ', maintain' : ''})';
}

/// Every Ramadan season the user decided, by Hijri year: the value of the
/// synced setting `ramadan.seasons` (A41a D3), a JSON object
/// `{"1448": {"on": true, "startShift": 1}}`.
final class RamadanSettings {
  /// The settings holding [seasons] (at most one per Hijri year; a later one
  /// replaces an earlier one).
  new(Iterable<RamadanSeason> seasons)
    : _byYear = Map.unmodifiable({for (final s in seasons) s.hijriYear: s});

  /// The settings in [json]. Years or fields it can't read are skipped (a
  /// value written by a newer app version, or damaged), never an error:
  /// a setting never stops the app (A01 D16).
  factory fromJson(Object? json) {
    if (json is! Map) return none;
    final seasons = <RamadanSeason>[];
    for (final MapEntry(:key, :value) in json.entries) {
      final year = key is String ? int.tryParse(key) : null;
      if (year == null || year < 1 || year > 9999 || value is! Map) continue;
      final on = value['on'];
      final start = value['startShift'] ?? 0;
      final end = value['endShift'] ?? 0;
      final maintain = value['maintain'] ?? false;
      final answered = value['targetsAnswered'] ?? false;
      if (on is! bool ||
          start is! int ||
          end is! int ||
          maintain is! bool ||
          answered is! bool) {
        continue;
      }
      if (start.abs() > RamadanSeason.maxShift ||
          end.abs() > RamadanSeason.maxShift) {
        continue;
      }
      seasons.add(
        RamadanSeason(
          hijriYear: year,
          on: on,
          startShift: start,
          endShift: end,
          maintain: maintain,
          targetsAnswered: answered,
        ),
      );
    }
    return RamadanSettings(seasons);
  }

  /// No decision for any year.
  static final RamadanSettings none = RamadanSettings(const []);

  final Map<int, RamadanSeason> _byYear;

  /// The decided seasons, oldest year first.
  List<RamadanSeason> get seasons => List.unmodifiable(
    (_byYear.keys.toList()..sort()).map((y) => _byYear[y]!),
  );

  /// The season of [hijriYear], or null when undecided.
  RamadanSeason? operator [](int hijriYear) => _byYear[hijriYear];

  /// A copy with [season] stored (replacing that year's).
  RamadanSettings withSeason(RamadanSeason season) =>
      RamadanSettings([..._byYear.values, season]);

  /// The JSON value of the setting.
  Map<String, Object> toJson() => {
    for (final s in seasons) '${s.hijriYear}': s._toJson(),
  };

  @override
  bool operator ==(Object other) {
    if (other is! RamadanSettings || other._byYear.length != _byYear.length) {
      return false;
    }
    for (final MapEntry(:key, :value) in _byYear.entries) {
      if (other._byYear[key] != value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(_byYear.values);

  @override
  String toString() => 'RamadanSettings(${seasons.join(', ')})';
}

/// One Ramadan on the Gregorian calendar: its first and last day
/// (inclusive), after the user's shifts.
final class RamadanPeriod {
  /// The period [start]–[end] of Hijri year [hijriYear]. Throws an
  /// `ArgumentError` when [end] is before [start].
  new({required this.hijriYear, required this.start, required this.end}) {
    if (end.isBefore(start)) throw ArgumentError('end is before start');
  }

  /// The Hijri year.
  final int hijriYear;

  /// The first day of Ramadan (1 Ramadan).
  final LocalDate start;

  /// The last day of Ramadan (the day before Eid al-Fitr).
  final LocalDate end;

  /// The number of days.
  int get days => start.daysUntil(end) + 1;

  /// Whether [date] is one of its days.
  bool contains(LocalDate date) => !date.isBefore(start) && !date.isAfter(end);

  /// The day of Ramadan of [date] (1 on the first day), or null outside.
  int? dayOf(LocalDate date) =>
      contains(date) ? start.daysUntil(date) + 1 : null;

  @override
  bool operator ==(Object other) =>
      other is RamadanPeriod &&
      other.hijriYear == hijriYear &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(hijriYear, start, end);

  @override
  String toString() => 'RamadanPeriod($hijriYear, $start–$end)';
}

/// One day's fasting decision (LC-034, A41a fix round 2), stored as its own
/// synced setting (`ramadan.fasting.d<yyyymmdd>`, [RamadanFasting.keyName]),
/// so two devices marking different days, or one marking a day while the
/// other changes a season preference, never overwrite each other: settings
/// merge per key, last writer wins. Stored names are permanent values.
enum FastingMark {
  /// Not fasting that day: normal slots, targets and reminders.
  notFasting,

  /// Fasting (the default when nothing is stored). Written explicitly when
  /// a not-fasting day is switched back, so the newer decision wins.
  fasting,
}

/// The per-date keys of [FastingMark] (A41a fix round 2).
abstract final class RamadanFasting {
  /// The setting key of [date]'s mark, like `ramadan.fasting.d20270211`.
  static String keyName(LocalDate date) =>
      'ramadan.fasting.d${date.year.toString().padLeft(4, '0')}'
      '${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';

  /// The days of a calendar Ramadan a mark can apply to: its days and one
  /// either side (the ±1 shifts, LC-030).
  static List<LocalDate> datesOf(RamadanPeriod calendarPeriod) => [
    for (
      var d = calendarPeriod.start.plusDays(-RamadanSeason.maxShift);
      !d.isAfter(calendarPeriod.end.plusDays(RamadanSeason.maxShift));
      d = d.plusDays(1)
    )
      d,
  ];
}
