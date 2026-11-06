// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_query_filters.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyQueryFilters {

 String? get slot; String? get exerciseRef;/// A library muscle group (e.g. legs), for op last.
 String? get muscleGroup;/// null means the default: true for averages.
 bool? get completeDaysOnly;/// ISO weekdays 1 (Monday) to 7; empty means every day.
 List<int> get weekdays;
/// Create a copy of BuddyQueryFilters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyQueryFiltersCopyWith<BuddyQueryFilters> get copyWith => _$BuddyQueryFiltersCopyWithImpl<BuddyQueryFilters>(this as BuddyQueryFilters, _$identity);

  /// Serializes this BuddyQueryFilters to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyQueryFilters;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyQueryFilters&&(identical(other.slot, _this.slot) || other.slot == _this.slot)&&(identical(other.exerciseRef, _this.exerciseRef) || other.exerciseRef == _this.exerciseRef)&&(identical(other.muscleGroup, _this.muscleGroup) || other.muscleGroup == _this.muscleGroup)&&(identical(other.completeDaysOnly, _this.completeDaysOnly) || other.completeDaysOnly == _this.completeDaysOnly)&&const DeepCollectionEquality().equals(other.weekdays, _this.weekdays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyQueryFilters;
  return Object.hash(runtimeType,_this.slot,_this.exerciseRef,_this.muscleGroup,_this.completeDaysOnly,const DeepCollectionEquality().hash(_this.weekdays));
}

@override
String toString() {
  final _this = this as BuddyQueryFilters;
  return 'BuddyQueryFilters(slot: ${_this.slot}, exerciseRef: ${_this.exerciseRef}, muscleGroup: ${_this.muscleGroup}, completeDaysOnly: ${_this.completeDaysOnly}, weekdays: ${_this.weekdays})';
}


}

/// @nodoc
abstract mixin class $BuddyQueryFiltersCopyWith<$Res>  {
  factory $BuddyQueryFiltersCopyWith(BuddyQueryFilters value, $Res Function(BuddyQueryFilters) _then) = _$BuddyQueryFiltersCopyWithImpl;
@useResult
$Res call({
 String? slot, String? exerciseRef, String? muscleGroup, bool? completeDaysOnly, List<int> weekdays
});




}
/// @nodoc
class _$BuddyQueryFiltersCopyWithImpl<$Res>
    implements $BuddyQueryFiltersCopyWith<$Res> {
  _$BuddyQueryFiltersCopyWithImpl(this._self, this._then);

  final BuddyQueryFilters _self;
  final $Res Function(BuddyQueryFilters) _then;

/// Create a copy of BuddyQueryFilters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slot = freezed,Object? exerciseRef = freezed,Object? muscleGroup = freezed,Object? completeDaysOnly = freezed,Object? weekdays = null,}) {
  return _then(BuddyQueryFilters(
slot: freezed == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String?,exerciseRef: freezed == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String?,muscleGroup: freezed == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as String?,completeDaysOnly: freezed == completeDaysOnly ? _self.completeDaysOnly : completeDaysOnly // ignore: cast_nullable_to_non_nullable
as bool?,weekdays: null == weekdays ? _self.weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyQueryFilters].
extension BuddyQueryFiltersPatterns on BuddyQueryFilters {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyQueryFilters value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyQueryFilters() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyQueryFilters value)  $default,){
final _that = this;
switch (_that) {
case _BuddyQueryFilters():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyQueryFilters value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyQueryFilters() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? slot,  String? exerciseRef,  String? muscleGroup,  bool? completeDaysOnly,  List<int> weekdays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyQueryFilters() when $default != null:
return $default(_that.slot,_that.exerciseRef,_that.muscleGroup,_that.completeDaysOnly,_that.weekdays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? slot,  String? exerciseRef,  String? muscleGroup,  bool? completeDaysOnly,  List<int> weekdays)  $default,) {final _that = this;
switch (_that) {
case _BuddyQueryFilters():
return $default(_that.slot,_that.exerciseRef,_that.muscleGroup,_that.completeDaysOnly,_that.weekdays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? slot,  String? exerciseRef,  String? muscleGroup,  bool? completeDaysOnly,  List<int> weekdays)?  $default,) {final _that = this;
switch (_that) {
case _BuddyQueryFilters() when $default != null:
return $default(_that.slot,_that.exerciseRef,_that.muscleGroup,_that.completeDaysOnly,_that.weekdays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyQueryFilters implements BuddyQueryFilters {
  const _BuddyQueryFilters({required this.slot, required this.exerciseRef, required this.muscleGroup, required this.completeDaysOnly, required  List<int> weekdays}): _weekdays = weekdays;
  factory _BuddyQueryFilters.fromJson(Map<String, dynamic> json) => _$BuddyQueryFiltersFromJson(json);

@override final  String? slot;
@override final  String? exerciseRef;
/// A library muscle group (e.g. legs), for op last.
@override final  String? muscleGroup;
/// null means the default: true for averages.
@override final  bool? completeDaysOnly;
/// ISO weekdays 1 (Monday) to 7; empty means every day.
 final  List<int> _weekdays;
/// ISO weekdays 1 (Monday) to 7; empty means every day.
@override List<int> get weekdays {
  if (_weekdays is EqualUnmodifiableListView) return _weekdays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weekdays);
}


/// Create a copy of BuddyQueryFilters
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyQueryFiltersCopyWith<_BuddyQueryFilters> get copyWith => __$BuddyQueryFiltersCopyWithImpl<_BuddyQueryFilters>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyQueryFiltersToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyQueryFilters&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.exerciseRef, exerciseRef) || other.exerciseRef == exerciseRef)&&(identical(other.muscleGroup, muscleGroup) || other.muscleGroup == muscleGroup)&&(identical(other.completeDaysOnly, completeDaysOnly) || other.completeDaysOnly == completeDaysOnly)&&const DeepCollectionEquality().equals(other.weekdays, _weekdays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,slot,exerciseRef,muscleGroup,completeDaysOnly,const DeepCollectionEquality().hash(_weekdays));
}

@override
String toString() {
    return 'BuddyQueryFilters(slot: $slot, exerciseRef: $exerciseRef, muscleGroup: $muscleGroup, completeDaysOnly: $completeDaysOnly, weekdays: $weekdays)';
}


}

/// @nodoc
abstract mixin class _$BuddyQueryFiltersCopyWith<$Res> implements $BuddyQueryFiltersCopyWith<$Res> {
  factory _$BuddyQueryFiltersCopyWith(_BuddyQueryFilters value, $Res Function(_BuddyQueryFilters) _then) = __$BuddyQueryFiltersCopyWithImpl;
@override @useResult
$Res call({
 String? slot, String? exerciseRef, String? muscleGroup, bool? completeDaysOnly, List<int> weekdays
});




}
/// @nodoc
class __$BuddyQueryFiltersCopyWithImpl<$Res>
    implements _$BuddyQueryFiltersCopyWith<$Res> {
  __$BuddyQueryFiltersCopyWithImpl(this._self, this._then);

  final _BuddyQueryFilters _self;
  final $Res Function(_BuddyQueryFilters) _then;

/// Create a copy of BuddyQueryFilters
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slot = freezed,Object? exerciseRef = freezed,Object? muscleGroup = freezed,Object? completeDaysOnly = freezed,Object? weekdays = null,}) {
  return _then(_BuddyQueryFilters(
slot: freezed == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String?,exerciseRef: freezed == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String?,muscleGroup: freezed == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as String?,completeDaysOnly: freezed == completeDaysOnly ? _self.completeDaysOnly : completeDaysOnly // ignore: cast_nullable_to_non_nullable
as bool?,weekdays: null == weekdays ? _self._weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
