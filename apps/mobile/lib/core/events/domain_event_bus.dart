import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'domain_event_bus.g.dart';

/// The app's domain events (A01 D4): how features react to each other's
/// changes (`03` §4). The `ChangeSetApplier` emits after each commit, in op
/// order, and never on rollback.
///
/// Delivery is synchronous: every listener has run when [emit] returns. A
/// listener that throws is reported to its zone's error handler and doesn't
/// stop the others or fail the apply.
final class DomainEventBus {
  /// An open bus.
  new();

  final StreamController<DomainEvent> _events =
      StreamController<DomainEvent>.broadcast(sync: true);

  /// Every event.
  Stream<DomainEvent> get events => _events.stream;

  /// The events of type [T].
  Stream<T> on<T extends DomainEvent>() =>
      _events.stream.where((e) => e is T).cast<T>();

  /// Sends [event] to the listeners. Only the applier calls this. Ignored
  /// after [close].
  void emit(DomainEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  /// Ends the streams.
  Future<void> close() => _events.close();
}

/// The app's [DomainEventBus]. Consumers subscribe in their own provider and
/// cancel in `ref.onDispose`.
@Riverpod(keepAlive: true)
DomainEventBus domainEventBus(Ref ref) {
  final bus = DomainEventBus();
  ref.onDispose(() => unawaited(bus.close()));
  return bus;
}
