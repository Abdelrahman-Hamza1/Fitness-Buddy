import 'package:fb_api_client/fb_api_client.dart' hide LocalDate;
import 'package:fb_domain/fb_domain.dart';

/// The generated QueryPlan and result types ⇄ the QueryEngine's (A68 D4).
/// A plan with an unknown enum value or an unreadable date doesn't map
/// (the tool answers `unsupportedPlan`). Holds user content: never logged.
abstract final class QueryPlanCodec {
  /// The engine plan of [plan], or `null` when it doesn't map.
  static QueryPlan? plan(BuddyQueryPlan plan) {
    final metric = _byName(QueryMetric.values, plan.metric.json);
    final op = _byName(QueryOp.values, plan.op.json);
    final kind = _byName(QueryPeriodKind.values, plan.period.kind.json);
    if (metric == null || op == null || kind == null) return null;
    final p = plan.period;
    final since = p.since == null
        ? null
        : _byName(QuerySince.values, p.since!.json);
    if (p.since != null && since == null) return null;
    LocalDate? date(String? text) =>
        text == null ? null : LocalDate.tryParse(text);
    final from = date(p.from);
    final to = date(p.to);
    if ((p.from != null && from == null) || (p.to != null && to == null)) {
      return null;
    }
    final f = plan.filters;
    return QueryPlan(
      metric: metric,
      op: op,
      measurementType: plan.measurementType,
      period: QueryPeriod(kind, days: p.days, since: since, from: from, to: to),
      filters: f == null
          ? const QueryFilters()
          : QueryFilters(
              slot: _blank(f.slot),
              exerciseRef: _blank(f.exerciseRef),
              muscleGroup: _blank(f.muscleGroup),
              completeDaysOnly: f.completeDaysOnly,
              weekdays: f.weekdays.toSet(),
            ),
    );
  }

  /// The result data of [answer].
  static BuddyQueryResultData result(QueryAnswer answer) =>
      BuddyQueryResultData(
        claims: [
          for (final c in answer.claims.take(20))
            BuddyClaimValue(
              metric: BuddyQueryMetric.fromJson(c.metric.name),
              operation: BuddyQueryOp.fromJson(c.op.name),
              value: c.value,
              date: c.date?.toString(),
              unit: BuddyClaimUnit.fromJson(c.unit.name),
              workoutId: c.workoutId,
              exerciseRef: c.exerciseRef,
              muscleGroup: c.muscleGroup?.name,
            ),
        ],
        coverage: BuddyCoverage(
          days: answer.days.clamp(0, QueryEngine.maxDays),
          loggedDays: answer.loggedDays.clamp(0, QueryEngine.maxDays),
        ),
        link: switch (answer.link) {
          null => null,
          final l => BuddyQueryLink(
            screen: BuddyLinkScreen.fromJson(l.screen.name),
            date: l.date?.toString(),
            from: l.from?.toString(),
            to: l.to?.toString(),
            exerciseRef: l.exerciseRef,
            workoutId: l.workoutId,
          ),
        },
      );

  static String? _blank(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  static T? _byName<T extends Enum>(List<T> values, String? name) =>
      values.where((v) => v.name == name).firstOrNull;
}
