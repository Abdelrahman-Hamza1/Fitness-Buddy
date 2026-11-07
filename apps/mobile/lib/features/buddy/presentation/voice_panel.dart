import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/buddy/application/voice_input.dart';
import 'package:fb_mobile/features/buddy/presentation/message_direction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the listening panel over Buddy's sheet (AI-014, A70 D6). Resolves
/// with the spoken words, or null (Cancel, Type instead, a problem, closed).
/// The words are only handed back: nothing is sent from here.
Future<String?> showVoicePanel(BuildContext context) =>
    showFbStatefulSheet(context, builder: (_) => const VoicePanel());

/// The listening panel: language switch, live words, level bars, Cancel and
/// Done; a plain explanation before the first microphone request, a plain
/// message when it can't listen.
class VoicePanel extends ConsumerStatefulWidget {
  /// The panel.
  const new({super.key});

  @override
  ConsumerState<VoicePanel> createState() => _VoicePanelState();
}

class _VoicePanelState extends ConsumerState<VoicePanel> {
  VoiceInputController get _voice =>
      ref.read(voiceInputControllerProvider.notifier);

  /// Going to the background cancels a recording (A70 review 2). Only
  /// hidden counts: the permission dialog makes the app inactive, not
  /// hidden.
  late final AppLifecycleListener _lifecycle;

  /// The panel is closing (Back, a tap outside, a drag, or a button): a
  /// late result is dropped, never popping the Buddy sheet (review 4).
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: () => _voice.suspend());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_voice.start());
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Pops this panel with [words], once, and only while it is the top
  /// route.
  void _close([String? words]) {
    if (_closing || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    _closing = true;
    Navigator.of(context).pop(words);
  }

  /// Any way the panel closes: the recording is cancelled at once.
  void _onPop(bool didPop, Object? _) {
    if (!didPop) return;
    _closing = true;
    unawaited(_voice.cancel());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceInputControllerProvider);
    ref.listen(voiceInputControllerProvider, (_, next) {
      if (next.phase == VoicePhase.done) _close(next.words);
    });
    final live =
        state.phase == VoicePhase.starting ||
        state.phase == VoicePhase.listening ||
        state.phase == VoicePhase.finishing;
    return PopScope<Object?>(
      onPopInvokedWithResult: _onPop,
      child: _sheet(context, state, live),
    );
  }

  Widget _sheet(BuildContext context, VoiceState state, bool live) {
    final l10n = context.l10n;
    return FbSheet(
      title: switch (state.phase) {
        VoicePhase.listening => l10n.buddyVoiceListening,
        VoicePhase.finishing => l10n.buddyVoiceFinishing,
        _ => l10n.buddyVoiceTitle,
      },
      actions: _actions(context, state),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: l10n.buddyVoiceLanguage,
            container: true,
            child: FbSegmented<VoiceLanguage>(
              key: const ValueKey('voice-language'),
              options: [
                FbOption(
                  value: VoiceLanguage.english,
                  label: l10n.buddyVoiceEnglish,
                ),
                FbOption(
                  value: VoiceLanguage.arabic,
                  label: l10n.buddyVoiceArabic,
                ),
              ],
              selected: state.language,
              enabled: state.phase != VoicePhase.finishing,
              onSelected: (l) => unawaited(_voice.switchLanguage(l)),
            ),
          ),
          const SizedBox(height: FbSpace.s4),
          if (live) ...[
            _Words(words: state.words),
            const SizedBox(height: FbSpace.s3),
            _LevelBars(
              level: state.level,
              on: state.phase == VoicePhase.listening,
            ),
          ] else
            _Message(
              text: switch (state.phase) {
                VoicePhase.asking => l10n.buddyVoiceAsk,
                _ => switch (state.problem) {
                  VoiceProblem.permission => l10n.buddyVoicePermissionOff,
                  VoiceProblem.unavailable => l10n.buddyVoiceUnavailable,
                  VoiceProblem.language => l10n.buddyVoiceLanguageMissing,
                  VoiceProblem.noSpeech => l10n.buddyVoiceNoSpeech,
                  VoiceProblem.interrupted => l10n.buddyVoiceInterrupted,
                  VoiceProblem.failed || null => l10n.buddyVoiceFailed,
                },
              },
            ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, VoiceState state) {
    final l10n = context.l10n;
    final (start, end) = switch (state.phase) {
      VoicePhase.asking => (
        FbButton.text(label: l10n.buddyVoiceTypeInstead, onPressed: _close),
        FbButton.primary(
          key: const ValueKey('voice-allow'),
          label: l10n.buddyVoiceAllow,
          icon: FbIcons.mic,
          onPressed: () => unawaited(_voice.allow()),
        ),
      ),
      VoicePhase.failed => (
        FbButton.text(
          key: const ValueKey('voice-type'),
          label: l10n.buddyVoiceTypeInstead,
          onPressed: _close,
        ),
        switch (state.problem) {
          VoiceProblem.permission || VoiceProblem.unavailable => null,
          _ => FbButton.primary(
            label: l10n.buddyVoiceTryAgain,
            icon: FbIcons.mic,
            onPressed: _voice.retry,
          ),
        },
      ),
      _ => (
        FbButton.text(
          key: const ValueKey('voice-cancel'),
          label: l10n.buddyVoiceCancel,
          onPressed: _close,
        ),
        FbButton.primary(
          key: const ValueKey('voice-done'),
          label: l10n.buddyVoiceDone,
          icon: FbIcons.mic,
          busy: state.phase == VoicePhase.finishing,
          onPressed: state.phase == VoicePhase.listening ? _voice.stop : null,
        ),
      ),
    };
    return Row(
      spacing: FbSpace.s3,
      children: [
        Expanded(child: start),
        Expanded(child: end ?? const SizedBox.shrink()),
      ],
    );
  }
}

/// The live words in a box that always holds three lines at the current
/// text scale, so the panel never changes height while words come in; the
/// newest words stay in view.
class _Words extends StatelessWidget {
  const new({required this.words});

  final String words;

  static const _lines = 3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const style = FbType.body;
    final empty = words.trim().isEmpty;
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(style.fontSize ?? 16) *
        (style.height ?? 1.4);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: FbRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(FbSpace.s3),
        child: SizedBox(
          height: lineHeight * _lines,
          child: SingleChildScrollView(
            reverse: true,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                empty ? context.l10n.buddyVoicePlaceholder : words,
                key: const ValueKey('voice-words'),
                textDirection: empty ? null : messageDirection(words),
                style: style.copyWith(
                  color: empty ? scheme.onSurfaceVariant : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Five bars that follow the input level (decoration: hidden from screen
/// readers; still under reduced motion).
class _LevelBars extends StatelessWidget {
  const new({required this.level, required this.on});

  final double level;
  final bool on;

  static const _weights = [0.45, 0.75, 1.0, 0.75, 0.45];
  static const _height = 32.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colour = on ? scheme.primary : scheme.outlineVariant;
    final duration = FbMotion.of(context, FbMotion.fast);
    return ExcludeSemantics(
      child: SizedBox(
        height: _height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: FbSpace.s1,
          children: [
            for (final w in _weights)
              AnimatedContainer(
                duration: duration,
                curve: FbMotion.curve,
                width: 6,
                height: 6 + (_height - 6) * (on ? level : 0) * w,
                decoration: BoxDecoration(
                  color: colour,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        key: const ValueKey('voice-message'),
        style: FbType.body.copyWith(color: scheme.onSurface),
      ),
    );
  }
}
