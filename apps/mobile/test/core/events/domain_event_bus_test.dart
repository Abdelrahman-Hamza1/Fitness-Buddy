import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../changes/support/test_db.dart';

void main() {
  test('on<T>() filters by type; delivery is synchronous', () {
    final bus = DomainEventBus();
    addTearDown(bus.close);
    final noted = <Noted>[];
    final all = <DomainEvent>[];
    bus.on<Noted>().listen(noted.add);
    bus.events.listen(all.add);
    final applied = ChangeSetApplied(
      changeSetId: 'c',
      origin: Origin.direct,
      entities: const {'testNote'},
    );
    bus
      ..emit(const Noted(1))
      ..emit(applied)
      ..emit(const Noted(2));
    // No await: listeners have run when emit returns.
    expect(noted, [const Noted(1), const Noted(2)]);
    expect(all, [const Noted(1), applied, const Noted(2)]);
  });

  test('a throwing listener is reported to its zone and the others still '
      'hear the event', () {
    final bus = DomainEventBus();
    addTearDown(bus.close);
    final errors = <Object>[];
    final heard = <DomainEvent>[];
    runZonedGuarded(
      () => bus.events.listen((_) => throw StateError('listener bug')),
      (error, _) => errors.add(error),
    );
    bus.events.listen(heard.add);
    bus.emit(const Noted(1));
    expect(errors, [isA<StateError>()]);
    expect(heard, [const Noted(1)]);
  });

  test('emit after close is ignored; the provider closes the bus', () async {
    final container = ProviderContainer.test();
    final bus = container.read(domainEventBusProvider);
    final done = expectLater(bus.events, emitsDone);
    container.dispose();
    await done;
    bus.emit(const Noted(1));
  });
}
