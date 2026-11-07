import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

part 'speech_recognizer.g.dart';

/// The language of one recording (AI-014, D-101): Arabizi isn't spoken, so
/// two choices.
enum VoiceLanguage {
  /// English.
  english('en'),

  /// Arabic.
  arabic('ar');

  new(this.code);

  /// The ISO 639-1 code, also the stored preference.
  final String code;

  /// The language of [code], or null.
  static VoiceLanguage? of(String? code) {
    for (final l in values) {
      if (l.code == code) return l;
    }
    return null;
  }
}

/// Whether the phone can listen (A70 D3).
enum SpeechReadiness {
  /// Ready: the microphone is allowed and a recogniser is there.
  ready,

  /// The microphone permission was refused (now or for good).
  denied,

  /// The phone has no speech recogniser.
  unavailable,
}

/// Why listening stopped without words (A70 D3).
enum VoiceProblem {
  /// The microphone permission is off.
  permission,

  /// The phone has no speech recogniser.
  unavailable,

  /// The recogniser has no pack for this language.
  language,

  /// Nothing was heard.
  noSpeech,

  /// Anything else (busy, network, a platform error).
  failed,

  /// The app went to the background while listening (A70 review 2): the
  /// recording was cancelled; listening again takes a tap.
  interrupted,
}

/// What a listening session reports. Holds the user's words: never logged.
sealed class SpeechEvent {
  const new _();
}

/// The words so far (cumulative for the session); [isFinal] for the
/// recogniser's last result.
final class SpeechWords extends SpeechEvent {
  /// The words.
  const new(this.text, {this.isFinal = false}) : super._();

  /// The transcript so far.
  final String text;

  /// The recogniser's final result.
  final bool isFinal;

  @override
  String toString() => 'SpeechWords(final: $isFinal)';
}

/// The input level, 0 (silence) to 1.
final class SpeechLevel extends SpeechEvent {
  /// The level.
  const new(this.level) : super._();

  /// 0–1.
  final double level;
}

/// The session ended (a pause, Stop, or the time cap); the last
/// [SpeechWords] are the transcript.
final class SpeechEnded extends SpeechEvent {
  /// Ended.
  const new() : super._();
}

/// The session failed before any words.
final class SpeechFailed extends SpeechEvent {
  /// Failed with [problem].
  const new(this.problem) : super._();

  /// Why.
  final VoiceProblem problem;

  @override
  String toString() => 'SpeechFailed($problem)';
}

/// The phone's speech recognition (A70 D3). On Android the platform
/// `SpeechRecognizer`, asked for on-device recognition: the app records
/// nothing, stores nothing and sends no audio anywhere; the words are
/// handed to the caller only and never logged.
abstract interface class SpeechRecognizer {
  /// Whether the microphone is allowed already (no dialog).
  Future<bool> hasPermission();

  /// Asks for the microphone (the system dialog, first time only) and
  /// checks that a recogniser is there.
  Future<SpeechReadiness> prepare();

  /// Starts a session in [language]; a new call ends the previous one. The
  /// stream closes after [SpeechEnded] or [SpeechFailed].
  Stream<SpeechEvent> listen(VoiceLanguage language);

  /// Stops listening; the session ends with its words, within
  /// [PlatformSpeechRecognizer.stopGrace] of this call. Nothing in the
  /// session listens again after it.
  Future<void> stop();

  /// Stops listening and drops the session.
  Future<void> cancel();
}

/// The locale id to listen in for [language] (A70 D4), from the
/// recogniser's [available] ids (`en_US` or `en-US`): the phone's own
/// [system] locale when it is that language, else the first of a
/// preference list, else any of that language, else a plain default.
String pickSpeechLocale(
  Iterable<String> available,
  VoiceLanguage language, {
  String? system,
}) {
  String norm(String id) => id.replaceAll('-', '_').toLowerCase();
  bool ofLanguage(String id) => norm(id).split('_').first == language.code;
  final ids = available.toList();
  if (system != null && ofLanguage(system)) {
    for (final id in ids) {
      if (norm(id) == norm(system)) return id;
    }
  }
  final preferred = switch (language) {
    VoiceLanguage.english => const ['en_us', 'en_gb'],
    VoiceLanguage.arabic => const ['ar_sa', 'ar_jo', 'ar_eg', 'ar_ae'],
  };
  for (final p in preferred) {
    for (final id in ids) {
      if (norm(id) == p) return id;
    }
  }
  for (final id in ids) {
    if (ofLanguage(id)) return id;
  }
  return switch (language) {
    VoiceLanguage.english => 'en_US',
    VoiceLanguage.arabic => 'ar_SA',
  };
}

/// Whether the recogniser's [available] locale ids can take [language]
/// (A70 review 1): an empty list says nothing (listen and let the
/// recogniser answer); a list without that language means it isn't there.
bool speechLanguageListed(Iterable<String> available, VoiceLanguage language) {
  if (available.isEmpty) return true;
  return available.any(
    (id) =>
        id.replaceAll('-', '_').toLowerCase().split('_').first == language.code,
  );
}

/// [SpeechRecognizer] over the `speech_to_text` plugin (A70 D1, D3): the
/// only file that imports it.
///
/// Always asks for on-device recognition (`onDevice: true`) and never
/// retries off-device (A70 review 1). On Android 13+ with an on-device
/// service, the recogniser's locale list is that service's languages, so a
/// language missing there fails before listening. Residual (in the card):
/// on a phone without an on-device service the plugin falls back to the
/// phone's standard recogniser, and `EXTRA_PREFER_OFFLINE` is a preference
/// Android doesn't guarantee, so the phone's speech service may use its
/// own online service; the app itself keeps no recording and sends nothing.
final class PlatformSpeechRecognizer implements SpeechRecognizer {
  /// Over the plugin's single instance, or [engine] (tests).
  new({SpeechToText? engine}) : _stt = engine ?? SpeechToText();

  /// How long Stop waits for the recogniser's final result, counted from
  /// the Stop tap (A70 review 5); then the session ends with its words and
  /// the recogniser is cancelled.
  static const stopGrace = Duration(seconds: 3);

  /// How long the locale list may take (the plugin can leave it unanswered).
  static const localesTimeout = Duration(seconds: 2);

  final SpeechToText _stt;

  StreamController<SpeechEvent>? _session;

  /// Stop was asked in this session: nothing may start listening again.
  bool _stopping = false;

  /// The Stop deadline of this session.
  Timer? _deadline;

  /// Words came in this session.
  bool _heard = false;

  /// The ids the recogniser offers, read once after [prepare].
  List<String>? _locales;
  String? _system;

  @override
  Future<bool> hasPermission() async {
    try {
      return await _stt.hasPermission;
      // A platform error says nothing the user needs; never logged.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return false;
    }
  }

  @override
  Future<SpeechReadiness> prepare() async {
    try {
      final ok = await _stt.initialize(
        onError: _onError,
        onStatus: _onStatus,
        options: [SpeechToText.androidNoBluetooth],
      );
      if (ok) return SpeechReadiness.ready;
      return await hasPermission()
          ? SpeechReadiness.unavailable
          : SpeechReadiness.denied;
      // No recogniser (PlatformException recognizerNotAvailable) or anything
      // else: the message isn't shown or logged.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return SpeechReadiness.unavailable;
    }
  }

  @override
  Stream<SpeechEvent> listen(VoiceLanguage language) {
    _close();
    final session = StreamController<SpeechEvent>();
    _session = session;
    _stopping = false;
    _heard = false;
    unawaited(_start(session, language));
    return session.stream;
  }

  bool _live(StreamController<SpeechEvent> session) =>
      _session == session && !_stopping && !session.isClosed;

  Future<void> _start(
    StreamController<SpeechEvent> session,
    VoiceLanguage language,
  ) async {
    try {
      await _readLocales();
      if (!_live(session)) return;
      if (!speechLanguageListed(_locales!, language)) {
        _fail(session, VoiceProblem.language);
        return;
      }
      await _stt.listen(
        onResult: _onResult,
        onSoundLevelChange: _onLevel,
        listenOptions: SpeechListenOptions(
          onDevice: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 60),
          localeId: pickSpeechLocale(_locales!, language, system: _system),
        ),
      );
      // Cancelled or replaced while the platform was starting: stop it.
      if (_session != session) unawaited(_safely(_stt.cancel));
      // Not initialized, or the platform refused: never logged.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      _fail(session, VoiceProblem.failed);
    }
  }

  Future<void> _readLocales() async {
    if (_locales != null) return;
    try {
      final locales = await _stt.locales().timeout(localesTimeout);
      _locales = [for (final l in locales) l.localeId];
      _system = (await _stt.systemLocale().timeout(localesTimeout))?.localeId;
      // No list (a platform error, or no answer in time): the recogniser
      // answers instead; never logged.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      _locales ??= const [];
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    final session = _session;
    if (session == null || session.isClosed) return;
    final words = result.recognizedWords;
    if (words.trim().isNotEmpty) _heard = true;
    session.add(SpeechWords(words, isFinal: result.finalResult));
    if (result.finalResult) _end(session);
  }

  void _onLevel(double rmsDb) {
    final session = _session;
    if (session == null || session.isClosed || _stopping) return;
    // Android reports about −2 (silence) to 10 dB.
    session.add(SpeechLevel(((rmsDb + 2) / 12).clamp(0.0, 1.0)));
  }

  void _onStatus(String status) {
    final session = _session;
    if (session == null) return;
    if (status == SpeechToText.doneStatus || status == 'doneNoResult') {
      _end(session);
    }
  }

  void _onError(SpeechRecognitionError error) {
    final session = _session;
    if (session == null) return;
    if (_heard) {
      _end(session);
      return;
    }
    _fail(session, switch (error.errorMsg) {
      'error_permission' => VoiceProblem.permission,
      'error_language_unavailable' ||
      'error_language_not_supported' => VoiceProblem.language,
      'error_no_match' || 'error_speech_timeout' => VoiceProblem.noSpeech,
      _ => VoiceProblem.failed,
    });
  }

  void _end(StreamController<SpeechEvent> session) {
    if (session.isClosed) return;
    session.add(const SpeechEnded());
    _finish(session);
  }

  void _fail(StreamController<SpeechEvent> session, VoiceProblem problem) {
    if (session.isClosed) return;
    session.add(SpeechFailed(problem));
    _finish(session);
  }

  void _finish(StreamController<SpeechEvent> session) {
    unawaited(session.close());
    if (_session == session) {
      _session = null;
      _deadline?.cancel();
      _deadline = null;
    }
  }

  void _close() {
    _deadline?.cancel();
    _deadline = null;
    final old = _session;
    _session = null;
    if (old != null && !old.isClosed) unawaited(old.close());
  }

  @override
  Future<void> stop() async {
    final session = _session;
    if (session == null || _stopping) return;
    _stopping = true;
    // Counted from now, not from the platform's answer (review 5).
    _deadline = Timer(stopGrace, () {
      if (session.isClosed) return;
      _end(session);
      unawaited(_safely(_stt.cancel));
    });
    await _safely(_stt.stop);
  }

  @override
  Future<void> cancel() async {
    _close();
    await _safely(_stt.cancel);
  }

  static Future<void> _safely(Future<void> Function() call) async {
    try {
      await call();
      // A platform error changes nothing for the user; never logged.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  @override
  String toString() => 'PlatformSpeechRecognizer';
}

/// The phone's speech recogniser; tests override it with a fake.
@Riverpod(keepAlive: true)
SpeechRecognizer speechRecognizer(Ref ref) => PlatformSpeechRecognizer();
