/// One serial write lane per Buddy thread (A23 D7, D8, PA1).
///
/// Every persisted change of the thread's proposals (a reply, a follow-up,
/// a coalesced adjustment, a confirm, a discard, a rebuild) runs as a job
/// here, one after another, and builds its ops from the **latest**
/// in-memory sessions when it runs, never from sessions captured earlier.
/// With the handler's revision guard (`proposalStale`), every order of
/// edits stores one consistent session per message.
///
/// Adjustments don't write at once: [schedule] marks the message's session
/// as having a pending latest-wins write (one per message), written by
/// [flush] (sheet dismissed, app paused) or by [drain] inside a confirm or
/// discard job before the resolve. No timer.
final class ProposalWriteLane {
  Future<void> _tail = Future.value();
  final Set<String> _pending = {};

  /// Runs [job] after every job queued before it. A failing job never stops
  /// the lane; its error goes to the caller.
  Future<T> run<T>(Future<T> Function() job) {
    final result = _tail.then((_) => job());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Marks message [messageId]'s session as changed since its last write.
  void schedule(String messageId) => _pending.add(messageId);

  /// Whether any message has a pending write.
  bool get hasPending => _pending.isNotEmpty;

  /// Whether [messageId] has a pending write.
  bool isPending(String messageId) => _pending.contains(messageId);

  /// Writes every pending session, as a job of its own.
  Future<void> flush(Future<bool> Function(String messageId) write) =>
      run(() => drain(write));

  /// Inside a running job: writes every pending session now, each with
  /// [write] (which reads the latest session). A write that returns `false`
  /// (a newer stored revision, `proposalStale`) is dropped silently; a newer
  /// job follows.
  Future<void> drain(Future<bool> Function(String messageId) write) async {
    for (final message in [..._pending]) {
      _pending.remove(message);
      try {
        await write(message);
        // A failed bookkeeping write never blocks the lane; the next change
        // schedules the message again.
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {}
    }
  }

  @override
  String toString() => 'ProposalWriteLane(${_pending.length} pending)';
}
