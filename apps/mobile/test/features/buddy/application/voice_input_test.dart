import 'dart:async';

import 'package:fb_mobile/features/buddy/application/voice_input.dart';
import 'package:fb_mobile/features/buddy/data/speech_recognizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_speech.dart';

void main() {
  group('AI-014 appendTranscript', () {
    test('AI-014 puts the words after typed text with one space', () {
      expect(appendTranscript('', ' 2 eggs '), '2 eggs');
      expect(appendTranscript('breakfast:', '2 eggs'), 'breakfast: 2 eggs');
      expect(appendTranscript('breakfast ', '2 eggs'), 'breakfast 2 eggs');
      expect(appendTranscript('tea', '   '), 'tea');
    });

    test('AI-014 caps at the composer limit without splitting a pair', () {
      expect(appendTranscript('ab', 'cdef', limit: 5), 'ab cd');
      // 'x' + space + '😀' is 4 units; a cut at 3 would split the emoji.
      expect(appendTranscript('x', '😀', limit: 3), 'x ');
    });
  });

  group('A70 pickSpeechLocale', () {
    test("A70 prefers the phone's own locale of that language", () {
      final ids = ['en-US', 'en-GB', 'ar-SA', 'ar-JO'];
      expect(
        pickSpeechLocale(ids, VoiceLanguage.arabic, system: 'ar_JO'),
        'ar-JO',
      );
      expect(
        pickSpeechLocale(ids, VoiceLanguage.english, system: 'ar_JO'),
        'en-US',
      );
      expect(pickSpeechLocale(['ar_EG'], VoiceLanguage.arabic), 'ar_EG');
      expect(pickSpeechLocale(const [], VoiceLanguage.arabic), 'ar_SA');
    });
  });

  group('A70 VoiceInputController', () {
    late FakeSpeechRecognizer speech;
    late MemoryVoiceLanguageStore store;
    late ProviderContainer container;

    VoiceState state() => container.read(voiceInputControllerProvider);
    VoiceInputController notifier() =>
        container.read(voiceInputControllerProvider.notifier);

    void setUpWith({bool allowed = true, SpeechReadiness? readiness}) {
      speech = FakeSpeechRecognizer(
        allowed: allowed,
        readiness: readiness ?? SpeechReadiness.ready,
      );
      store = MemoryVoiceLanguageStore(VoiceLanguage.arabic);
      container = ProviderContainer(overrides: fakeSpeech(speech, store));
      addTearDown(container.dispose);
      container.listen(voiceInputControllerProvider, (_, _) {});
    }

    test(
      'AI-014 listens in the remembered language and ends with the words',
      () async {
        setUpWith();
        await notifier().start();
        expect(state().phase, VoicePhase.listening);
        expect(speech.listened, [VoiceLanguage.arabic]);
        speech.hear('صحن');
        await pumpEventQueue();
        expect(state().words, 'صحن');
        speech
          ..hear('صحن حمص ')
          ..end();
        await pumpEventQueue();
        expect(state().phase, VoicePhase.done);
        expect(state().words, 'صحن حمص');
      },
    );

    test('AI-014 asks first; denied is the permission problem', () async {
      setUpWith(allowed: false, readiness: SpeechReadiness.denied);
      await notifier().start();
      expect(state().phase, VoicePhase.asking);
      expect(speech.prepares, 0);
      await notifier().allow();
      expect(state().phase, VoicePhase.failed);
      expect(state().problem, VoiceProblem.permission);
      expect(speech.listened, isEmpty);
    });

    test(
      'AI-014 nothing heard is noSpeech; switching language restarts',
      () async {
        setUpWith();
        await notifier().start();
        speech.end();
        await pumpEventQueue();
        expect(state().problem, VoiceProblem.noSpeech);
        await notifier().switchLanguage(VoiceLanguage.english);
        expect(store.language, VoiceLanguage.english);
        expect(state().phase, VoicePhase.listening);
        expect(speech.listened, [VoiceLanguage.arabic, VoiceLanguage.english]);
      },
    );

    testWidgets('A70 review 3+5 Done mid-session never listens again and '
        'ends by the deadline when the platform stop never answers', (
      tester,
    ) async {
      setUpWith();
      speech.stopAnswer = Completer<void>().future;
      await notifier().start();
      speech.hear('two eggs');
      await tester.pump();
      notifier().stop();
      expect(state().phase, VoicePhase.finishing);
      await tester.pump(const Duration(seconds: 2));
      expect(state().phase, VoicePhase.finishing);
      await tester.pump(VoiceInputController.stopDeadline);
      expect(state().phase, VoicePhase.done);
      expect(state().words, 'two eggs');
      // The recogniser was cancelled at the deadline; one recording only.
      expect(speech.cancels, 1);
      expect(speech.listened, hasLength(1));
      notifier().stop();
      expect(speech.stops, 1);
    });

    test('A70 review 2 going to the background cancels; late results are '
        'dropped and listening again takes a tap', () async {
      setUpWith();
      speech.lateEvents = true;
      await notifier().start();
      speech.hear('two');
      await pumpEventQueue();
      notifier().suspend();
      expect(state().phase, VoicePhase.failed);
      expect(state().problem, VoiceProblem.interrupted);
      expect(speech.cancels, 1);
      speech
        ..hear('two eggs')
        ..end();
      await pumpEventQueue();
      expect(state().problem, VoiceProblem.interrupted);
      expect(speech.listened, hasLength(1));
      notifier().retry();
      await pumpEventQueue();
      expect(state().phase, VoicePhase.listening);
      expect(speech.listened, hasLength(2));
    });

    test('A70 review 6 two quick switches end in one recording in the last '
        'language', () async {
      setUpWith();
      await notifier().start();
      final slowCancel = Completer<void>();
      speech.cancelAnswer = slowCancel.future;
      final first = notifier().switchLanguage(VoiceLanguage.english);
      await pumpEventQueue();
      final second = notifier().switchLanguage(VoiceLanguage.arabic);
      await pumpEventQueue();
      expect(speech.listened, [VoiceLanguage.arabic]);
      slowCancel.complete();
      await Future.wait([first, second]);
      await pumpEventQueue();
      expect(speech.listened, [VoiceLanguage.arabic, VoiceLanguage.arabic]);
      expect(state().language, VoiceLanguage.arabic);
      expect(state().phase, VoicePhase.listening);
    });

    test('A70 fix-check 1 Done while a switch waits for its cancel never '
        'starts the mic', () async {
      setUpWith();
      await notifier().start();
      speech.hear('two eggs');
      await pumpEventQueue();
      final slowCancel = Completer<void>();
      speech.cancelAnswer = slowCancel.future;
      final switching = notifier().switchLanguage(VoiceLanguage.english);
      await pumpEventQueue();
      notifier().stop();
      slowCancel.complete();
      await switching;
      await pumpEventQueue();
      expect(speech.listened, [VoiceLanguage.arabic]);
      expect(state().phase, VoicePhase.failed);
      expect(state().problem, VoiceProblem.noSpeech);
    });
  });
}
