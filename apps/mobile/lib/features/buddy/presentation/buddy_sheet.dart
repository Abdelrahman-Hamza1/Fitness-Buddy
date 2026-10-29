import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/presentation/composer.dart';
import 'package:fb_mobile/features/buddy/presentation/message_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens Buddy's chat sheet over the current screen (UX-011, A22 D14), on
/// the root navigator so no snackbar covers it. Its search button opens food
/// search for [date].
///
/// The sheet sits above the keyboard and starts at 60% of that space, so the
/// numbers behind stay readable; drag it up for the full thread, down (or
/// tap outside, or back) to close. The thread stays for this app session.
Future<void> showBuddySheet(BuildContext context, {required LocalDate date}) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.16),
      builder: (context) => BuddySheet(date: date),
    );

/// The chat sheet's content: the thread and the composer.
class BuddySheet extends ConsumerStatefulWidget {
  /// The sheet; search opens on [date].
  const new({required this.date, super.key});

  /// The day food search opens on.
  final LocalDate date;

  /// The sheet's resting height, as a share of the space above the keyboard.
  static const double restingSize = 0.6;

  @override
  ConsumerState<BuddySheet> createState() => _BuddySheetState();
}

class _BuddySheetState extends ConsumerState<BuddySheet> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _sheet = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    // Text handed back while the sheet was closed (a second 503) is there
    // when it opens again (after this frame: taking it changes the thread).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restore();
    });
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

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _sheet.dispose();
    super.dispose();
  }

  void _send() {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    _text.clear();
    unawaited(
      ref
          .read(buddyThreadControllerProvider.notifier)
          .send(text, buddyReplyTexts(context.l10n)),
    );
  }

  void _search() {
    final navigator = ref.read(appNavigatorProvider);
    Navigator.of(context).pop();
    navigator.push(FoodSearchRoute(date: widget.date));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final sending = ref.watch(
      buddyThreadControllerProvider.select((t) => t.sending),
    );
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
        child: DraggableScrollableSheet(
          controller: _sheet,
          expand: false,
          initialChildSize: BuddySheet.restingSize,
          minChildSize: BuddySheet.restingSize,
          snap: true,
          builder: (context, scroll) => Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: FbSpace.s2),
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
              Expanded(
                child: BuddyMessageList(
                  controller: scroll,
                  sheet: _sheet,
                  onSearch: _search,
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
                  onSend: sending ? null : _send,
                  onSearch: _search,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
