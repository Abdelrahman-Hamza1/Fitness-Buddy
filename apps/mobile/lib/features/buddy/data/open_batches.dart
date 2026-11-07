import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';

/// The open batches among [foods] at [nowUtc] (A67 D7): batch foods with
/// the grams already logged of each, still open (DY-043, DY-044).
Future<List<BatchFacts>> openBatches(
  AppDatabase db,
  List<PersonalFood> foods,
  DateTime nowUtc,
) async {
  final batches = [
    for (final f in foods)
      if (f.createdFrom == BatchFacts.openCode) f,
  ];
  if (batches.isEmpty) return const [];
  final ids = [for (final b in batches) b.id];
  final rows = await db
      .customSelect(
        'SELECT food_id, COALESCE(SUM(amount), 0) AS g '
        'FROM diary_entries WHERE deleted_at IS NULL '
        "AND food_kind = 'personal' AND food_id IN "
        '(${List.filled(ids.length, '?').join(', ')}) GROUP BY food_id',
        variables: [for (final id in ids) Variable<String>(id)],
        readsFrom: {db.diaryEntries},
      )
      .get();
  final eaten = <String, double>{
    for (final row in rows)
      row.read<String>('food_id'): (row.data['g'] as num? ?? 0).toDouble(),
  };
  final created = {
    for (final row in await (db.select(
      db.personalFoods,
    )..where((t) => t.id.isIn(ids))).get())
      row.id: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
  };
  return [
    for (final b in batches)
      if (BatchFacts(
            food: b,
            eatenGrams: eaten[b.id] ?? 0,
            createdAt: created[b.id] ?? nowUtc,
          )
          case final facts when facts.openAt(nowUtc))
        facts,
  ];
}
