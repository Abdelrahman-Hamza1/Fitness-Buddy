import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_fixtures.dart';
import 'proposal_recompute_test.dart' show update;

final date = LocalDate(2026, 10, 17);
ProposalContext dayContext({
  Map<LocalDate, Nutrients> confirmed = const {},
  TargetPlan? plan,
  Iterable<WeekIntake> earlier = const [],
  bool ramadan = false,
  int revision = 0,
}) => ProposalContext(
  referenceTime: context().referenceTime,
  slots: context().slots,
  dayContext: ProposalDayContext(
    today: date,
    weightKg: 70,
    calendar: const WeekCalendar(weekStart: DayOfWeek.monday),
    confirmed: confirmed,
    revision: revision,
    earlierIntake: earlier,
    ramadan: ramadan,
    history: plan == null
        ? null
        : TargetSettingsHistory([
            TargetSettings(
              id: '019a1b2c-0000-7000-8000-000000007777',
              version: 1,
              effectiveFrom: date.plusDays(-30),
              standard: plan,
              ramadan: TargetPlan(
                baseKcal: 2200,
                floorKcal: 1200,
                mode: .fixed,
              ),
            ),
            TargetSettings(
              id: '019a1b2c-0000-7000-8000-000000007778',
              version: 2,
              effectiveFrom: date.plusDays(1),
              standard: TargetPlan(baseKcal: 2500, floorKcal: 1200),
            ),
          ]),
  ),
);

void main() {
  // rule: A21 privacy
  test('A21 day context diagnostics omit confirmed intake', () {
    expect(dayContext().dayContext.toString(), 'ProposalDayContext(redacted)');
  });
  test('AI-031 today after this includes only this active card', () {
    final s = session(
      message([
        intent([item()]),
        intent([item(amount: 2)], slot: 'dinner'),
      ]),
      ctx: dayContext(confirmed: {date: nutrients(500)}),
    );
    expect(s.cards.map((c) => c.preview.eaten!.kcal), [572, 644]);
  });
  test('AI-031 sibling card confirmed is not double counted', () {
    final s = session(
      message([
        intent([item()]),
        intent([item(amount: 2)], slot: 'dinner'),
      ]),
      ctx: dayContext(confirmed: {date: nutrients(500)}),
    );
    final u = update(
      s,
      ProposalSetLifecycle(s.cards.first.id, .confirmed),
      ctx: dayContext(confirmed: {date: nutrients(572)}, revision: 1),
    );
    expect(u.session.cards.first.preview.eaten!.kcal, 572);
    expect(u.session.cards.last.preview.eaten!.kcal, 716);
    expect(u.session.cards.first.draftOps, isEmpty);
    expect(u.session.cards.last.preview.revision, 1);
  });
  // rule: A21 confirmed-only-targets
  test(
    'A21 pending drafts never enter weekly rebalance or confirmed totals',
    () {
      final plan = TargetPlan(baseKcal: 2000, floorKcal: 1200);
      final ctx = dayContext(
        plan: plan,
        earlier: [WeekIntake(date: date.plusDays(-1), kcal: 1800)],
      );
      final a = session(message(), ctx: ctx).cards.single;
      final b = session(
        message([
          intent([item(amount: 10)]),
        ]),
        ctx: ctx,
      ).cards.single;
      expect(a.preview.targetKcal, b.preview.targetKcal);
      expect(ctx.dayContext!.confirmed, isEmpty);
    },
  );
  // rule: A21 A12-integration
  test('A21 preview preserves unknown earlier day reservations', () {
    final plan = TargetPlan(baseKcal: 2000, floorKcal: 1200);
    final earlier = [
      WeekIntake(date: date.plusDays(-1), kcal: 0, complete: false),
    ];
    final ctx = dayContext(plan: plan, earlier: earlier);
    final card = session(message(), ctx: ctx).cards.single;
    expect(
      card.preview.targetKcal,
      plan
          .day(
            date: date,
            weightKg: 70,
            calendar: ctx.dayContext!.calendar,
            earlierIntake: earlier,
          )
          .kcal,
    );
  });
  // rule: A21 A12-integration
  test('A21 preview uses fixed manual or weekly A12 targets unchanged', () {
    for (final plan in [
      TargetPlan(baseKcal: 1900, floorKcal: 1200, mode: .fixed),
      TargetPlan(
        baseKcal: 1000,
        floorKcal: 1200,
        mode: .fixed,
        manual: true,
        acknowledged: true,
      ),
      TargetPlan(baseKcal: 2000, floorKcal: 1200),
    ]) {
      final ctx = dayContext(plan: plan);
      expect(
        session(message(), ctx: ctx).cards.single.preview.targetKcal,
        plan
            .day(date: date, weightKg: 70, calendar: ctx.dayContext!.calendar)
            .kcal,
      );
      expect(
        session(
          message(),
          ctx: dayContext(plan: plan, ramadan: true),
        ).cards.single.preview.targetKcal,
        2200,
      );
    }
  });
  test('AI-031 past day drafts do not change today preview', () {
    final s = session(
      message([
        intent([item()], time: 'yesterday'),
        intent([item(amount: 2)]),
      ]),
      ctx: dayContext(confirmed: {date: nutrients(500)}),
    );
    expect(s.cards.first.preview.date, date.plusDays(-1));
    expect(s.cards.first.preview.eaten, isNull);
    expect(s.cards.last.preview.eaten!.kcal, 644);
  });
  test(
    'AI-031 missing targets is unavailable and negative remaining is retained',
    () {
      expect(
        session(message()).cards.single.preview.targetsUnavailable,
        isTrue,
      );
      expect(session(message()).cards.single.preview.remainingKcal, isNull);
      final c = session(
        message(),
        ctx: dayContext(
          confirmed: {date: nutrients(3000)},
          plan: TargetPlan(baseKcal: 2000, floorKcal: 1200, mode: .fixed),
        ),
      ).cards.single;
      expect(c.preview.remainingKcal, -1072);
    },
  );
  // rule: A21 lifecycle
  test('A21 confirmed or discarded card has no active draft contribution', () {
    final s = session(message());
    for (final lifecycle in [
      ProposalLifecycle.confirmed,
      ProposalLifecycle.discarded,
      ProposalLifecycle.superseded,
    ]) {
      final c = update(
        s,
        ProposalSetLifecycle(s.cards.single.id, lifecycle),
      ).session;
      expect(c.cards.single.canConfirm, isFalse);
      expect(c.cards.single.totals, Nutrients.zero);
      expect(c.cards.single.preview.eaten, isNull);
      expect(
        ProposalEngine.recompute(
          c,
          ProposalSetLifecycle(c.cards.single.id, .active),
        ).issue,
        ProposalIssue.invalidInput,
      );
    }
  });
}
