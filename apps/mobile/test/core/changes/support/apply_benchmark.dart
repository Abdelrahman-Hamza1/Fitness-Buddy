import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';

import 'test_db.dart';

/// The timings of [runApplyBenchmark], in microseconds.
final class ApplyBenchmarkResult {
  /// The timings of [runs] change sets, sorted; [readsBeforePlan] says
  /// which variant ran.
  new(Iterable<int> micros, {required this.readsBeforePlan})
    : micros = List.unmodifiable(micros.toList()..sort());

  /// Whether each op's handler read once before planning.
  final bool readsBeforePlan;

  /// Every run, fastest first.
  final List<int> micros;

  /// The number of measured runs.
  int get runs => micros.length;

  /// The median, ms.
  double get medianMs => _percentile(0.5);

  /// The 95th percentile (nearest rank), ms.
  double get p95Ms => _percentile(0.95);

  double _percentile(double p) {
    final rank = (p * micros.length).ceil().clamp(1, micros.length);
    return micros[rank - 1] / 1000;
  }

  /// One line of numbers, no row values: `median 1.23 ms, p95 2.34 ms`.
  String summary(String where) =>
      'A01 apply benchmark ($where): 10-op change set (10 inserts over 2 '
      'tables${readsBeforePlan ? ', one TxReader read per op' : ''}), '
      '$runs runs: median ${medianMs.toStringAsFixed(2)} ms, '
      'p95 ${p95Ms.toStringAsFixed(2)} ms';
}

/// Applies `warmUps`, then [runs] measured change sets of 10 ops, each one
/// insert, alternating between the two synced test tables (A01 §5
/// performance), through [harness]'s applier. The clock moves 1 ms per
/// change set. Shared by the host test and the on-device Patrol test.
///
/// With [readsBeforePlan], each op's handler first reads the sync metadata
/// of the row it inserts (`TxReader.meta`), like a real handler checking
/// the current state: every read flushes the writes queued so far, so the
/// change set runs in ten batches instead of one (the worst case of the
/// batching).
Future<ApplyBenchmarkResult> runApplyBenchmark(
  Harness harness, {
  int warmUps = 20,
  int runs = 200,
  bool readsBeforePlan = false,
}) async {
  var row = 0;
  String nextId() =>
      '0199e3c2-5b1a-7c3d-8e4f-${(row++).toRadixString(16).padLeft(12, '0')}';

  ScriptOp insert(int i) {
    final RowOp write = i.isEven
        ? addNote(harness.db, nextId(), 'note $i')
        : addTag(harness.db, nextId(), 'tag $row');
    if (!readsBeforePlan) return ScriptOp.rows([write]);
    return ScriptOp((tx, _) async {
      if (await tx.meta(write.table, write.id) != null) {
        throw StateError('benchmark row exists');
      }
      return OpPlan([write]);
    });
  }

  ChangeSet tenInserts() => ChangeSet([
    for (var i = 0; i < 10; i++) insert(i),
  ], origin: Origin.direct);

  final micros = <int>[];
  final watch = Stopwatch();
  for (var n = 0; n < warmUps + runs; n++) {
    harness.clock.advance(const Duration(milliseconds: 1));
    final changeSet = tenInserts();
    watch
      ..reset()
      ..start();
    final result = await harness.applier.apply(changeSet);
    watch.stop();
    if (result is! Applied) throw StateError('benchmark apply: $result');
    if (n >= warmUps) micros.add(watch.elapsedMicroseconds);
  }
  return ApplyBenchmarkResult(micros, readsBeforePlan: readsBeforePlan);
}
