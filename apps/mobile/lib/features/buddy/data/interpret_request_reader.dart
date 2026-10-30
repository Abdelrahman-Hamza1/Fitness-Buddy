import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/config/client_config.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_builder.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:fb_mobile/features/diary/diary.dart' show DiaryReads;
import 'package:fb_mobile/features/foods/foods.dart'
    show PersonalFoodMappingError, personalFoodOf;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'interpret_request_reader.g.dart';

/// Reads what an interpret request needs in one read-only snapshot and
/// builds it with [InterpretRequestBuilder] (A22 D10; ≤ 100 ms, `06` §10).
final class InterpretRequestReader {
  /// Reads [_db].
  const new(this._db);

  final AppDatabase _db;

  /// The request for message [requestId] with [text] at [now]; a follow-up
  /// on open card [activeCard] sends its bounded summary (A22b E1).
  Future<PreparedInterpret> prepare({
    required String requestId,
    required String text,
    required EntryTime now,
    SlotMode mode = SlotMode.normal,
    ProposalCard? activeCard,
  }) => _db.readSnapshot(() async {
    final slots = await DiaryReads(_db).slots();
    final rows = await (_db.select(
      _db.personalFoods,
    )..where((t) => t.deletedAt.isNull())).get();
    final foods = <PersonalFood>[];
    for (final row in rows) {
      try {
        foods.add(personalFoodOf(row));
      } on PersonalFoodMappingError {
        // An unreadable food is never sent.
      }
    }
    return InterpretRequestBuilder.build(
      requestId: requestId,
      text: text,
      now: now,
      slots: slots,
      personalFoods: foods,
      mode: mode,
      activeCard: activeCard,
    );
  });

  @override
  String toString() => 'InterpretRequestReader';
}

/// The interpret request reader of the open profile.
@Riverpod(keepAlive: true)
InterpretRequestReader interpretRequestReader(Ref ref) =>
    InterpretRequestReader(ref.watch(appDatabaseProvider));

/// The proposal loader of the open profile, with the client config snapshot
/// at load time (thresholds) and the installed catalog.
@Riverpod(keepAlive: true)
ProposalInputLoader proposalInputLoader(Ref ref) => ProposalInputLoader(
  ref.watch(appDatabaseProvider),
  catalog: ref.watch(offlineCatalogProvider),
  config: () => ref.read(clientConfigProvider),
);
