// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_query_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyQueryPlan {

 BuddyQueryMetric get metric;/// With metric measurement: a built-in kind (waist, chest, hips, arm, thigh, neck, bodyFat) or a custom type UUID; otherwise null.
 String? get measurementType; BuddyQueryOp get op; BuddyQueryPeriod get period; BuddyQueryFilters? get filters;
/// Create a copy of BuddyQueryPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyQueryPlanCopyWith<BuddyQueryPlan> get copyWith => _$BuddyQueryPlanCopyWithImpl<BuddyQueryPlan>(this as BuddyQueryPlan, _$identity);

  /// Serializes this BuddyQueryPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyQueryPlan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyQueryPlan&&(identical(other.metric, _this.metric) || other.metric == _this.metric)&&(identical(other.measurementType, _this.measurementType) || other.measurementType == _this.measurementType)&&(identical(other.op, _this.op) || other.op == _this.op)&&(identical(other.period, _this.period) || other.period == _this.period)&&(identical(other.filters, _this.filters) || other.filters == _this.filters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyQueryPlan;
  return Object.hash(runtimeType,_this.metric,_this.measurementType,_this.op,_this.period,_this.filters);
}

@override
String toString() {
  final _this = this as BuddyQueryPlan;
  return 'BuddyQueryPlan(metric: ${_this.metric}, measurementType: ${_this.measurementType}, op: ${_this.op}, period: ${_this.period}, filters: ${_this.filters})';
}


}

/// @nodoc
abstract mixin class $BuddyQueryPlanCopyWith<$Res>  {
  factory $BuddyQueryPlanCopyWith(BuddyQueryPlan value, $Res Function(BuddyQueryPlan) _then) = _$BuddyQueryPlanCopyWithImpl;
@useResult
$Res call({
 BuddyQueryMetric metric, String? measurementType, BuddyQueryOp op, BuddyQueryPeriod period, BuddyQueryFilters? filters
});


$BuddyQueryPeriodCopyWith<$Res> get period;$BuddyQueryFiltersCopyWith<$Res>? get filters;

}
/// @nodoc
class _$BuddyQueryPlanCopyWithImpl<$Res>
    implements $BuddyQueryPlanCopyWith<$Res> {
  _$BuddyQueryPlanCopyWithImpl(this._self, this._then);

  final BuddyQueryPlan _self;
  final $Res Function(BuddyQueryPlan) _then;

/// Create a copy of BuddyQueryPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metric = null,Object? measurementType = freezed,Object? op = null,Object? period = null,Object? filters = freezed,}) {
  return _then(BuddyQueryPlan(
metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as BuddyQueryMetric,measurementType: freezed == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as String?,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as BuddyQueryOp,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as BuddyQueryPeriod,filters: freezed == filters ? _self.filters : filters // ignore: cast_nullable_to_non_nullable
as BuddyQueryFilters?,
  ));
}
/// Create a copy of BuddyQueryPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyQueryPeriodCopyWith<$Res> get period {
  
  return $BuddyQueryPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of BuddyQueryPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyQueryFiltersCopyWith<$Res>? get filters {
    if (_self.filters == null) {
    return null;
  }

  return $BuddyQueryFiltersCopyWith<$Res>(_self.filters!, (value) {
    return _then(_self.copyWith(filters: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyQueryPlan].
extension BuddyQueryPlanPatterns on BuddyQueryPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyQueryPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyQueryPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyQueryPlan value)  $default,){
final _that = this;
switch (_that) {
case _BuddyQueryPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyQueryPlan value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyQueryPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyQueryMetric metric,  String? measurementType,  BuddyQueryOp op,  BuddyQueryPeriod period,  BuddyQueryFilters? filters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyQueryPlan() when $default != null:
return $default(_that.metric,_that.measurementType,_that.op,_that.period,_that.filters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyQueryMetric metric,  String? measurementType,  BuddyQueryOp op,  BuddyQueryPeriod period,  BuddyQueryFilters? filters)  $default,) {final _that = this;
switch (_that) {
case _BuddyQueryPlan():
return $default(_that.metric,_that.measurementType,_that.op,_that.period,_that.filters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyQueryMetric metric,  String? measurementType,  BuddyQueryOp op,  BuddyQueryPeriod period,  BuddyQueryFilters? filters)?  $default,) {final _that = this;
switch (_that) {
case _BuddyQueryPlan() when $default != null:
return $default(_that.metric,_that.measurementType,_that.op,_that.period,_that.filters);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyQueryPlan implements BuddyQueryPlan {
  const _BuddyQueryPlan({required this.metric, required this.measurementType, required this.op, required this.period, required this.filters});
  factory _BuddyQueryPlan.fromJson(Map<String, dynamic> json) => _$BuddyQueryPlanFromJson(json);

@override final  BuddyQueryMetric metric;
/// With metric measurement: a built-in kind (waist, chest, hips, arm, thigh, neck, bodyFat) or a custom type UUID; otherwise null.
@override final  String? measurementType;
@override final  BuddyQueryOp op;
@override final  BuddyQueryPeriod period;
@override final  BuddyQueryFilters? filters;

/// Create a copy of BuddyQueryPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyQueryPlanCopyWith<_BuddyQueryPlan> get copyWith => __$BuddyQueryPlanCopyWithImpl<_BuddyQueryPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyQueryPlanToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyQueryPlan&&(identical(other.metric, metric) || other.metric == metric)&&(identical(other.measurementType, measurementType) || other.measurementType == measurementType)&&(identical(other.op, op) || other.op == op)&&(identical(other.period, period) || other.period == period)&&(identical(other.filters, filters) || other.filters == filters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,metric,measurementType,op,period,filters);
}

@override
String toString() {
    return 'BuddyQueryPlan(metric: $metric, measurementType: $measurementType, op: $op, period: $period, filters: $filters)';
}


}

/// @nodoc
abstract mixin class _$BuddyQueryPlanCopyWith<$Res> implements $BuddyQueryPlanCopyWith<$Res> {
  factory _$BuddyQueryPlanCopyWith(_BuddyQueryPlan value, $Res Function(_BuddyQueryPlan) _then) = __$BuddyQueryPlanCopyWithImpl;
@override @useResult
$Res call({
 BuddyQueryMetric metric, String? measurementType, BuddyQueryOp op, BuddyQueryPeriod period, BuddyQueryFilters? filters
});


@override $BuddyQueryPeriodCopyWith<$Res> get period;@override $BuddyQueryFiltersCopyWith<$Res>? get filters;

}
/// @nodoc
class __$BuddyQueryPlanCopyWithImpl<$Res>
    implements _$BuddyQueryPlanCopyWith<$Res> {
  __$BuddyQueryPlanCopyWithImpl(this._self, this._then);

  final _BuddyQueryPlan _self;
  final $Res Function(_BuddyQueryPlan) _then;

/// Create a copy of BuddyQueryPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? metric = null,Object? measurementType = freezed,Object? op = null,Object? period = null,Object? filters = freezed,}) {
  return _then(_BuddyQueryPlan(
metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as BuddyQueryMetric,measurementType: freezed == measurementType ? _self.measurementType : measurementType // ignore: cast_nullable_to_non_nullable
as String?,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as BuddyQueryOp,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as BuddyQueryPeriod,filters: freezed == filters ? _self.filters : filters // ignore: cast_nullable_to_non_nullable
as BuddyQueryFilters?,
  ));
}

/// Create a copy of BuddyQueryPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyQueryPeriodCopyWith<$Res> get period {
  
  return $BuddyQueryPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of BuddyQueryPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyQueryFiltersCopyWith<$Res>? get filters {
    if (_self.filters == null) {
    return null;
  }

  return $BuddyQueryFiltersCopyWith<$Res>(_self.filters!, (value) {
    return _then(_self.copyWith(filters: value));
  });
}
}

// dart format on
