import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/home_widget/home_widget_store.dart';
import 'package:fb_mobile/core/l10n/approx_text.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// What the home-screen widgets show (A71 D3, UX-082–085).
enum WidgetShows {
  /// The day's numbers and the buttons.
  numbers,

  /// "Hide numbers" is on: the mark, "What did you eat?" and the buttons.
  hidden,

  /// No signed-in profile (a read-only copy after sign-out): "Open Fitness
  /// Buddy".
  signedOut,
}

/// One macro on the widget: "92/150" (or "92 g" without a target) and its
/// bar in thousandths, full in the over tone past the target.
final class WidgetMacro {
  /// The macro.
  const new({
    required this.text,
    required this.eaten,
    this.bar = 0,
    this.over = false,
  });

  /// The formatted grams, "~" for a lower bound or an estimate, "—" when
  /// unknown.
  final String text;

  /// Only the eaten grams ("~92", no unit, no target): the compact one-row
  /// widgets (A73), whose bar shows the target.
  final String eaten;

  /// Eaten of target, 0–1000; 0 without a target.
  final int bar;

  /// Past its target.
  final bool over;

  @override
  String toString() => 'WidgetMacro';
}

/// One day's numbers, formatted as Today shows them (A71 D3).
final class WidgetDay {
  /// The day's numbers.
  const new({
    required this.date,
    required this.withTargets,
    required this.kcal,
    required this.caption,
    required this.ring,
    required this.over,
    required this.eatenOfTarget,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  /// [view] of [date] in the words of [l10n].
  factory of(AppLocalizations l10n, LocalDate date, TodayNumbersView view) {
    final number = NumberFormat.decimalPattern(l10n.localeName);
    String grams(double? g, {required bool approximate}) => g == null
        ? l10n.unknownValue
        : approxText(l10n, number.format(g), approximate: approximate);
    switch (view) {
      case final TargetNumbers v:
        WidgetMacro macro(MacroNumbers m) {
          final text = grams(m.eatenGrams, approximate: m.approximate);
          final target = m.targetGrams;
          if (target == null) {
            return WidgetMacro(text: l10n.todayMacroEaten(text), eaten: text);
          }
          final eaten = m.eatenGrams ?? 0;
          return WidgetMacro(
            text: l10n.widgetMacroOfTarget(text, target),
            eaten: text,
            bar: permille(eaten, target.toDouble()),
            over: eaten > target,
          );
        }
        return WidgetDay(
          date: date,
          withTargets: true,
          kcal: approxText(
            l10n,
            number.format(v.remainingKcal.abs()),
            approximate: v.estimated,
          ),
          caption: v.over ? l10n.widgetKcalOver : l10n.widgetKcalLeft,
          ring: v.over
              ? 1000
              : permille(v.eatenKcal.toDouble(), v.targetKcal.toDouble()),
          over: v.over,
          eatenOfTarget: l10n.todayEatenOfBudget(
            approxText(
              l10n,
              number.format(v.eatenKcal),
              approximate: v.estimated,
            ),
            number.format(v.targetKcal),
          ),
          protein: macro(v.protein),
          carbs: macro(v.carbs),
          fat: macro(v.fat),
          fiber: macro(v.fiber),
        );
      case final EatenNumbers v:
        // UX-084: without targets the ring shows the calories eaten.
        WidgetMacro macro(NutrientField f, double? g) {
          final text = grams(g, approximate: v.approximate.contains(f));
          return WidgetMacro(text: l10n.todayMacroEaten(text), eaten: text);
        }
        return WidgetDay(
          date: date,
          withTargets: false,
          kcal: approxText(
            l10n,
            number.format(v.eatenKcal),
            approximate: v.estimated,
          ),
          caption: l10n.diaryKcalEaten,
          ring: 0,
          over: false,
          eatenOfTarget: '',
          protein: macro(NutrientField.protein, v.protein),
          carbs: macro(NutrientField.carbs, v.carbs),
          fat: macro(NutrientField.fat, v.fat),
          fiber: macro(NutrientField.fiber, v.fiber),
        );
    }
  }

  /// [eaten] of [target] in thousandths, 0–1000.
  static int permille(double eaten, double target) {
    if (target <= 0) return eaten > 0 ? 1000 : 0;
    return (eaten / target * 1000).round().clamp(0, 1000);
  }

  /// The day the numbers are for (the widget shows them only on it).
  final LocalDate date;

  /// Targets in effect: the ring shows what is left; else calories eaten.
  final bool withTargets;

  /// The ring's number: kcal left, over, or eaten ("1,240", "~860").
  final String kcal;

  /// Under the number: "kcal left", "kcal over" or "kcal eaten".
  final String caption;

  /// The ring's fill, 0–1000 (full when over, empty without targets).
  final int ring;

  /// Over the day's target: the ring is full in the neutral over tone.
  final bool over;

  /// "860 / 2,100 kcal"; empty without targets.
  final String eatenOfTarget;

  /// Protein.
  final WidgetMacro protein;

  /// Carbs.
  final WidgetMacro carbs;

  /// Fat.
  final WidgetMacro fat;

  /// Fiber.
  final WidgetMacro fiber;

  @override
  String toString() => 'WidgetDay($date)';
}

/// The snapshot the app writes for the widgets (A71 D3): what they show,
/// whose it is, and today's and tomorrow's numbers (the widget picks the
/// phone's date, so midnight needs no app run, D4). Numbers only: no food,
/// no names. Content-free [toString].
final class WidgetSnapshot {
  /// A snapshot.
  const new({
    required this.shows,
    required this.profileTag,
    this.days = const [],
  });

  /// The snapshot of the open profile [profileTag]: signed out (a
  /// read-only copy) and hidden carry no numbers at all.
  factory of({
    required AppLocalizations l10n,
    required String profileTag,
    required bool signedOut,
    required bool hidden,
    required List<(LocalDate, TodayNumbersView)> days,
  }) {
    if (signedOut) {
      return WidgetSnapshot(
        shows: WidgetShows.signedOut,
        profileTag: profileTag,
      );
    }
    if (hidden) {
      return WidgetSnapshot(shows: WidgetShows.hidden, profileTag: profileTag);
    }
    return WidgetSnapshot(
      shows: WidgetShows.numbers,
      profileTag: profileTag,
      days: [for (final (date, view) in days) WidgetDay.of(l10n, date, view)],
    );
  }

  /// The snapshot format the native widgets read (`HomeWidgets.kt`).
  static const int version = 1;

  /// What the widgets show.
  final WidgetShows shows;

  /// The profile's tag (`homeWidgetProfileTag`).
  final String profileTag;

  /// Today's and tomorrow's numbers; empty unless [shows] is numbers.
  final List<WidgetDay> days;

  /// The flat key/values `HomeWidgets.kt` reads.
  Map<String, Object> toData() {
    final data = <String, Object>{
      'v': version,
      'shows': shows.name,
      homeWidgetProfileKey: profileTag,
      'days': days.length,
    };
    for (final (i, d) in days.indexed) {
      final p = 'd$i.';
      data.addAll({
        '${p}date': '${d.date}',
        '${p}targets': d.withTargets,
        '${p}kcal': d.kcal,
        '${p}caption': d.caption,
        '${p}ring': d.ring,
        '${p}over': d.over,
        '${p}eatenOf': d.eatenOfTarget,
      });
      for (final (name, m) in [
        ('protein', d.protein),
        ('carbs', d.carbs),
        ('fat', d.fat),
        ('fiber', d.fiber),
      ]) {
        data.addAll({
          '$p$name.text': m.text,
          '$p$name.eaten': m.eaten,
          '$p$name.bar': m.bar,
          '$p$name.over': m.over,
        });
      }
    }
    return data;
  }

  @override
  String toString() => 'WidgetSnapshot(${shows.name}, ${days.length} days)';
}
