import 'dart:math' as math;

import 'package:fb_domain/src/body/weigh_in.dart';
import 'package:fb_domain/src/targets/target_profile.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// One diary day as the adaptive estimate reads it (A38 D1). Days the app
/// has nothing for are simply not passed: unknown, never zero (TG-032).
/// Content-free [toString].
final class IntakeDay {
  /// [kcal] over [entryCount] live entries in [mealCount] meals; the day
  /// mark's [incomplete]; [confirmed] when the user said the day is
  /// complete (a "count again" mark or a dismissed suggestion, DY-004), so
  /// it is never suggested again.
  new({
    required this.date,
    required this.kcal,
    required this.entryCount,
    int? mealCount,
    this.incomplete = false,
    this.confirmed = false,
  }) : mealCount = mealCount ?? entryCount {
    if (!kcal.isFinite || kcal < 0) {
      throw ArgumentError('kcal must be finite and not negative');
    }
    if (entryCount < 0 || this.mealCount < 0) {
      throw ArgumentError('counts must not be negative');
    }
  }

  /// The diary day.
  final LocalDate date;

  /// Logged calories.
  final double kcal;

  /// Live entries.
  final int entryCount;

  /// Distinct meals with entries (defaults to [entryCount], an upper bound).
  final int mealCount;

  /// Marked incomplete (DY-004).
  final bool incomplete;

  /// Confirmed complete by the user.
  final bool confirmed;

  /// Whether anything was logged.
  bool get logged => entryCount > 0;

  @override
  String toString() => 'IntakeDay($date)';
}

/// The DY-004 shape: under half of a reference in fewer than two meals.
/// Drives the incomplete-day suggestion (against the day's target); the
/// estimate never applies it on its own (TG-031).
abstract final class IncompleteDayRule {
  /// The share of the reference below which a day looks incomplete.
  static const double maxShare = .5;

  /// Fewer meals than this look incomplete.
  static const int minMeals = 2;

  /// Whether a logged, unmarked day of [kcal] in [mealCount] meals looks
  /// incomplete against [referenceKcal]. Days with nothing logged are
  /// unknown, not suspicious; marked days are already answered.
  static bool matches({
    required double kcal,
    required int entryCount,
    required int mealCount,
    required double referenceKcal,
    bool incomplete = false,
  }) =>
      entryCount > 0 &&
      !incomplete &&
      mealCount < minMeals &&
      referenceKcal > 0 &&
      kcal < referenceKcal * maxShare;
}

/// How sure an estimate is (TG-033).
enum ExpenditureConfidence {
  /// Little or noisy data.
  low,

  /// Usable.
  medium,

  /// Plenty of consistent data.
  high,
}

/// The tunables of [AdaptiveExpenditure] (A38 D1). Derived, never stored:
/// retuning needs no migration.
final class AdaptiveConfig {
  /// The A38 plan's values.
  const new({
    this.windowDays = 28,
    this.weighInNoiseKg = .5,
    this.priorSigmaKcal = 250,
    this.highMaxSigmaKcal = 100,
    this.mediumMaxSigmaKcal = 200,
    this.ramadanWeight = .5,
    this.outlierMinKg = 1.5,
    this.outlierFraction = .015,
    this.anomalySpreads = 3,
    this.anomalyMinMultiple = 2.5,
    this.anomalyMinSpreadFraction = .15,
    this.minIntakeErrorShare = .25,
  });

  /// The days the estimate looks back over, ending on the end date.
  final int windowDays;

  /// The least day-to-day weigh-in noise assumed, kg (one SD).
  final double weighInNoiseKg;

  /// How far the formula expenditure may be off, kcal/day (one SD).
  final double priorSigmaKcal;

  /// High confidence up to this data uncertainty, kcal/day.
  final double highMaxSigmaKcal;

  /// Medium confidence up to this data uncertainty, kcal/day.
  final double mediumMaxSigmaKcal;

  /// How much a weigh-in during Ramadan counts (TG-037).
  final double ramadanWeight;

  /// A weigh-in this far off the line (or [outlierFraction] of the mean
  /// weight, whichever is larger) is dropped once.
  final double outlierMinKg;

  /// See [outlierMinKg].
  final double outlierFraction;

  /// A day's intake above the median by more than this many robust spreads
  /// (and above [anomalyMinMultiple] × the median) is flagged.
  final double anomalySpreads;

  /// A flagged day is at least this multiple of the median (weekly feast
  /// days of twice the usual intake are normal, not errors).
  final double anomalyMinMultiple;

  /// The robust spread is at least this share of the median intake.
  final double anomalyMinSpreadFraction;

  /// The least share of the intake sampling variance kept at full logging
  /// (logging error).
  final double minIntakeErrorShare;
}

/// Where the data stands against TG-031 within the window. Content-free
/// [toString].
final class AdaptiveReadiness {
  /// The counts, against [defaults]' thresholds.
  const new({
    required this.loggedDays,
    required this.completeDays,
    required this.weighIns,
    required this.weighInSpanDays,
    this.defaults = const TargetDefaults(),
  });

  /// Days with a live entry.
  final int loggedDays;

  /// Logged days not marked incomplete (TG-031).
  final int completeDays;

  /// Weigh-in days.
  final int weighIns;

  /// Days from the first to the last weigh-in day.
  final int weighInSpanDays;

  /// The thresholds.
  final TargetDefaults defaults;

  /// More days to log (TG-031: 14).
  int get daysToLog => math.max(0, defaults.adaptiveDays - loggedDays);

  /// More complete days needed (10).
  int get completeDaysToLog =>
      math.max(0, defaults.adaptiveCompleteDays - completeDays);

  /// More weigh-ins needed (3).
  int get weighInsToLog => math.max(0, defaults.adaptiveWeighIns - weighIns);

  /// More days the weigh-ins must spread over (10).
  int get spanDaysToGo =>
      math.max(0, defaults.adaptiveWeighInSpanDays - weighInSpanDays);

  /// Whether every threshold is met.
  bool get isReady =>
      daysToLog == 0 &&
      completeDaysToLog == 0 &&
      weighInsToLog == 0 &&
      spanDaysToGo == 0;

  @override
  String toString() => 'AdaptiveReadiness(ready: $isReady)';
}

/// One expenditure estimate (TG-030, TG-033). Values are user data:
/// content-free [toString].
final class ExpenditureEstimate {
  new _({
    required this.windowStart,
    required this.windowEnd,
    required this.intakeKcal,
    required this.weightKgPerWeek,
    required this.dataKcal,
    required this.dataSigmaKcal,
    required this.priorKcal,
    required this.kcal,
    required this.sigmaKcal,
    required this.confidence,
    required this.completeDays,
    required this.weighIns,
    required this.droppedWeighIns,
    required List<LocalDate> anomalyDates,
  }) : anomalyDates = List.unmodifiable(anomalyDates);

  /// The window's first day.
  final LocalDate windowStart;

  /// The window's last day (the estimate's date).
  final LocalDate windowEnd;

  /// Mean logged intake over the complete days.
  final double intakeKcal;

  /// The weight line's slope, kg per week (negative: losing).
  final double weightKgPerWeek;

  /// Intake minus the energy of the weight change: what the data says.
  final double dataKcal;

  /// The data's uncertainty, kcal/day (one SD).
  final double dataSigmaKcal;

  /// The formula expenditure it is blended with.
  final double priorKcal;

  /// The estimate: [dataKcal] and [priorKcal] by inverse variance.
  final double kcal;

  /// The estimate's uncertainty (one SD): the chart's band.
  final double sigmaKcal;

  /// From [dataSigmaKcal] (TG-033).
  final ExpenditureConfidence confidence;

  /// Complete days used.
  final int completeDays;

  /// Weigh-in days used.
  final int weighIns;

  /// Weigh-in days dropped as outliers (0 or 1).
  final int droppedWeighIns;

  /// Complete days, oldest first, whose logged intake looks like an error
  /// and that the user hasn't confirmed: counted as logged, but confidence
  /// is at most medium and an automatic change waits (A38 review 2).
  final List<LocalDate> anomalyDates;

  @override
  String toString() => 'ExpenditureEstimate($windowEnd, ${confidence.name})';
}

/// The estimate's readiness and, when ready, the estimate.
final class AdaptiveResult {
  const new _(this.readiness, this.estimate);

  /// Where the data stands.
  final AdaptiveReadiness readiness;

  /// The estimate; null until [readiness] is met.
  final ExpenditureEstimate? estimate;

  @override
  String toString() => 'AdaptiveResult(${estimate == null ? 'not ' : ''}ready)';
}

/// Actual expenditure from logged intake and the weight change over the
/// same window (TG-030 to TG-033, A38 D1). Pure and deterministic.
abstract final class AdaptiveExpenditure {
  /// The estimate for the window of [config].windowDays ending on [end].
  ///
  /// [days] and [weighIns] may hold anything; only the window is read.
  /// [priorKcal] is the formula expenditure on [end] (TG-020). [isRamadan]
  /// marks fasting days, whose weigh-ins count less (TG-037; A41a wires
  /// it).
  static AdaptiveResult estimate({
    required LocalDate end,
    required Iterable<IntakeDay> days,
    required Iterable<WeighIn> weighIns,
    required double priorKcal,
    bool Function(LocalDate date)? isRamadan,
    AdaptiveConfig config = const AdaptiveConfig(),
    TargetDefaults defaults = const TargetDefaults(),
  }) {
    if (!priorKcal.isFinite || priorKcal <= 0) {
      throw ArgumentError('prior must be finite and positive');
    }
    final start = end.plusDays(1 - config.windowDays);
    bool inWindow(LocalDate d) => !d.isBefore(start) && !d.isAfter(end);

    // Intake: one row per date (the last wins), logged days only.
    final byDate = <LocalDate, IntakeDay>{
      for (final day in days)
        if (inWindow(day.date) && day.logged) day.date: day,
    };
    // TG-031/032: every logged day not marked incomplete counts. A day that
    // only looks incomplete (DY-004) is suggested to the user, never left
    // out here.
    final completeDays = [
      for (final day in byDate.values)
        if (!day.incomplete) day,
    ];
    final complete = [for (final day in completeDays) day.kcal];

    // Weigh-ins: the day choices in the window.
    final points = [
      for (final w in DayChoice.of(weighIns.where((w) => w.isReadable)))
        if (inWindow(w.localDate))
          _Point(
            start.daysUntil(w.localDate).toDouble(),
            w.kg,
            isRamadan?.call(w.localDate) ?? false ? config.ramadanWeight : 1,
          ),
    ];
    AdaptiveReadiness readinessOf(List<_Point> ps) => AdaptiveReadiness(
      loggedDays: byDate.length,
      completeDays: complete.length,
      weighIns: ps.length,
      weighInSpanDays: ps.isEmpty ? 0 : (ps.last.x - ps.first.x).round(),
      defaults: defaults,
    );

    final readiness = readinessOf(points);
    if (!readiness.isReady) return AdaptiveResult._(readiness, null);

    var used = points;
    var fit = _Fit.of(used);
    var dropped = 0;
    if (used.length >= 4) {
      final meanKg = used.fold<double>(0, (s, p) => s + p.y) / used.length;
      final limit = math.max(
        config.outlierMinKg,
        meanKg * config.outlierFraction,
      );
      var worst = -1;
      var worstResidual = limit;
      for (final (i, p) in used.indexed) {
        final r = (p.y - fit.at(p.x)).abs();
        if (r > worstResidual) {
          worst = i;
          worstResidual = r;
        }
      }
      if (worst >= 0) {
        final rest = [...used]..removeAt(worst);
        if (readinessOf(rest).isReady) {
          used = rest;
          fit = _Fit.of(used);
          dropped = 1;
        }
      }
    }

    final n = complete.length;
    // Intake anomalies (a mistyped 20,000 kcal day) are flagged, never
    // clipped: the average is the real logged intake. A day above both the
    // median plus [AdaptiveConfig.anomalySpreads] robust spreads and
    // [AdaptiveConfig.anomalyMinMultiple] × the median, not confirmed by
    // the user, is an anomaly: confidence stays at most medium and an
    // automatic check-in waits for the user (A38 review 2).
    final median = _median(complete)!;
    final mad = _median([for (final k in complete) (k - median).abs()])!;
    final spread = math.max(
      1.4826 * mad,
      config.anomalyMinSpreadFraction * median,
    );
    final cap = math.max(
      median + config.anomalySpreads * spread,
      config.anomalyMinMultiple * median,
    );
    final anomalies = [
      for (final day in completeDays)
        if (day.kcal > cap && !day.confirmed) day.date,
    ]..sort();
    final intake = complete.fold<double>(0, (s, k) => s + k) / n;
    final intakeSd = n < 2
        ? 0.0
        : math.sqrt(
            complete.fold<double>(
                  0,
                  (s, k) => s + (k - intake) * (k - intake),
                ) /
                (n - 1),
          );
    // Days not logged are a sample of the window (finite-population
    // share), and logged days carry logging error, so the intake term never
    // drops below [AdaptiveConfig.minIntakeErrorShare] of the sampling one.
    final coverage = math.min(1, n / config.windowDays);
    final intakeSe =
        intakeSd /
        math.sqrt(n) *
        math.sqrt(math.max(1 - coverage, config.minIntakeErrorShare));
    final noise = math.max(fit.residualSd, config.weighInNoiseKg);
    final slopeSe = noise / math.sqrt(fit.sxx);
    final kcalPerKg = defaults.kcalPerKg;
    final dataKcal = intake - fit.slope * kcalPerKg;
    final dataSigma = math.sqrt(
      math.pow(slopeSe * kcalPerKg, 2) + intakeSe * intakeSe,
    );
    final priorVar = config.priorSigmaKcal * config.priorSigmaKcal;
    final dataVar = math.max(dataSigma * dataSigma, 1e-6);
    final kcal =
        (priorKcal / priorVar + dataKcal / dataVar) /
        (1 / priorVar + 1 / dataVar);
    final sigma = math.sqrt(1 / (1 / priorVar + 1 / dataVar));
    final confidence = dataSigma <= config.highMaxSigmaKcal && anomalies.isEmpty
        ? ExpenditureConfidence.high
        : dataSigma <= config.mediumMaxSigmaKcal
        ? ExpenditureConfidence.medium
        : ExpenditureConfidence.low;
    return AdaptiveResult._(
      readiness,
      ExpenditureEstimate._(
        windowStart: start,
        windowEnd: end,
        intakeKcal: intake,
        weightKgPerWeek: fit.slope * 7,
        dataKcal: dataKcal,
        dataSigmaKcal: dataSigma,
        priorKcal: priorKcal,
        kcal: kcal,
        sigmaKcal: sigma,
        confidence: confidence,
        completeDays: n,
        weighIns: used.length,
        droppedWeighIns: dropped,
        anomalyDates: anomalies,
      ),
    );
  }

  static double? _median(List<double> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }
}

/// A weigh-in day: [x] days into the window, [y] kg, weight [w].
final class _Point {
  const new(this.x, this.y, this.w);

  final double x;
  final double y;
  final double w;
}

/// A weighted least-squares line through the points (≥ 2 distinct x).
final class _Fit {
  const new _(this.intercept, this.slope, this.sxx, this.residualSd);

  factory of(List<_Point> points) {
    var sw = 0.0;
    var swx = 0.0;
    var swy = 0.0;
    for (final p in points) {
      sw += p.w;
      swx += p.w * p.x;
      swy += p.w * p.y;
    }
    final mx = swx / sw;
    final my = swy / sw;
    var sxx = 0.0;
    var sxy = 0.0;
    for (final p in points) {
      sxx += p.w * (p.x - mx) * (p.x - mx);
      sxy += p.w * (p.x - mx) * (p.y - my);
    }
    final slope = sxy / sxx;
    final intercept = my - slope * mx;
    var rss = 0.0;
    for (final p in points) {
      final r = p.y - (intercept + slope * p.x);
      rss += p.w * r * r;
    }
    final n = points.length;
    // Weighted residual variance per unit weight, n − 2 degrees of freedom.
    final residualSd = n > 2 ? math.sqrt(rss / ((n - 2) * sw / n)) : 0.0;
    return _Fit._(intercept, slope, sxx, residualSd);
  }

  final double intercept;
  final double slope;
  final double sxx;
  final double residualSd;

  double at(double x) => intercept + slope * x;
}
