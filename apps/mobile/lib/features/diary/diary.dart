/// The diary feature. Other features and `app/` import only this barrel
/// (`03-architecture.md` §3.2).
library;

export 'application/day_rows.dart';
export 'application/day_view.dart';
export 'application/diary_actions.dart';
export 'application/diary_providers.dart';
export 'application/diary_view_state.dart';
export 'application/saved_meal_actions.dart';
export 'application/saved_meals.dart';
export 'data/diary_op_handler.dart' show DiaryOpHandler;
export 'data/diary_reads.dart' show DiaryReads;
export 'data/diary_repository.dart';
export 'presentation/copy_meal_sheet.dart';
export 'presentation/entry_amount_sheet.dart';
export 'presentation/entry_details.dart';
export 'presentation/entry_row.dart';
export 'presentation/group_rows.dart';
export 'presentation/live_entry.dart';
export 'presentation/live_meal.dart';
export 'presentation/meal_menu.dart';
export 'presentation/move_entry_sheet.dart';
export 'presentation/move_to_slot_sheet.dart';
export 'presentation/nutrient_override_sheet.dart';
export 'presentation/save_meal_sheet.dart';
export 'presentation/saved_meals/saved_meal_screen.dart';
export 'presentation/saved_meals/saved_meals_screen.dart';
export 'presentation/slot_header_row.dart';
