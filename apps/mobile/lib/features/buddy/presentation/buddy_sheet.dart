import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/presentation/composer.dart';
import 'package:fb_mobile/features/buddy/presentation/message_list.dart';
import 'package:fb_mobile/features/diary/diary.dart';
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
          : FbMotion.normal,
      curve: Curves.easeOutCubic,
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
                  ),
                ),
                const _FollowUpChip(),
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
      ),
    );
  }
}

/// "Updating {slot} card ✕" above the composer while a card is open
/// (AI-044, UX-023, D21): the next message updates that card; ✕ makes it a
/// new message.
class _FollowUpChip extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(
      buddyThreadControllerProvider.select(
        (t) => switch (t.followUpCard) {
          final c? => (c.id, c.card.lines.firstOrNull?.entry.slotId),
          null => null,
        },
      ),
    );
    if (target == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final slots = ref.watch(slotRecordsProvider).value ?? const [];
    final slot = slots
        .map((r) => r.slot)
        .where((s) => s.id == target.$2)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: FbSpace.s3,
        end: FbSpace.s3,
        top: FbSpace.s1,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FbTargetChip(
          label: slot == null
              ? l10n.buddyFollowUpTargetNoSlot
              : l10n.buddyFollowUpTarget(slotLabel(l10n, slot)),
          clearTooltip: l10n.buddyFollowUpClear,
          onClear: () =>
              ref.read(buddyThreadControllerProvider.notifier).clearFollowUp(),
        ),
      ),
    );
  }
}
