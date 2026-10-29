import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/body.dart';

void main() {
  final today = dayN(100);
  final sparse = WeighInCadence.of([today], today);

  test('WB-012 1–7 weigh-in days in 28 is sparse, 8+ is frequent, none with '
      'history is stale', () {
    final none = WeighInCadence.of(const [], today);
    expect(none.kind, CadenceKind.none);
    expect(none.countLast28, 0);
    expect(none.lastDate, isNull);

    // Weekly: 4 days in the window, the oldest exactly 27 days back.
    final weekly = WeighInCadence.of([
      for (var i = 0; i < 28; i += 7) today.plusDays(-27 + i),
    ], today);
    expect(weekly.kind, CadenceKind.sparse);
    expect(weekly.countLast28, 4);
    expect(weekly.lastDate, today.plusDays(-6));

    final seven = WeighInCadence.of([
      for (var i = 0; i < 7; i++) today.plusDays(-i),
    ], today);
    expect(seven.kind, CadenceKind.sparse);
    expect(seven.countLast28, 7);

    final eight = WeighInCadence.of([
      for (var i = 0; i < 8; i++) today.plusDays(-3 * i),
    ], today);
    expect(eight.kind, CadenceKind.frequent);
    expect(eight.countLast28, 8);
    expect(eight.lastDate, today);

    // 28 days back is outside the window; repeats and future days don't count.
    final stale = WeighInCadence.of([
      today.plusDays(-28),
      today.plusDays(-40),
      today.plusDays(1),
    ], today);
    expect(stale.kind, CadenceKind.stale);
    expect(stale.countLast28, 0);
    expect(stale.lastDate, today.plusDays(-28));
    final repeated = WeighInCadence.of([today, today, today], today);
    expect(repeated.countLast28, 1);
    expect(repeated, sparse);
    expect(
      WeighInCadence.of([today.plusDays(2)], today).kind,
      CadenceKind.none,
    );

    expect(sparse, WeighInCadence.of([today], today));
    expect(sparse.hashCode, WeighInCadence.of([today], today).hashCode);
    expect(sparse == stale, isFalse);
    expect(sparse == weekly, isFalse);
    expect(sparse == WeighInCadence.of([today.plusDays(-1)], today), isFalse);
    expect(sparse.toString(), 'WeighInCadence(CadenceKind.sparse, 1, $today)');
  });

  test('WB-012 the suggestion shows at most once in 30 days and stays hidden '
      'after Got it', () {
    bool show(CadenceTipState state, LocalDate on, [WeighInCadence? cadence]) =>
        CadenceTipRule.shouldShow(
          state,
          on,
          cadence ?? WeighInCadence.of([on], on),
        );

    // Only with a sparse cadence.
    expect(show(CadenceTipState.initial, today), isTrue);
    for (final days in [
      const <LocalDate>[],
      [today.plusDays(-40)],
      [for (var i = 0; i < 10; i++) today.plusDays(-i)],
    ]) {
      expect(
        show(CadenceTipState.initial, today, WeighInCadence.of(days, today)),
        isFalse,
      );
    }

    final shown = CadenceTipState.initial.shownToday(today);
    expect(shown, CadenceTipState(shownOn: today));
    final dismissed = shown.dismiss();
    expect(dismissed, CadenceTipState(shownOn: today, dismissed: true));
    expect(show(dismissed, today), isFalse);
    for (var later = 1; later < CadenceTipRule.intervalDays; later++) {
      expect(show(dismissed, today.plusDays(later)), isFalse, reason: '$later');
      expect(show(shown, today.plusDays(later)), isFalse, reason: '$later');
    }
    expect(show(dismissed, today.plusDays(30)), isTrue);
    expect(show(shown, today.plusDays(45)), isTrue);
    // A new month starts a new showing, not dismissed yet.
    expect(
      dismissed.shownToday(today.plusDays(30)),
      CadenceTipState(shownOn: today.plusDays(30)),
    );
    // A shown date after today (the clock moved back) counts as long ago.
    expect(show(dismissed, today.plusDays(-1)), isTrue);

    expect(CadenceTipState.initial.shownOn, isNull);
    expect(CadenceTipState.initial.dismissed, isFalse);
    expect(shown.hashCode, CadenceTipState(shownOn: today).hashCode);
    expect(shown == dismissed, isFalse);
    expect(shown == CadenceTipState(shownOn: today.plusDays(1)), isFalse);
    expect(dismissed.toString(), 'CadenceTipState($today, dismissed: true)');
  });

  test('WB-012 on the day it first shows, the suggestion stays until '
      'dismissed', () {
    final shown = CadenceTipState.initial.shownToday(today);
    expect(CadenceTipRule.shouldShow(shown, today, sparse), isTrue);
    // Marking it shown again the same day keeps the state.
    expect(shown.shownToday(today), same(shown));
    expect(CadenceTipRule.shouldShow(shown, today, sparse), isTrue);
    expect(CadenceTipRule.shouldShow(shown.dismiss(), today, sparse), isFalse);
    expect(
      CadenceTipRule.shouldShow(
        shown.dismiss().shownToday(today),
        today,
        sparse,
      ),
      isFalse,
    );
  });
}
