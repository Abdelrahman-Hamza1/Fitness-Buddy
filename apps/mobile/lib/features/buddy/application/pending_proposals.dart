import 'package:fb_mobile/features/buddy/data/proposal_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_proposals.g.dart';

/// How many Buddy cards wait to be confirmed or discarded, of any kind
/// (AI-045, HM-004, D-094): Today's Buddy bar shows it as "{n} waiting".
/// Re-emitted on every change; pending cards never count toward totals.
@riverpod
Stream<int> pendingProposalCount(Ref ref) => ref
    .watch(proposalRepositoryProvider)
    .watchPending()
    .map((pending) => pending.length)
    .distinct();
