// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_weekly_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyWeeklySummary {

 String get start; String get end;/// Days of the week before today (7 for a past week).
 int get elapsedDays;/// Logged, complete days that enter averages (TG-032).
 int get countedDays; int get targetDays;/// Counted days within 10 % of the calorie target.
 int get daysWithinTarget; int get proteinTargetDays; int get proteinDaysHit;/// Average intake over the target days.
 double? get averageKcal;/// Average calorie target over the same days.
 double? get averageTargetKcal; double? get averageFiberG;/// Trend weight change over the week (kg).
 double? get trendChangeKg; BuddyWeeklyWorkouts? get workouts;/// Some counted days include estimates.
 bool get estimated;/// The phone's adaptive check-in proposal (A38), when it proposes a change; the app attaches its own pending targetChange card to the review.
 BuddyWeeklyCheckIn? get checkIn;
/// Create a copy of BuddyWeeklySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyWeeklySummaryCopyWith<BuddyWeeklySummary> get copyWith => _$BuddyWeeklySummaryCopyWithImpl<BuddyWeeklySummary>(this as BuddyWeeklySummary, _$identity);

  /// Serializes this BuddyWeeklySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyWeeklySummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyWeeklySummary&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.elapsedDays, _this.elapsedDays) || other.elapsedDays == _this.elapsedDays)&&(identical(other.countedDays, _this.countedDays) || other.countedDays == _this.countedDays)&&(identical(other.targetDays, _this.targetDays) || other.targetDays == _this.targetDays)&&(identical(other.daysWithinTarget, _this.daysWithinTarget) || other.daysWithinTarget == _this.daysWithinTarget)&&(identical(other.proteinTargetDays, _this.proteinTargetDays) || other.proteinTargetDays == _this.proteinTargetDays)&&(identical(other.proteinDaysHit, _this.proteinDaysHit) || other.proteinDaysHit == _this.proteinDaysHit)&&(identical(other.averageKcal, _this.averageKcal) || other.averageKcal == _this.averageKcal)&&(identical(other.averageTargetKcal, _this.averageTargetKcal) || other.averageTargetKcal == _this.averageTargetKcal)&&(identical(other.averageFiberG, _this.averageFiberG) || other.averageFiberG == _this.averageFiberG)&&(identical(other.trendChangeKg, _this.trendChangeKg) || other.trendChangeKg == _this.trendChangeKg)&&(identical(other.workouts, _this.workouts) || other.workouts == _this.workouts)&&(identical(other.estimated, _this.estimated) || other.estimated == _this.estimated)&&(identical(other.checkIn, _this.checkIn) || other.checkIn == _this.checkIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyWeeklySummary;
  return Object.hash(runtimeType,_this.start,_this.end,_this.elapsedDays,_this.countedDays,_this.targetDays,_this.daysWithinTarget,_this.proteinTargetDays,_this.proteinDaysHit,_this.averageKcal,_this.averageTargetKcal,_this.averageFiberG,_this.trendChangeKg,_this.workouts,_this.estimated,_this.checkIn);
}

@override
String toString() {
  final _this = this as BuddyWeeklySummary;
  return 'BuddyWeeklySummary(start: ${_this.start}, end: ${_this.end}, elapsedDays: ${_this.elapsedDays}, countedDays: ${_this.countedDays}, targetDays: ${_this.targetDays}, daysWithinTarget: ${_this.daysWithinTarget}, proteinTargetDays: ${_this.proteinTargetDays}, proteinDaysHit: ${_this.proteinDaysHit}, averageKcal: ${_this.averageKcal}, averageTargetKcal: ${_this.averageTargetKcal}, averageFiberG: ${_this.averageFiberG}, trendChangeKg: ${_this.trendChangeKg}, workouts: ${_this.workouts}, estimated: ${_this.estimated}, checkIn: ${_this.checkIn})';
}


}

/// @nodoc
abstract mixin class $BuddyWeeklySummaryCopyWith<$Res>  {
  factory $BuddyWeeklySummaryCopyWith(BuddyWeeklySummary value, $Res Function(BuddyWeeklySummary) _then) = _$BuddyWeeklySummaryCopyWithImpl;
@useResult
$Res call({
 String start, String end, int elapsedDays, int countedDays, int targetDays, int daysWithinTarget, int proteinTargetDays, int proteinDaysHit, double? averageKcal, double? averageTargetKcal, double? averageFiberG, double? trendChangeKg, BuddyWeeklyWorkouts? workouts, bool estimated, BuddyWeeklyCheckIn? checkIn
});


$BuddyWeeklyWorkoutsCopyWith<$Res>? get workouts;$BuddyWeeklyCheckInCopyWith<$Res>? get checkIn;

}
/// @nodoc
class _$BuddyWeeklySummaryCopyWithImpl<$Res>
    implements $BuddyWeeklySummaryCopyWith<$Res> {
  _$BuddyWeeklySummaryCopyWithImpl(this._self, this._then);

  final BuddyWeeklySummary _self;
  final $Res Function(BuddyWeeklySummary) _then;

/// Create a copy of BuddyWeeklySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? end = null,Object? elapsedDays = null,Object? countedDays = null,Object? targetDays = null,Object? daysWithinTarget = null,Object? proteinTargetDays = null,Object? proteinDaysHit = null,Object? averageKcal = freezed,Object? averageTargetKcal = freezed,Object? averageFiberG = freezed,Object? trendChangeKg = freezed,Object? workouts = freezed,Object? estimated = null,Object? checkIn = freezed,}) {
  return _then(BuddyWeeklySummary(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,elapsedDays: null == elapsedDays ? _self.elapsedDays : elapsedDays // ignore: cast_nullable_to_non_nullable
as int,countedDays: null == countedDays ? _self.countedDays : countedDays // ignore: cast_nullable_to_non_nullable
as int,targetDays: null == targetDays ? _self.targetDays : targetDays // ignore: cast_nullable_to_non_nullable
as int,daysWithinTarget: null == daysWithinTarget ? _self.daysWithinTarget : daysWithinTarget // ignore: cast_nullable_to_non_nullable
as int,proteinTargetDays: null == proteinTargetDays ? _self.proteinTargetDays : proteinTargetDays // ignore: cast_nullable_to_non_nullable
as int,proteinDaysHit: null == proteinDaysHit ? _self.proteinDaysHit : proteinDaysHit // ignore: cast_nullable_to_non_nullable
as int,averageKcal: freezed == averageKcal ? _self.averageKcal : averageKcal // ignore: cast_nullable_to_non_nullable
as double?,averageTargetKcal: freezed == averageTargetKcal ? _self.averageTargetKcal : averageTargetKcal // ignore: cast_nullable_to_non_nullable
as double?,averageFiberG: freezed == averageFiberG ? _self.averageFiberG : averageFiberG // ignore: cast_nullable_to_non_nullable
as double?,trendChangeKg: freezed == trendChangeKg ? _self.trendChangeKg : trendChangeKg // ignore: cast_nullable_to_non_nullable
as double?,workouts: freezed == workouts ? _self.workouts : workouts // ignore: cast_nullable_to_non_nullable
as BuddyWeeklyWorkouts?,estimated: null == estimated ? _self.estimated : estimated // ignore: cast_nullable_to_non_nullable
as bool,checkIn: freezed == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as BuddyWeeklyCheckIn?,
  ));
}
/// Create a copy of BuddyWeeklySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyWeeklyWorkoutsCopyWith<$Res>? get workouts {
    if (_self.workouts == null) {
    return null;
  }

  return $BuddyWeeklyWorkoutsCopyWith<$Res>(_self.workouts!, (value) {
    return _then(_self.copyWith(workouts: value));
  });
}/// Create a copy of BuddyWeeklySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyWeeklyCheckInCopyWith<$Res>? get checkIn {
    if (_self.checkIn == null) {
    return null;
  }

  return $BuddyWeeklyCheckInCopyWith<$Res>(_self.checkIn!, (value) {
    return _then(_self.copyWith(checkIn: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyWeeklySummary].
extension BuddyWeeklySummaryPatterns on BuddyWeeklySummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyWeeklySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyWeeklySummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyWeeklySummary value)  $default,){
final _that = this;
switch (_that) {
case _BuddyWeeklySummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyWeeklySummary value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyWeeklySummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String start,  String end,  int elapsedDays,  int countedDays,  int targetDays,  int daysWithinTarget,  int proteinTargetDays,  int proteinDaysHit,  double? averageKcal,  double? averageTargetKcal,  double? averageFiberG,  double? trendChangeKg,  BuddyWeeklyWorkouts? workouts,  bool estimated,  BuddyWeeklyCheckIn? checkIn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyWeeklySummary() when $default != null:
return $default(_that.start,_that.end,_that.elapsedDays,_that.countedDays,_that.targetDays,_that.daysWithinTarget,_that.proteinTargetDays,_that.proteinDaysHit,_that.averageKcal,_that.averageTargetKcal,_that.averageFiberG,_that.trendChangeKg,_that.workouts,_that.estimated,_that.checkIn);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String start,  String end,  int elapsedDays,  int countedDays,  int targetDays,  int daysWithinTarget,  int proteinTargetDays,  int proteinDaysHit,  double? averageKcal,  double? averageTargetKcal,  double? averageFiberG,  double? trendChangeKg,  BuddyWeeklyWorkouts? workouts,  bool estimated,  BuddyWeeklyCheckIn? checkIn)  $default,) {final _that = this;
switch (_that) {
case _BuddyWeeklySummary():
return $default(_that.start,_that.end,_that.elapsedDays,_that.countedDays,_that.targetDays,_that.daysWithinTarget,_that.proteinTargetDays,_that.proteinDaysHit,_that.averageKcal,_that.averageTargetKcal,_that.averageFiberG,_that.trendChangeKg,_that.workouts,_that.estimated,_that.checkIn);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String start,  String end,  int elapsedDays,  int countedDays,  int targetDays,  int daysWithinTarget,  int proteinTargetDays,  int proteinDaysHit,  double? averageKcal,  double? averageTargetKcal,  double? averageFiberG,  double? trendChangeKg,  BuddyWeeklyWorkouts? workouts,  bool estimated,  BuddyWeeklyCheckIn? checkIn)?  $default,) {final _that = this;
switch (_that) {
case _BuddyWeeklySummary() when $default != null:
return $default(_that.start,_that.end,_that.elapsedDays,_that.countedDays,_that.targetDays,_that.daysWithinTarget,_that.proteinTargetDays,_that.proteinDaysHit,_that.averageKcal,_that.averageTargetKcal,_that.averageFiberG,_that.trendChangeKg,_that.workouts,_that.estimated,_that.checkIn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyWeeklySummary implements BuddyWeeklySummary {
  const _BuddyWeeklySummary({required this.start, required this.end, required this.elapsedDays, required this.countedDays, required this.targetDays, required this.daysWithinTarget, required this.proteinTargetDays, required this.proteinDaysHit, required this.averageKcal, required this.averageTargetKcal, required this.averageFiberG, required this.trendChangeKg, required this.workouts, required this.estimated, required this.checkIn});
  factory _BuddyWeeklySummary.fromJson(Map<String, dynamic> json) => _$BuddyWeeklySummaryFromJson(json);

@override final  String start;
@override final  String end;
/// Days of the week before today (7 for a past week).
@override final  int elapsedDays;
/// Logged, complete days that enter averages (TG-032).
@override final  int countedDays;
@override final  int targetDays;
/// Counted days within 10 % of the calorie target.
@override final  int daysWithinTarget;
@override final  int proteinTargetDays;
@override final  int proteinDaysHit;
/// Average intake over the target days.
@override final  double? averageKcal;
/// Average calorie target over the same days.
@override final  double? averageTargetKcal;
@override final  double? averageFiberG;
/// Trend weight change over the week (kg).
@override final  double? trendChangeKg;
@override final  BuddyWeeklyWorkouts? workouts;
/// Some counted days include estimates.
@override final  bool estimated;
/// The phone's adaptive check-in proposal (A38), when it proposes a change; the app attaches its own pending targetChange card to the review.
@override final  BuddyWeeklyCheckIn? checkIn;

/// Create a copy of BuddyWeeklySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyWeeklySummaryCopyWith<_BuddyWeeklySummary> get copyWith => __$BuddyWeeklySummaryCopyWithImpl<_BuddyWeeklySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyWeeklySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyWeeklySummary&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.elapsedDays, elapsedDays) || other.elapsedDays == elapsedDays)&&(identical(other.countedDays, countedDays) || other.countedDays == countedDays)&&(identical(other.targetDays, targetDays) || other.targetDays == targetDays)&&(identical(other.daysWithinTarget, daysWithinTarget) || other.daysWithinTarget == daysWithinTarget)&&(identical(other.proteinTargetDays, proteinTargetDays) || other.proteinTargetDays == proteinTargetDays)&&(identical(other.proteinDaysHit, proteinDaysHit) || other.proteinDaysHit == proteinDaysHit)&&(identical(other.averageKcal, averageKcal) || other.averageKcal == averageKcal)&&(identical(other.averageTargetKcal, averageTargetKcal) || other.averageTargetKcal == averageTargetKcal)&&(identical(other.averageFiberG, averageFiberG) || other.averageFiberG == averageFiberG)&&(identical(other.trendChangeKg, trendChangeKg) || other.trendChangeKg == trendChangeKg)&&(identical(other.workouts, workouts) || other.workouts == workouts)&&(identical(other.estimated, estimated) || other.estimated == estimated)&&(identical(other.checkIn, checkIn) || other.checkIn == checkIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,start,end,elapsedDays,countedDays,targetDays,daysWithinTarget,proteinTargetDays,proteinDaysHit,averageKcal,averageTargetKcal,averageFiberG,trendChangeKg,workouts,estimated,checkIn);
}

@override
String toString() {
    return 'BuddyWeeklySummary(start: $start, end: $end, elapsedDays: $elapsedDays, countedDays: $countedDays, targetDays: $targetDays, daysWithinTarget: $daysWithinTarget, proteinTargetDays: $proteinTargetDays, proteinDaysHit: $proteinDaysHit, averageKcal: $averageKcal, averageTargetKcal: $averageTargetKcal, averageFiberG: $averageFiberG, trendChangeKg: $trendChangeKg, workouts: $workouts, estimated: $estimated, checkIn: $checkIn)';
}


}

/// @nodoc
abstract mixin class _$BuddyWeeklySummaryCopyWith<$Res> implements $BuddyWeeklySummaryCopyWith<$Res> {
  factory _$BuddyWeeklySummaryCopyWith(_BuddyWeeklySummary value, $Res Function(_BuddyWeeklySummary) _then) = __$BuddyWeeklySummaryCopyWithImpl;
@override @useResult
$Res call({
 String start, String end, int elapsedDays, int countedDays, int targetDays, int daysWithinTarget, int proteinTargetDays, int proteinDaysHit, double? averageKcal, double? averageTargetKcal, double? averageFiberG, double? trendChangeKg, BuddyWeeklyWorkouts? workouts, bool estimated, BuddyWeeklyCheckIn? checkIn
});


@override $BuddyWeeklyWorkoutsCopyWith<$Res>? get workouts;@override $BuddyWeeklyCheckInCopyWith<$Res>? get checkIn;

}
/// @nodoc
class __$BuddyWeeklySummaryCopyWithImpl<$Res>
    implements _$BuddyWeeklySummaryCopyWith<$Res> {
  __$BuddyWeeklySummaryCopyWithImpl(this._self, this._then);

  final _BuddyWeeklySummary _self;
  final $Res Function(_BuddyWeeklySummary) _then;

/// Create a copy of BuddyWeeklySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,Object? elapsedDays = null,Object? countedDays = null,Object? targetDays = null,Object? daysWithinTarget = null,Object? proteinTargetDays = null,Object? proteinDaysHit = null,Object? averageKcal = freezed,Object? averageTargetKcal = freezed,Object? averageFiberG = freezed,Object? trendChangeKg = freezed,Object? workouts = freezed,Object? estimated = null,Object? checkIn = freezed,}) {
  return _then(_BuddyWeeklySummary(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,elapsedDays: null == elapsedDays ? _self.elapsedDays : elapsedDays // ignore: cast_nullable_to_non_nullable
as int,countedDays: null == countedDays ? _self.countedDays : countedDays // ignore: cast_nullable_to_non_nullable
as int,targetDays: null == targetDays ? _self.targetDays : targetDays // ignore: cast_nullable_to_non_nullable
as int,daysWithinTarget: null == daysWithinTarget ? _self.daysWithinTarget : daysWithinTarget // ignore: cast_nullable_to_non_nullable
as int,proteinTargetDays: null == proteinTargetDays ? _self.proteinTargetDays : proteinTargetDays // ignore: cast_nullable_to_non_nullable
as int,proteinDaysHit: null == proteinDaysHit ? _self.proteinDaysHit : proteinDaysHit // ignore: cast_nullable_to_non_nullable
as int,averageKcal: freezed == averageKcal ? _self.averageKcal : averageKcal // ignore: cast_nullable_to_non_nullable
as double?,averageTargetKcal: freezed == averageTargetKcal ? _self.averageTargetKcal : averageTargetKcal // ignore: cast_nullable_to_non_nullable
as double?,averageFiberG: freezed == averageFiberG ? _self.averageFiberG : averageFiberG // ignore: cast_nullable_to_non_nullable
as double?,trendChangeKg: freezed == trendChangeKg ? _self.trendChangeKg : trendChangeKg // ignore: cast_nullable_to_non_nullable
as double?,workouts: freezed == workouts ? _self.workouts : workouts // ignore: cast_nullable_to_non_nullable
as BuddyWeeklyWorkouts?,estimated: null == estimated ? _self.estimated : estimated // ignore: cast_nullable_to_non_nullable
as bool,checkIn: freezed == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as BuddyWeeklyCheckIn?,
  ));
}

/// Create a copy of BuddyWeeklySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyWeeklyWorkoutsCopyWith<$Res>? get workouts {
    if (_self.workouts == null) {
    return null;
  }

  return $BuddyWeeklyWorkoutsCopyWith<$Res>(_self.workouts!, (value) {
    return _then(_self.copyWith(workouts: value));
  });
}/// Create a copy of BuddyWeeklySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyWeeklyCheckInCopyWith<$Res>? get checkIn {
    if (_self.checkIn == null) {
    return null;
  }

  return $BuddyWeeklyCheckInCopyWith<$Res>(_self.checkIn!, (value) {
    return _then(_self.copyWith(checkIn: value));
  });
}
}

// dart format on
