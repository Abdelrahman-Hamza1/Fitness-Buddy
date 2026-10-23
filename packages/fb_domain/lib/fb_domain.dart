/// Pure Dart domain models, business rules and algorithms for Fitness Buddy.
///
/// No Flutter, no I/O, no `DateTime.now()` or `Random`: time and IDs are
/// injected by the caller. The production sources are in
/// `package:fb_domain/system.dart` and the test fakes in
/// `package:fb_domain/testing.dart`, which this barrel doesn't export.
library;

export 'src/changes/change_op.dart';
export 'src/changes/domain_event.dart';
export 'src/changes/origin.dart';
export 'src/diary/day_layout.dart';
export 'src/diary/diary_entry.dart';
export 'src/diary/diary_events.dart';
export 'src/diary/diary_ops.dart';
export 'src/diary/food_history.dart';
export 'src/diary/food_ref.dart';
export 'src/diary/meal_slot.dart';
export 'src/diary/provenance.dart';
export 'src/diary/slot_assigner.dart';
export 'src/diary/totals.dart';
export 'src/food/food_state.dart';
export 'src/food/portion/default_portion.dart';
export 'src/food/portion/state_sibling.dart';
export 'src/food/portion/unit_options.dart';
export 'src/food/search/food_search_ranker.dart';
export 'src/food/search/fuzzy_index.dart';
export 'src/food/search/name_matcher.dart';
export 'src/food/search/osa_distance.dart';
export 'src/food/search/search_candidate.dart';
export 'src/ids/hlc.dart';
export 'src/ids/uuid_v7.dart';
export 'src/math/rounding.dart';
export 'src/nutrition/calculator.dart';
export 'src/nutrition/nutrients.dart';
export 'src/nutrition/sanity.dart';
export 'src/nutrition/yield.dart';
export 'src/settings/settings_ops.dart';
export 'src/targets/goals.dart';
export 'src/targets/macros.dart';
export 'src/targets/target_calculator.dart';
export 'src/targets/target_profile.dart';
export 'src/targets/target_settings.dart';
export 'src/targets/weekly_budget.dart';
export 'src/time/clock.dart';
export 'src/time/day_pager.dart';
export 'src/time/local_date.dart';
export 'src/time/local_time.dart';
export 'src/time/week_calendar.dart';
export 'src/units/amounts.dart';
export 'src/units/display.dart';
export 'src/units/food_measures.dart';
export 'src/units/units.dart';
