import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import '../support/weigh_in_harness.dart';

void main() {
  /// Reads [provider] after the database settles, waiting out a reload.
  Future<T> settled<T>(
    ProviderContainer container,
    ProviderListenable<AsyncValue<T>> provider,
    bool Function(T value) done,
  ) async {
    for (var i = 0; i < 100; i++) {
      final value = container.read(provider);
      if (value case AsyncData(:final value) when done(value)) return value;
      await pumpEventQueue();
    }
    fail('$provider never settled');
  }

  test('PA1 currentWeightKgProvider is the latest trend and null without '
      'weigh-ins; it updates after a weigh-in is logged', () async {
    final h = WeighInHarness();
    final container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(h.db)],
    );
    final current = container.listen(currentWeightKgProvider, (_, _) {});
    addTearDown(current.close);

    expect(
      await settled<double?>(container, currentWeightKgProvider, (_) => true),
      isNull,
    );

    await h.apply([
      CreateWeighIn(fixtureId(1), weighInDraft(98, date: day17.plusDays(-7))),
    ]);
    expect(
      await settled<double?>(
        container,
        currentWeightKgProvider,
        (v) => v != null,
      ),
      98,
    );

    // A weekly weigh-in moves the trend halfway (D1): 98 → 97.
    await h.apply([CreateWeighIn(fixtureId(2), weighInDraft(96))]);
    expect(
      await settled<double?>(
        container,
        currentWeightKgProvider,
        (v) => v != 98,
      ),
      97,
    );
  });

  test('WB-010 weighInsProvider and weightTrendProvider follow the live '
      'weigh-ins', () async {
    final h = WeighInHarness();
    await h.seed([
      weighInDraft(98, date: day17.plusDays(-7)),
      weighInDraft(97.6, date: day17.plusDays(-7), hour: 9),
      weighInDraft(96),
    ]);
    final container = ProviderContainer.test(
      overrides: [appDatabaseProvider.overrideWithValue(h.db)],
    );
    final trend = container.listen(weightTrendProvider, (_, _) {});
    addTearDown(trend.close);
    final list = container.listen(weighInsProvider, (_, _) {});
    addTearDown(list.close);

    final weighIns = await settled<List<WeighIn>>(
      container,
      weighInsProvider,
      (v) => v.length == 3,
    );
    expect(weighIns.map((w) => w.id), [
      fixtureId(1),
      fixtureId(2),
      fixtureId(3),
    ]);
    final computed = await settled<WeightTrend>(
      container,
      weightTrendProvider,
      (v) => v.points.length == 2,
    );
    // The day's earliest counts (WB-003), the trend holds between days.
    expect(computed.points.first.weighInId, fixtureId(1));
    expect(computed.trendOn(day17.plusDays(-1)), 98);
    expect(computed.latest!.trendKg, 97);
    expect(computed, TrendWeight().compute(weighIns));

    await h.apply([DeleteWeighIn(VersionedId(fixtureId(3), 1))]);
    final after = await settled<WeightTrend>(
      container,
      weightTrendProvider,
      (v) => v.points.length == 1,
    );
    expect(after.latest!.trendKg, 98);
  });
}
