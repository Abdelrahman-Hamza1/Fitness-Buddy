import 'dart:ui' show Locale;

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/home_widget/home_widget_store.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/home_widgets/application/widget_snapshot.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_test/flutter_test.dart';

import '../today/presentation/support/today_targets_support.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

/// A fixed 2,000 kcal day (no weekly carry-over).
DayTargets _fixed(LocalDate date, {MacroSettings? macros}) => targetsOn(
  date,
  settings: [sampleVersion(mode: TargetMode.fixed, macros: macros)],
);

WidgetSnapshot _snapshot(
  List<(LocalDate, TodayNumbersView)> days, {
  bool hidden = false,
  bool signedOut = false,
}) => WidgetSnapshot.of(
  l10n: _l10n,
  profileTag: homeWidgetProfileTag('p1'),
  signedOut: signedOut,
  hidden: hidden,
  days: days,
);

void main() {
  final today = weekDay(3);
  final tomorrow = today.plusDays(1);

  test('UX-082 HM-001 with targets: kcal left, the ring filled by eaten of '
      'target, "eaten / target" and the macros against their targets, for '
      'today and tomorrow', () {
    final snapshot = _snapshot([
      (
        today,
        TodayNumbersView.of(
          eatenTotals(860, protein: 92, fiber: 30.4),
          _fixed(today),
        ),
      ),
      (tomorrow, TodayNumbersView.of(IntakeTotals.empty, _fixed(tomorrow))),
    ]);
    expect(snapshot.shows, WidgetShows.numbers);
    final day = snapshot.days.first;
    expect(day.date, today);
    expect(day.withTargets, isTrue);
    expect(day.kcal, '1,140');
    expect(day.caption, 'kcal left');
    expect(day.ring, 430);
    expect(day.over, isFalse);
    expect(day.eatenOfTarget, '860 / 2,000 kcal');
    final protein = _fixed(today).day.macros.proteinGrams;
    final target = DisplayRounding.macroTargetGrams(protein);
    expect(day.protein.text, '92/$target');
    expect(day.protein.bar, WidgetDay.permille(92, target.toDouble()));
    expect(day.protein.over, isFalse);
    // Tomorrow starts at the full target.
    final next = snapshot.days.last;
    expect(next.date, tomorrow);
    expect(next.kcal, '2,000');
    expect(next.ring, 0);

    final data = snapshot.toData();
    expect(data['v'], WidgetSnapshot.version);
    expect(data['shows'], 'numbers');
    expect(data['profile'], homeWidgetProfileTag('p1'));
    expect(data['days'], 2);
    expect(data['d0.date'], '$today');
    expect(data['d1.date'], '$tomorrow');
    expect(data['d0.kcal'], '1,140');
    expect(data['d0.ring'], 430);
    expect(data['d0.protein.text'], '92/$target');
    // Only strings, ints and bools cross the channel.
    expect(
      data.values.every((v) => v is String || v is int || v is bool),
      isTrue,
    );
  });

  test('SF-021 over target: how much over in the over wording, the ring '
      'full; a macro past its target is a full bar marked over', () {
    final day = _snapshot([
      (
        today,
        TodayNumbersView.of(eatenTotals(2320, protein: 400), _fixed(today)),
      ),
    ]).days.single;
    expect(day.kcal, '320');
    expect(day.caption, 'kcal over');
    expect(day.ring, 1000);
    expect(day.over, isTrue);
    expect(day.protein.bar, 1000);
    expect(day.protein.over, isTrue);
  });

  test('UX-084 without targets the ring shows the calories eaten and the '
      'macros their grams, no bars', () {
    final day = _snapshot([
      (today, TodayNumbersView.of(eatenTotals(1239.6), null)),
    ]).days.single;
    expect(day.withTargets, isFalse);
    expect(day.kcal, '1,240');
    expect(day.caption, 'kcal eaten');
    expect(day.ring, 0);
    expect(day.eatenOfTarget, isEmpty);
    expect(day.protein.text, '82 g');
    expect(day.protein.bar, 0);
  });

  test('HM-001 A62 an estimate shows "~", an unknown macro "—", a macro '
      'without a target its grams (TG-054)', () {
    final day = _snapshot([
      (
        today,
        TodayNumbersView.of(
          IntakeTotals.fromCounts(
            sum: Nutrients(kcal: 900, protein: 40, carbs: 0, fat: 20, fiber: 5),
            items: 2,
            estimates: 1,
            carbsUnknown: 2,
          ),
          _fixed(today, macros: MacroSettings(caloriesProteinOnly: true)),
        ),
      ),
    ]).days.single;
    expect(day.kcal, '~1,100');
    expect(day.eatenOfTarget, '~900 / 2,000 kcal');
    expect(day.carbs.text, '— g');
    expect(day.carbs.bar, 0);
    expect(day.fat.text, '~20 g');
  });

  test('UX-085 hidden and signed out carry no numbers at all', () {
    final view = TodayNumbersView.of(eatenTotals(860), _fixed(today));
    for (final (snapshot, shows) in [
      (_snapshot([(today, view)], hidden: true), 'hidden'),
      (_snapshot([(today, view)], signedOut: true), 'signedOut'),
      (_snapshot([(today, view)], hidden: true, signedOut: true), 'signedOut'),
    ]) {
      expect(snapshot.days, isEmpty);
      final data = snapshot.toData();
      expect(data['shows'], shows);
      expect(data['days'], 0);
      expect(data.keys.where((k) => k.startsWith('d0.')), isEmpty);
      expect('$snapshot', isNot(contains('860')));
    }
  });

  test('A71 D3 the profile tag is a stable one-way hash, never the key', () {
    final tag = homeWidgetProfileTag('profile-key-1');
    expect(tag, homeWidgetProfileTag('profile-key-1'));
    expect(tag, isNot(homeWidgetProfileTag('profile-key-2')));
    expect(tag, hasLength(16));
    expect(tag, isNot(contains('profile')));
  });

  test('UX-085 A71 D8 the hide setting: key name pinned, off by default, in '
      'the export vocabulary', () {
    expect(AppSettings.widgetNumbersHidden.name, 'widgets.hideNumbers');
    expect(AppSettings.widgetNumbersHidden.defaultValue, isFalse);
    expect(AppSettings.all, contains(AppSettings.widgetNumbersHidden));
  });
}
