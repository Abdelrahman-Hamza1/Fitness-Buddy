import 'dart:async';

import 'package:fb_mobile/core/home_widget/home_widget_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> calls;
  bool? committed;
  Completer<void>? holdSave;

  setUp(() {
    calls = [];
    committed = true;
    holdSave = null;
    messenger.setMockMethodCallHandler(ChannelHomeWidgetStore.channel, (
      call,
    ) async {
      if (call.method == 'save') await holdSave?.future;
      calls.add(call.method);
      return call.method == 'clearDurably' ? committed : null;
    });
  });

  tearDown(
    () => messenger.setMockMethodCallHandler(
      ChannelHomeWidgetStore.channel,
      null,
    ),
  );

  test('UX-085 A71 review: clearAndHold clears durably and refuses every '
      'save until release, also one queued before it', () async {
    final store = ChannelHomeWidgetStore(supported: true);
    holdSave = Completer();
    final inFlight = store.save({'v': 1});
    // That save has reached the platform; the next one only waits in line.
    await Future<void>.delayed(Duration.zero);
    final queued = store.save({'v': 1});
    final cleared = store.clearAndHold();
    final after = store.save({'v': 1});
    holdSave!.complete();
    await Future.wait([inFlight, queued, cleared, after]);
    // The save already sent lands before the clear; the others are refused.
    expect(calls, ['save', 'clearDurably']);
    expect(store.held, isTrue);

    store.release();
    await store.save({'v': 1});
    expect(calls, ['save', 'clearDurably', 'save']);
  });

  test('A71 review: an unconfirmed clear throws (the transition fails '
      'closed); no widget channel is no widgets to clear', () async {
    final store = ChannelHomeWidgetStore(supported: true);
    committed = false;
    await expectLater(store.clearAndHold(), throwsStateError);

    messenger.setMockMethodCallHandler(ChannelHomeWidgetStore.channel, null);
    await store.clearAndHold();

    final off = ChannelHomeWidgetStore(supported: false);
    await off.clearAndHold();
    await off.save({'v': 1});
  });
}
