// The allow comments must stay on the line they excuse.
// ignore_for_file: lines_longer_than_80_chars

import 'package:material_ui/material_ui.dart';

/// The only place icons are named (A02 D2). Rounded Material icons, from the
/// font `material_ui` already ships. Screens never use `Icons.*` directly.
///
/// Icons that point somewhere (`previous`, `next`) mirror in right-to-left
/// layouts.
abstract final class FbIcons {
  /// Points to the earlier thing (a chevron that mirrors in RTL).
  static const IconData previous = Icons.chevron_left_rounded; // app-check: allow directional matchTextDirection mirrors it in RTL

  /// Points to the later thing.
  static const IconData next = Icons.chevron_right_rounded; // app-check: allow directional matchTextDirection mirrors it in RTL

  /// Expand a collapsed row; rotated half a turn when it is open.
  static const IconData expand = Icons.expand_more_rounded;

  /// Delete (swipe action).
  static const IconData delete = Icons.delete_outline_rounded;

  /// Move to another place (swipe action). Vertical, so it needs no mirroring.
  static const IconData move = Icons.swap_vert_rounded;

  /// The grip of a row that can be dragged to reorder a list.
  static const IconData dragHandle = Icons.drag_handle_rounded;

  /// Add (quick-add chips, add buttons).
  static const IconData add = Icons.add_rounded;

  /// A saved meal (the quick-add chip of a saved meal, the saved meals list).
  static const IconData meal = Icons.restaurant_rounded;

  /// Edit an amount or value.
  static const IconData edit = Icons.edit_rounded;

  /// Remove / clear.
  static const IconData close = Icons.close_rounded;

  /// Confirm.
  static const IconData check = Icons.check_rounded;

  /// Backspace on the number pad.
  static const IconData backspace = Icons.backspace_outlined;

  /// Camera (photo input).
  static const IconData camera = Icons.photo_camera_outlined;

  /// Send a message. Points to the end (mirrors in RTL).
  static const IconData send = Icons.send_rounded; // app-check: allow directional matchTextDirection mirrors it in RTL

  /// Search (the magnifier).
  static const IconData search = Icons.search_rounded;

  /// Barcode scan.
  static const IconData barcode = Icons.qr_code_scanner_rounded;

  /// More options.
  static const IconData more = Icons.more_horiz_rounded;

  /// Information.
  static const IconData info = Icons.info_outline_rounded;

  /// Offline / no connection.
  static const IconData offline = Icons.cloud_off_rounded;

  /// Waiting to sync.
  static const IconData pending = Icons.schedule_rounded;

  /// A problem the user can fix.
  static const IconData error = Icons.error_outline_rounded;

  /// Calendar / date.
  static const IconData calendar = Icons.calendar_today_rounded;

  /// Chart placeholder.
  static const IconData chart = Icons.show_chart_rounded;

  /// Empty state: nothing here yet.
  static const IconData empty = Icons.inbox_outlined;

  /// Today tab.
  static const IconData today = Icons.today_rounded;

  /// Diary tab.
  static const IconData diary = Icons.menu_book_rounded;

  /// Progress tab.
  static const IconData progress = Icons.insights_rounded;

  /// Me tab.
  static const IconData me = Icons.person_outline_rounded;

  /// Today tab, not selected.
  static const IconData navToday = Icons.today_outlined;

  /// Today tab, selected.
  static const IconData navTodaySelected = Icons.today_rounded;

  /// Progress tab, not selected.
  static const IconData navProgress = Icons.insights_outlined;

  /// Progress tab, selected.
  static const IconData navProgressSelected = Icons.insights_rounded;

  /// Workouts tab, not selected.
  static const IconData navWorkouts = Icons.fitness_center_outlined;

  /// Workouts tab, selected.
  static const IconData navWorkoutsSelected = Icons.fitness_center_rounded;

  /// Me tab, not selected.
  static const IconData navMe = Icons.person_outline_rounded;

  /// Me tab, selected.
  static const IconData navMeSelected = Icons.person_rounded;
}
