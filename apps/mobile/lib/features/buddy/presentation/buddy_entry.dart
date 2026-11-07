import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/presentation/buddy_sheet.dart';
import 'package:material_ui/material_ui.dart';

/// How Buddy opens (A70 D8, D-101).
enum BuddyEntryMode {
  /// The chat sheet with the message box focused (the keyboard).
  keyboard,

  /// The chat sheet with the listening panel open at once (voice input,
  /// AI-014); its words land in the message box, never sent by themselves.
  voice,
}

/// The one way into Buddy (A70 D8): Today's input bar, a notification's
/// `TodayRoute(open: TodayOpen.buddy)`, and the home-screen widgets (A71,
/// through `TodayRoute(open: TodayOpen.buddyVoice)` or directly).
abstract final class BuddyEntry {
  /// Opens Buddy's sheet over the current screen in [mode]; food search in
  /// it opens on [date]. With [revealPending] the thread opens at the
  /// oldest card still waiting (D-094). Resolves when the sheet closes.
  static Future<void> open(
    BuildContext context, {
    required LocalDate date,
    BuddyEntryMode mode = BuddyEntryMode.keyboard,
    bool revealPending = false,
  }) => showBuddySheet(
    context,
    date: date,
    revealPending: revealPending,
    listen: mode == BuddyEntryMode.voice,
  );

  /// [open] with the keyboard.
  static Future<void> keyboard(
    BuildContext context, {
    required LocalDate date,
    bool revealPending = false,
  }) => open(context, date: date, revealPending: revealPending);

  /// [open] listening.
  static Future<void> voice(BuildContext context, {required LocalDate date}) =>
      open(context, date: date, mode: BuddyEntryMode.voice);
}
