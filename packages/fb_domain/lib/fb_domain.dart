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
export 'src/food/food_state.dart';
export 'src/ids/hlc.dart';
export 'src/ids/uuid_v7.dart';
export 'src/math/rounding.dart';
export 'src/nutrition/calculator.dart';
export 'src/nutrition/nutrients.dart';
export 'src/nutrition/sanity.dart';
export 'src/nutrition/yield.dart';
export 'src/settings/settings_ops.dart';
export 'src/time/clock.dart';
export 'src/time/local_date.dart';
export 'src/time/local_time.dart';
export 'src/time/week_calendar.dart';
export 'src/units/amounts.dart';
export 'src/units/display.dart';
export 'src/units/food_measures.dart';
export 'src/units/units.dart';
