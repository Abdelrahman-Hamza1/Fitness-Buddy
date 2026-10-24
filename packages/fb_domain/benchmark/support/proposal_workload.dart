import 'dart:io';

import 'package:fb_domain/fb_domain.dart';

// Synthetic fixture builders have no test-framework imports or side effects.
import '../../test/proposals/proposal_fixtures.dart' as fixture;

/// Shared host/device protocol. Never report food values or proposal objects.
const proposalScenarioId = 'a21-six-lines-weekly-v1';

/// Prepares all JSON, facts, IDs and absolute adjustments outside timing.
final class ProposalWorkload {
  /// Five ingredients plus one generated oil line; all remain active.
  new() {
    final rice = fixture.riceItem();
    final chicken = fixture.item(
      match: fixture.food(key: 'usda:chicken', kcal: 165),
      amount: 150,
      unit: 'g',
      alternatives: [
        fixture.food(key: 'usda:chicken2', kcal: 180),
        fixture.food(key: 'usda:chicken3', kcal: 195),
      ],
      dimensions: [fixture.fatDimension()],
    );
    final plate = fixture.serving('plate', 350)
      ..['rangeLo'] = 250.0
      ..['rangeHi'] = 450.0;
    final reference = fixture.item(
      match: fixture.food(
        key: 'ref:plate',
        source: 'reference',
        kcal: 190,
        servings: [plate],
      ),
      unit: 'plate',
      explicit: false,
      dimensions: [
        fixture.dimension('portion', [
          fixture.option('small', amount: 1, unit: 'plate'),
          fixture.option('large', amount: 2, unit: 'plate'),
        ]),
      ],
    );
    final cooked = fixture.food(
      key: 'usda:converted_rice',
      kcal: 130,
      group: 'rice',
    );
    final converted = fixture.item(
      match: cooked,
      amount: 80,
      unit: 'g',
      dimensions: [
        fixture.dimension('state', [
          fixture.option('cooked', candidate: cooked),
        ], stated: 'dry'),
      ],
    );
    final date = LocalDate(2026, 10, 17);
    final context = ProposalContext(
      referenceTime: EntryTime(DateTime.utc(2026, 10, 17, 12), 0),
      slots: [DefaultSlots.lunch, DefaultSlots.snacks],
      yields: [
        YieldFactor(group: 'rice', from: .dry, to: .cooked, factor: 2.5),
      ],
      dayContext: ProposalDayContext(
        today: date,
        weightKg: 70,
        calendar: const WeekCalendar(weekStart: DayOfWeek.monday),
        confirmed: {date: fixture.nutrients(500)},
        earlierIntake: [
          WeekIntake(date: date.plusDays(-1), kcal: 1800),
          WeekIntake(date: date.plusDays(-2), kcal: 0, complete: false),
        ],
        workoutWeights: {DayOfWeek.saturday: 1.2},
        history: TargetSettingsHistory([
          TargetSettings(
            id: '019a1b2c-0000-7000-8000-000000007777',
            version: 1,
            effectiveFrom: date.plusDays(-30),
            standard: TargetPlan(baseKcal: 2000, floorKcal: 1200),
          ),
        ]),
      ),
    );
    session = fixture.session(
      fixture.message([
        fixture.intent(
          [rice, chicken, reference, converted, fixture.item()],
          slot: 'lunch',
          group: 'Synthetic benchmark',
        ),
      ]),
      ctx: context,
    );
    // Allocate questions while fat is unsettled; then activate generated oil.
    final fat = session.cards.single.lines[1].dimensions.single;
    session = ProposalEngine.recompute(
      session,
      ProposalSelect(fat.id, fat.options.last.id),
    ).value!.session;
    final card = session.cards.single;
    final state = card.lines.first.dimensions.single;
    adjustments = [
      ProposalSetAmount(card.lines.last.entry.id, Quantity(2, 'piece')),
      ProposalSelect(state.id, state.options.last.id),
      ProposalSetAmount(card.lines.last.entry.id, Quantity(1, 'piece')),
      ProposalSelect(state.id, state.options.first.id),
    ];
    // Fail loudly if future fixture changes silently weaken the workload.
    if (!card.canConfirm ||
        card.lines.length != 6 ||
        card.range == null ||
        card.preview.targetsUnavailable ||
        !card.lines.any((line) => line.yieldNote != null)) {
      throw StateError('A21 benchmark fixture invalid');
    }
  }

  /// Replacement state, consumed by the next measured recompute.
  late ProposalSession session;

  /// Four alternating amount/option edits, preallocated before measurement.
  late final List<ProposalAdjustment> adjustments;
}

/// Engine-only timings; consumption and reporting occur outside each stopwatch.
final class ProposalBenchmarkResult {
  new _(this.microseconds, this.checksum);

  /// Sorted individual timings; outliers are retained.
  final List<int> microseconds;

  /// Structural checksum, never food numbers or names.
  final int checksum;

  double get _medianMs => (microseconds[499] + microseconds[500]) / 2000;

  /// Nearest-rank p95 over all 1,000 samples.
  double get p95Ms => microseconds[949] / 1000;

  /// Safe metadata only; callers supply explicit SDK/build/host descriptions.
  String report({required String mode, required String host}) =>
      'scenario=$proposalScenarioId sdk=${Platform.version.split(' ').first} '
      'mode=$mode host=$host warmups=200 samples=1000 '
      'median_ms=${_medianMs.toStringAsFixed(3)} '
      'p95_ms=${p95Ms.toStringAsFixed(3)} '
      'max_ms=${(microseconds.last / 1000).toStringAsFixed(3)} '
      'checksum=$checksum';
}

/// Times reducer, question allocation, ops, diff and weekly preview together.
ProposalBenchmarkResult runProposalBenchmark(ProposalWorkload workload) {
  final samples = List<int>.filled(1000, 0);
  final timer = Stopwatch();
  var checksum = 0;
  for (var i = 0; i < 1200; i++) {
    final adjustment = workload.adjustments[i % workload.adjustments.length];
    timer
      ..reset()
      ..start();
    final result = ProposalEngine.recompute(workload.session, adjustment);
    timer.stop();
    final elapsed = timer.elapsedMicroseconds;
    final update = result.value;
    if (update == null) throw StateError('A21 benchmark recompute failed');
    workload.session = update.session;
    final card = update.session.cards.single;
    if (!card.canConfirm || update.diff.isEmpty) {
      throw StateError('A21 benchmark workload became a no-op');
    }
    checksum +=
        card.lines.length +
        card.draftOps.length +
        update.diff.lineFields.length +
        update.diff.cardFields.length +
        update.session.budget.questions.length;
    if (i >= 200) samples[i - 200] = elapsed;
  }
  samples.sort();
  return ProposalBenchmarkResult._(List.unmodifiable(samples), checksum);
}
