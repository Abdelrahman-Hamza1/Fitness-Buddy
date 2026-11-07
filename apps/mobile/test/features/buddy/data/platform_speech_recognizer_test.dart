import 'dart:async';

import 'package:fb_mobile/features/buddy/data/speech_recognizer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';

const _channel = MethodChannel('plugin.csdcorp.com/speech_to_text');

void main() {
  late List<String> calls;
  late List<Object?> listenArgs;

  setUp(() {
    calls = [];
    listenArgs = [];
  });

  void platform(
    WidgetTester tester, {
    List<String> locales = const ['en_US:English', 'ar_SA:Arabic'],
  }) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (
      call,
    ) {
      calls.add(call.method);
      return switch (call.method) {
        'has_permission' || 'initialize' || 'listen' => () {
          if (call.method == 'listen') listenArgs.add(call.arguments);
          return Future<Object?>.value(true);
        }(),
        'locales' => Future<Object?>.value(locales),
        // A platform that never answers Stop (A70 review 5).
        'stop' => Completer<Object?>().future,
        _ => Future<Object?>.value(),
      };
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _channel,
        null,
      ),
    );
  }

  testWidgets('A70 review 1 always on-device; a language the recogniser '
      "doesn't list fails before listening", (tester) async {
    platform(tester, locales: const ['en_US:English']);
    final r = PlatformSpeechRecognizer(
      engine: SpeechToText.withMethodChannel(),
    );
    expect(await r.prepare(), SpeechReadiness.ready);
    final arabic = <SpeechEvent>[];
    r.listen(VoiceLanguage.arabic).listen(arabic.add);
    await tester.pump();
    expect(arabic.single, isA<SpeechFailed>());
    expect((arabic.single as SpeechFailed).problem, VoiceProblem.language);
    expect(calls, isNot(contains('listen')));

    r.listen(VoiceLanguage.english).listen((_) {});
    await tester.pump();
    final args = listenArgs.single! as Map<Object?, Object?>;
    expect(args['onDevice'], isTrue);
    expect(args['localeId'], 'en_US');
    await r.cancel();
    await tester.pump();
  });

  testWidgets('A70 review 5 Stop ends the session within the grace even when '
      'the platform never answers, and cancels the recogniser', (tester) async {
    platform(tester);
    final r = PlatformSpeechRecognizer(
      engine: SpeechToText.withMethodChannel(),
    );
    await r.prepare();
    final events = <SpeechEvent>[];
    var closed = false;
    r
        .listen(VoiceLanguage.english)
        .listen(events.add, onDone: () => closed = true);
    await tester.pump();
    unawaited(r.stop());
    await tester.pump(const Duration(seconds: 2));
    expect(closed, isFalse);
    expect(calls, isNot(contains('cancel')));
    await tester.pump(PlatformSpeechRecognizer.stopGrace);
    expect(events.last, isA<SpeechEnded>());
    expect(closed, isTrue);
    expect(calls, contains('cancel'));
    expect(calls.where((c) => c == 'listen'), hasLength(1));
  });
}
