import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/photos/photo_picker.dart';
import 'package:fb_mobile/core/photos/photo_source_sheet.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/voice_input.dart';
import 'package:fb_mobile/features/buddy/presentation/composer.dart';
import 'package:fb_mobile/features/buddy/presentation/message_list.dart';
import 'package:fb_mobile/features/buddy/presentation/voice_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens Buddy's chat sheet over the current screen (UX-011, A22 D14), on
/// the root navigator so no snackbar covers it. Its search button opens food
/// search for [date].
///
/// The sheet sits above the keyboard and starts at 60% of that space, so the
/// numbers behind stay readable; drag it up for the full thread, down (or
/// tap outside, or back) to close. The thread stays for this app session.
///
/// With [revealPending] (Today's "{n} waiting", D-094) the thread opens
/// scrolled to the oldest card still waiting for an answer. With [listen]
/// (`BuddyEntry.voice`, A70 D8) the listening panel opens at once.
///
/// Only one sheet at a time (A71 fix-check): when one is already open (a
/// widget tap brought the app back to it), that sheet is reused: [listen]
/// opens its listening panel (unless it already listens), otherwise its
/// message box takes the focus; the draft stays. Resolves when it closes.
Future<void> showBuddySheet(
  BuildContext context, {
  required LocalDate date,
  bool revealPending = false,
  bool listen = false,
}) {
  if (_BuddySheetState._open case final open?) {
    if (listen) {
      open.listenAgain();
    } else {
      open.focusComposer();
    }
    return open._closed.future;
  }
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.16),
    builder: (context) =>
        BuddySheet(date: date, revealPending: revealPending, listen: listen),
  );
}

/// Closes the open Buddy sheet when nothing would be lost (an empty message
/// box, not listening, no photo); whether it closed or none was open. A
/// widget's numbers tap uses it to show Today (A71 fix-check).
bool closeBuddySheetIfIdle() {
  final open = _BuddySheetState._open;
  if (open == null) return true;
  if (open._listening ||
      open._photo != null ||
      open._text.text.trim().isNotEmpty) {
    return false;
  }
  Navigator.of(open.context).pop();
  return true;
}

/// The chat sheet's content: the thread and the composer.
class BuddySheet extends ConsumerStatefulWidget {
  /// The sheet; search opens on [date].
  const new({
    required this.date,
    this.revealPending = false,
    this.listen = false,
    super.key,
  });

  /// Whether the listening panel opens at once (A70 D8).
  final bool listen;

  /// The day food search opens on.
  final LocalDate date;

  /// Whether the thread opens at the oldest waiting card.
  final bool revealPending;

  /// The sheet's resting height, as a share of the space above the keyboard.
  static const double restingSize = 0.6;

  @override
  ConsumerState<BuddySheet> createState() => _BuddySheetState();
}

class _BuddySheetState extends ConsumerState<BuddySheet> {
  /// The sheet on screen, if any (one at a time, A71 fix-check).
  static _BuddySheetState? _open;

  final _closed = Completer<void>();
  bool _listening = false;

  final _text = TextEditingController();
  final _focus = FocusNode();
  final _sheet = DraggableScrollableController();

  /// The thread, kept to flush its adjusted cards when the sheet goes away.
  late final BuddyThreadController _thread;

  /// Pausing the app with the sheet open writes the adjusted cards too
  /// (A23 D8).
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _open = this;
    _thread = ref.read(buddyThreadControllerProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onPause: () => unawaited(_thread.flush()),
    );
    // Text handed back while the sheet was closed (a second 503) is there
    // when it opens again (after this frame: taking it changes the thread).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _restore();
      // Leftover picker files of an earlier run go (A69 review), off the
      // startup path.
      unawaited(ref.read(photoPickerProvider).sweepOnce());
      // Opening Buddy tries waiting messages again (A66 D12).
      unawaited(_thread.wake(buddyReplyTexts(context.l10n)));
      if (widget.listen) unawaited(_speak());
    });
    _text.addListener(_onText);
  }

  /// The box's text came from the voice (A70 D7): the hint shows until
  /// it is sent or cleared.
  bool _fromVoice = false;

  void _onText() {
    if (_fromVoice && _text.text.trim().isEmpty) {
      setState(() => _fromVoice = false);
    }
  }

  /// The listening panel; its words go after the typed text, the box keeps
  /// the focus (the keyboard). Never sent by itself (AI-014): the sent text
  /// is the box's, as the user leaves it.
  Future<void> _speak() async {
    _listening = true;
    final String? words;
    try {
      words = await showVoicePanel(context);
    } finally {
      _listening = false;
    }
    if (!mounted) return;
    if (words != null && words.trim().isNotEmpty) {
      final text = appendTranscript(_text.text, words);
      _text.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      setState(() => _fromVoice = true);
    }
    _focus.requestFocus();
  }

  void _restore() {
    final text = ref
        .read(buddyThreadControllerProvider.notifier)
        .takeComposerRestore();
    if (text == null) return;
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Another entry asked for the keyboard: the box takes the focus.
  void focusComposer() {
    if (mounted) _focus.requestFocus();
  }

  /// Another entry asked to listen: the panel opens unless it is open.
  void listenAgain() {
    if (mounted && !_listening) unawaited(_speak());
  }

  @override
  void dispose() {
    if (_open == this) _open = null;
    if (!_closed.isCompleted) _closed.complete();
    // Dismissing the sheet writes every adjusted card (A23 D8).
    unawaited(_thread.flush());
    _lifecycle.dispose();
    _text
      ..removeListener(_onText)
      ..dispose();
    _focus.dispose();
    _sheet.dispose();
    super.dispose();
  }

  /// The meal photo for the next message (memory only, A69 D6).
  String? _photo;

  void _send() {
    final photo = _photo;
    var text = _text.text;
    if (text.trim().isEmpty) {
      if (photo == null) return;
      text = context.l10n.buddyPhotoOnlyMessage;
    }
    _text.clear();
    setState(() {
      _photo = null;
      _fromVoice = false;
    });
    unawaited(
      ref
          .read(buddyThreadControllerProvider.notifier)
          .send(text, buddyReplyTexts(context.l10n), image: photo),
    );
  }

  Future<void> _pickPhoto() async {
    final photo = await pickPhoto(
      context,
      ref,
      title: context.l10n.buddyAddPhoto,
    );
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  /// The sheet is at full height (from its size notifications, so the
  /// handle's label follows drags and animations).
  bool _expanded = false;

  bool _onSize(DraggableScrollableNotification n) {
    final expanded = n.extent > 0.99;
    if (expanded != _expanded) setState(() => _expanded = expanded);
    return false;
  }

  void _toggleSize() {
    if (!_sheet.isAttached) return;
    // Just above the resting size: a sheet that reaches its minimum size
    // closes (shouldCloseOnMinExtent), and shrinking mustn't dismiss it.
    final to = _expanded ? BuddySheet.restingSize + 0.001 : 1.0;
    _sheet.animateTo(
      to,
      duration: MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 1)
          : FbMotion.local,
      curve: Curves.easeOutCubic,
    );
  }

  void _search() {
    final navigator = ref.read(appNavigatorProvider);
    Navigator.of(context).pop();
    navigator.push(FoodSearchRoute(date: widget.date));
  }

  /// A personal-food card's "Review and save" (A67 D8): the prepared form.
  void _reviewFood() {
    final navigator = ref.read(appNavigatorProvider);
    Navigator.of(context).pop();
    navigator.push(const NewFoodFromBuddyRoute());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final sending = ref.watch(
      buddyThreadControllerProvider.select((t) => t.sending),
    );
    // No sending while an account transition switches profiles (A33).
    final accountBusy = ref.watch(accountBusyProvider);
    // After a second 503 the text comes back to the composer (A22 D6).
    ref.listen(buddyThreadControllerProvider.select((t) => t.composerRestore), (
      _,
      restore,
    ) {
      if (restore != null) _restore();
    });
    return Semantics(
      label: l10n.buddySheetLabel,
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: NotificationListener<DraggableScrollableNotification>(
          onNotification: _onSize,
          child: DraggableScrollableSheet(
            controller: _sheet,
            expand: false,
            initialChildSize: BuddySheet.restingSize,
            minChildSize: BuddySheet.restingSize,
            snap: true,
            builder: (context, scroll) => Column(
              children: [
                // A tap (or a screen reader's activate) expands the sheet,
                // or brings it back to its resting height (backlog #141).
                Semantics(
                  button: true,
                  label: _expanded
                      ? l10n.buddySheetCollapse
                      : l10n.buddySheetExpand,
                  excludeSemantics: true,
                  onTap: _toggleSize,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleSize,
                    child: SizedBox(
                      width: 96,
                      height: 48,
                      child: Center(
                        child: SizedBox(
                          width: 32,
                          height: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.outlineVariant,
                              borderRadius: BorderRadius.circular(FbRadius.sm),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: BuddyMessageList(
                    controller: scroll,
                    sheet: _sheet,
                    onSearch: _search,
                    onReviewFood: _reviewFood,
                    revealPending: widget.revealPending,
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    FbSpace.s3,
                    FbSpace.s1,
                    FbSpace.s3,
                    FbSpace.s3,
                  ),
                  child: BuddyComposer(
                    controller: _text,
                    focusNode: _focus,
                    onSend: sending || accountBusy ? null : _send,
                    onSearch: _search,
                    onPhoto: sending || accountBusy
                        ? null
                        : () => unawaited(_pickPhoto()),
                    photoAttached: _photo != null,
                    onRemovePhoto: () => setState(() => _photo = null),
                    // Speaking only fills the box (sending is the user's
                    // tap), so it works while a reply is on its way.
                    onVoice: accountBusy ? null : () => unawaited(_speak()),
                    fromVoice: _fromVoice,
                    autofocus: !widget.listen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
