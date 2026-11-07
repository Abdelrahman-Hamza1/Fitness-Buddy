import 'dart:async';

import 'package:fb_mobile/features/buddy/data/chat_message_repository.dart';
import 'package:fb_mobile/features/buddy/data/proposal_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_proposals.g.dart';

/// How many Buddy cards wait to be confirmed or discarded, of any kind,
/// plus messages waiting to be processed (AI-045, AI-047, HM-004, D-094):
/// Today's Buddy bar shows it as "{n} waiting". Re-emitted on every change;
/// pending cards never count toward totals.
@riverpod
Stream<int> pendingProposalCount(Ref ref) {
  final cards = ref
      .watch(proposalRepositoryProvider)
      .watchPending()
      .map((pending) => pending.length);
  final messages = ref.watch(chatMessageRepositoryProvider).watchWaiting();
  final out = StreamController<int>();
  int? c;
  int? m;
  void emit() {
    if (c != null && m != null) out.add(c! + m!);
  }

  final subs = [
    cards.listen((n) {
      c = n;
      emit();
    }, onError: out.addError),
    messages.listen((n) {
      m = n;
      emit();
    }, onError: out.addError),
  ];
  ref.onDispose(() async {
    for (final s in subs) {
      await s.cancel();
    }
    await out.close();
  });
  return out.stream.distinct();
}
