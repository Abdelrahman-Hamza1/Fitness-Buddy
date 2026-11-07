import 'dart:async';

import 'package:fb_mobile/features/buddy/data/speech_recognizer.dart';
import 'package:fb_mobile/features/buddy/data/voice_language_store.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// A [SpeechRecognizer] the test drives (A70 D9): no plugin, no microphone.
final class FakeSpeechRecognizer implements SpeechRecognizer {
  /// A recogniser with the microphone [allowed] already, answering
  /// [prepare] with [readiness].
  new({this.allowed = true, this.readiness = SpeechReadiness.ready});

  /// The microphone is allowed already.
  bool allowed;

  /// What [prepare] answers.
  SpeechReadiness readiness;

  /// The languages listened in, in order.
  final List<VoiceLanguage> listened = [];

  /// Calls to [stop] and [cancel].
  int stops = 0;
  int cancels = 0;

  /// How many times [prepare] ran (the system dialog).
  int prepares = 0;

  /// What [stop] returns; never completing models a platform that doesn't
  /// answer (A70 review 5).
  Future<void> stopAnswer = Future<void>.value();

  /// What [cancel] waits for (a slow platform cancel, review 6).
  Future<void> cancelAnswer = Future<void>.value();

  /// [cancel] leaves the session open, so a late platform result can
  /// still arrive (review 2, 4).
  bool lateEvents = false;

  StreamController<SpeechEvent>? _session;

  @override
  Future<bool> hasPermission() async => allowed;

  @override
  Future<SpeechReadiness> prepare() async {
    prepares++;
    if (readiness == SpeechReadiness.ready) allowed = true;
    return readiness;
  }

  @override
  Stream<SpeechEvent> listen(VoiceLanguage language) {
    unawaited(_session?.close());
    listened.add(language);
    return (_session = StreamController<SpeechEvent>()).stream;
  }

  /// The recogniser hears [words] (cumulative).
  void hear(String words) => _session?.add(SpeechWords(words));

  /// The session ends with its words.
  void end() {
    _session?.add(const SpeechEnded());
    unawaited(_session?.close());
    _session = null;
  }

  /// The session fails.
  void fail(VoiceProblem problem) {
    _session?.add(SpeechFailed(problem));
    unawaited(_session?.close());
    _session = null;
  }

  @override
  Future<void> stop() {
    stops++;
    return stopAnswer;
  }

  @override
  Future<void> cancel() async {
    cancels++;
    if (!lateEvents) {
      unawaited(_session?.close());
      _session = null;
    }
    await cancelAnswer;
  }
}

/// An in-memory voice language store.
final class MemoryVoiceLanguageStore implements VoiceLanguageStore {
  /// Starts with [language].
  new([this.language = VoiceLanguage.english]);

  /// The stored choice.
  VoiceLanguage language;

  @override
  Future<VoiceLanguage> read() async => language;

  @override
  Future<void> write(VoiceLanguage language) async => this.language = language;
}

/// Overrides the recogniser with [speech] and the preference with [store].
List<Override> fakeSpeech(
  FakeSpeechRecognizer speech, [
  MemoryVoiceLanguageStore? store,
]) => [
  speechRecognizerProvider.overrideWithValue(speech),
  voiceLanguageStoreProvider.overrideWithValue(
    store ?? MemoryVoiceLanguageStore(),
  ),
];
