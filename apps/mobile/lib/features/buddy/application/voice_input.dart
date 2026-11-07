import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/data/speech_recognizer.dart';
import 'package:fb_mobile/features/buddy/data/voice_language_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:fb_mobile/features/buddy/data/speech_recognizer.dart'
    show VoiceLanguage, VoiceProblem;

part 'voice_input.g.dart';

/// Where the listening panel is (A70 D5).
enum VoicePhase {
  /// Checking the microphone and the recogniser.
  starting,

  /// The microphone isn't allowed yet: the plain explanation first.
  asking,

  /// Listening; the words come in live.
  listening,

  /// Stopped by the user; waiting for the final words.
  finishing,

  /// Done: [VoiceState.words] go to the message box.
  done,

  /// Stopped without words ([VoiceState.problem]).
  failed,
}

/// The listening panel's state. Holds the user's words: never logged.
final class VoiceState {
  /// A state.
  const new({
    required this.phase,
    required this.language,
    this.words = '',
    this.level = 0,
    this.problem,
  });

  /// Where the panel is.
  final VoicePhase phase;

  /// The language of this recording.
  final VoiceLanguage language;

  /// The words so far (the transcript when [phase] is done).
  final String words;

  /// The input level, 0–1.
  final double level;

  /// Why it [VoicePhase.failed].
  final VoiceProblem? problem;

  /// A copy with the given fields.
  VoiceState copyWith({
    VoicePhase? phase,
    VoiceLanguage? language,
    String? words,
    double? level,
  }) => VoiceState(
    phase: phase ?? this.phase,
    language: language ?? this.language,
    words: words ?? this.words,
    level: level ?? this.level,
    problem: problem,
  );

  @override
  String toString() => 'VoiceState($phase, $language, $problem)';
}

/// [current] with the spoken [words] after it (A70 D7): one space between
/// unless [current] is empty or ends in whitespace, capped at [limit]
/// UTF-16 units without splitting a surrogate pair.
String appendTranscript(
  String current,
  String words, {
  int limit = ChatText.composerLimit,
}) {
  final add = words.trim();
  if (add.isEmpty) return current;
  final gap = current.isEmpty || RegExp(r'\s$').hasMatch(current) ? '' : ' ';
  final out = '$current$gap$add';
  if (out.length <= limit) return out;
  var cut = limit;
  final last = out.codeUnitAt(cut - 1);
  if (last >= 0xD800 && last <= 0xDBFF) cut--;
  return out.substring(0, cut);
}

/// The listening panel's view model (A70 D5): asks for the microphone,
/// runs one recording at a time on the phone's recogniser and ends with
/// the words. It never sends anything: the words go to the message box.
///
/// Every transition bumps one operation number, checked after each await
/// and on each event (A70 review 2, 3, 6): a cancelled, suspended, stopped
/// or replaced recording can't start, finish or listen again. A new
/// recording waits for the previous cancel to reach the recogniser.
@riverpod
class VoiceInputController extends _$VoiceInputController {
  /// How long Done waits for the final words, from the tap (review 5); a
  /// backstop over the recogniser's own deadline.
  static const stopDeadline = Duration(milliseconds: 3500);

  StreamSubscription<SpeechEvent>? _events;
  Timer? _deadline;

  /// The current operation; anything started under an older one is void.
  int _op = 0;

  /// The recogniser has a session of ours that may still be listening.
  bool _active = false;

  /// The last cancel sent to the recogniser.
  Future<void> _cancelling = Future<void>.value();

  late SpeechRecognizer _recognizer;

  @override
  VoiceState build() {
    _recognizer = ref.watch(speechRecognizerProvider);
    ref.onDispose(() {
      _op++;
      unawaited(_release());
    });
    return const VoiceState(
      phase: VoicePhase.starting,
      language: VoiceLanguage.english,
    );
  }

  bool _current(int op) => op == _op && ref.mounted;

  /// Ends our session at the recogniser (if any) and stops its events.
  Future<void> _release() {
    unawaited(_events?.cancel());
    _events = null;
    _deadline?.cancel();
    _deadline = null;
    if (_active) {
      _active = false;
      _cancelling = _recognizer.cancel();
    }
    return _cancelling;
  }

  /// Opens with the last language; asks first when the microphone isn't
  /// allowed yet, else listens at once.
  Future<void> start() async {
    final op = ++_op;
    final language = await ref.read(voiceLanguageStoreProvider).read();
    if (!_current(op)) return;
    state = state.copyWith(language: language);
    final allowed = await _recognizer.hasPermission();
    if (!_current(op)) return;
    if (!allowed) {
      state = state.copyWith(phase: VoicePhase.asking);
      return;
    }
    await allow();
  }

  /// Asks for the microphone (the system dialog) and listens.
  Future<void> allow() async {
    final op = ++_op;
    state = state.copyWith(phase: VoicePhase.starting);
    final readiness = await _recognizer.prepare();
    if (!_current(op)) return;
    switch (readiness) {
      case SpeechReadiness.ready:
        await _listen();
      case SpeechReadiness.denied:
        _fail(VoiceProblem.permission);
      case SpeechReadiness.unavailable:
        _fail(VoiceProblem.unavailable);
    }
  }

  Future<void> _listen() async {
    final op = ++_op;
    state = VoiceState(phase: VoicePhase.listening, language: state.language);
    await _release();
    // Stopped, cancelled or replaced while the previous cancel was on its
    // way (fix-check 1): nothing starts.
    if (!_current(op) || state.phase != VoicePhase.listening) return;
    _active = true;
    _events = _recognizer.listen(state.language).listen((event) {
      if (!_current(op)) return;
      switch (event) {
        case SpeechWords(:final text):
          state = state.copyWith(words: text);
        case SpeechLevel(:final level):
          if (state.phase == VoicePhase.listening) {
            state = state.copyWith(level: level);
          }
        case SpeechEnded():
          _active = false;
          _finish();
        case SpeechFailed(:final problem):
          _active = false;
          _op++;
          unawaited(_release());
          _fail(problem);
      }
    });
  }

  /// The recording is over: its words, or "nothing heard".
  void _finish() {
    _op++;
    final words = state.words.trim();
    unawaited(_release());
    if (words.isEmpty) {
      _fail(VoiceProblem.noSpeech);
    } else {
      state = state.copyWith(phase: VoicePhase.done, words: words, level: 0);
    }
  }

  void _fail(VoiceProblem problem) {
    state = VoiceState(
      phase: VoicePhase.failed,
      language: state.language,
      problem: problem,
    );
  }

  /// Stops listening; the words so far (and the recogniser's final ones)
  /// end the recording, at the latest [stopDeadline] after this call.
  /// Nothing listens again after it without a new tap.
  void stop() {
    if (state.phase != VoicePhase.listening) return;
    if (!_active) {
      // Not started at the recogniser yet (a switch's cancel pending):
      // the pending start is void and the recording ends now.
      _finish();
      return;
    }
    final op = _op;
    state = state.copyWith(phase: VoicePhase.finishing, level: 0);
    _deadline = Timer(stopDeadline, () {
      if (_current(op)) _finish();
    });
    // The deadline doesn't wait for the platform's answer.
    unawaited(_recognizer.stop());
  }

  /// Drops the recording (Cancel, the panel dismissed).
  Future<void> cancel() async {
    _op++;
    await _release();
  }

  /// The app went to the background (A70 review 2): a recording, or one
  /// about to start, is cancelled; listening again takes a tap.
  void suspend() {
    switch (state.phase) {
      case VoicePhase.starting || VoicePhase.listening || VoicePhase.finishing:
        _op++;
        unawaited(_release());
        _fail(VoiceProblem.interrupted);
      case _:
        break;
    }
  }

  /// Listens again after a problem.
  void retry() => unawaited(_listen());

  /// Switches the language (kept for next time); a recording under way
  /// starts again in [language]. Not while Done is finishing. Quick
  /// switches end in one recording, in the last language.
  Future<void> switchLanguage(VoiceLanguage language) async {
    if (language == state.language) return;
    final phase = state.phase;
    if (phase == VoicePhase.finishing || phase == VoicePhase.done) return;
    unawaited(ref.read(voiceLanguageStoreProvider).write(language));
    state = state.copyWith(language: language);
    final restart = switch (phase) {
      VoicePhase.listening => true,
      VoicePhase.failed => switch (state.problem) {
        VoiceProblem.language ||
        VoiceProblem.noSpeech ||
        VoiceProblem.failed ||
        VoiceProblem.interrupted => true,
        _ => false,
      },
      _ => false,
    };
    if (restart) await _listen();
  }
}
