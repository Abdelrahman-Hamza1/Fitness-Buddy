import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

WeighIn _weighIn(LocalDate date, double kg, int n) {
  final input = WeighInInput(kg, MassUnit.kilogram);
  return WeighIn(
    id: '0199e3c2-5b1a-7000-8000-${n.toRadixString(16).padLeft(12, '0')}',
    version: 1,
    time: EntryTime.local(LocalDateTime(date, hour: 7), 180),
    localDate: date,
    kg: input.kg,
    input: input,
  );
}

void main() {
  test('WB-020 the graph follows the local date across midnight', () async {
    final days = StreamController<LocalDate>();
    addTearDown(days.close);
    final first = LocalDate(2026, 10, 28);
    final container = ProviderContainer.test(
      overrides: [
        todayProvider.overrideWith((ref) => days.stream),
        weighInsProvider.overrideWith(
          (ref) => Stream.value([
            for (var i = 0; i < 20; i++)
              _weighIn(first.plusDays(i - 19), 90 - i * 0.1, i + 1),
          ]),
        ),
        goalHistoryProvider.overrideWith((ref) async => GoalPhases(const [])),
        targetsExplanationProvider.overrideWith((ref, date) async => null),
        unitSystemProvider.overrideWith(
          (ref) => Stream.value(UnitSystem.metric),
        ),
      ],
    )..listen(weightGraphProvider, (_, _) {});
    days.add(first);
    final before = await container.read(weightGraphProvider.future);
    expect(before.today, first);
    expect(before.weighIns, hasLength(20));
    expect(
      (before.monthlyRate as MonthlyRateUnavailable).gap,
      MonthlyRateGap.noTargets,
    );

    days.add(first.plusDays(1));
    await Future<void>.delayed(Duration.zero);
    final after = await container.read(weightGraphProvider.future);
    expect(after.today, first.plusDays(1));
  });
}
