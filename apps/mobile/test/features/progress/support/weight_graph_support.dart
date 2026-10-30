import 'dart:math' as math;

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/graph_window.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import '../../body/support/weigh_in_harness.dart';
import '../../today/presentation/support/today_support.dart' show phoneApp;

/// The graph's today: the weigh-in harness's 17 October 2026.
LocalDate get graphToday => day17;

/// [days] daily weigh-ins ending today (`fixtureId(1…)`): a slow loss from
/// 96 kg with a little daily noise; the last one has a note.
List<WeighIn> seededHistory({int days = 730, double perDay = 0.012}) => [
  for (var i = 0; i < days; i++)
    storedWeighIn(
      i + 1,
      weighInDraft(
        ((96 - i * perDay + math.sin(i * 1.3) * 0.5) * 10).roundToDouble() / 10,
        date: graphToday.plusDays(i - days + 1),
        note: i == days - 1 ? 'After the run' : null,
      ),
    ),
];

/// An open "lose to [targetKg] at 0.5 kg/week" phase from [start], unnamed
/// unless [name].
Versioned<GoalPhaseRecord> losePhase(
  LocalDate start, {
  double targetKg = 85,
  String? name,
}) => Versioned(
  GoalPhaseRecord(
    id: '0199e3c2-5b1a-7000-8000-00000000f001',
    revision: 1,
    start: start,
    type: GoalType.lose,
    expression: GoalExpression.targetRate(targetKg, 0.5),
    weightInputUnit: MassUnit.kilogram,
    name: name,
  ),
  1,
);

/// The graph's providers other than the weigh-ins, the clock and the
/// units: today, no goal phases unless [phases], no targets, no highlights.
List<Override> graphExtras({
  List<Versioned<GoalPhaseRecord>> phases = const [],
}) => [
  todayProvider.overrideWith((ref) => Stream.value(graphToday)),
  goalHistoryProvider.overrideWith((ref) async => GoalPhases(phases)),
  targetsExplanationProvider.overrideWith((ref, date) async => null),
  chartHighlightPeriodsProvider.overrideWithValue(const []),
];

/// The graph's providers without a database: a fixed clock and day,
/// [weighIns], [phases], no targets, [units], [highlights] and the start
/// [range].
List<Override> graphOverrides({
  List<WeighIn>? weighIns,
  List<Versioned<GoalPhaseRecord>> phases = const [],
  UnitSystem units = UnitSystem.metric,
  List<({LocalDate start, LocalDate end})> highlights = const [],
  GraphRange? range = GraphRange.m3,
  Error? graphError,
}) => [
  clockProvider.overrideWithValue(ManualClock(harnessNow, offsetMinutes: 180)),
  todayProvider.overrideWith((ref) => Stream.value(graphToday)),
  weighInsProvider.overrideWith(
    (ref) => Stream.value(weighIns ?? seededHistory()),
  ),
  if (graphError != null)
    weightGraphProvider.overrideWith((ref) async => throw graphError),
  goalHistoryProvider.overrideWith((ref) async => GoalPhases(phases)),
  targetsExplanationProvider.overrideWith((ref, date) async => null),
  unitSystemProvider.overrideWith((ref) => Stream.value(units)),
  chartHighlightPeriodsProvider.overrideWithValue(highlights),
  if (range != null)
    weightGraphWindowControllerProvider.overrideWithBuild(
      (ref, notifier) => (range: range, panStart: null),
    ),
];

/// The weight graph screen on a 360 dp phone.
Widget graphApp(
  List<Override> overrides, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) => ProviderScope(
  overrides: overrides,
  child: phoneApp(
    const WeightGraphScreen(),
    brightness: brightness,
    textScale: textScale,
  ),
);
