// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_workouts_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadWorkoutsData {

 List<BuddyWorkoutSessionRow> get sessions; List<BuddyExercisePr> get prs;
/// Create a copy of BuddyReadWorkoutsData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadWorkoutsDataCopyWith<BuddyReadWorkoutsData> get copyWith => _$BuddyReadWorkoutsDataCopyWithImpl<BuddyReadWorkoutsData>(this as BuddyReadWorkoutsData, _$identity);

  /// Serializes this BuddyReadWorkoutsData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadWorkoutsData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadWorkoutsData&&const DeepCollectionEquality().equals(other.sessions, _this.sessions)&&const DeepCollectionEquality().equals(other.prs, _this.prs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadWorkoutsData;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.sessions),const DeepCollectionEquality().hash(_this.prs));
}

@override
String toString() {
  final _this = this as BuddyReadWorkoutsData;
  return 'BuddyReadWorkoutsData(sessions: ${_this.sessions}, prs: ${_this.prs})';
}


}

/// @nodoc
abstract mixin class $BuddyReadWorkoutsDataCopyWith<$Res>  {
  factory $BuddyReadWorkoutsDataCopyWith(BuddyReadWorkoutsData value, $Res Function(BuddyReadWorkoutsData) _then) = _$BuddyReadWorkoutsDataCopyWithImpl;
@useResult
$Res call({
 List<BuddyWorkoutSessionRow> sessions, List<BuddyExercisePr> prs
});




}
/// @nodoc
class _$BuddyReadWorkoutsDataCopyWithImpl<$Res>
    implements $BuddyReadWorkoutsDataCopyWith<$Res> {
  _$BuddyReadWorkoutsDataCopyWithImpl(this._self, this._then);

  final BuddyReadWorkoutsData _self;
  final $Res Function(BuddyReadWorkoutsData) _then;

/// Create a copy of BuddyReadWorkoutsData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessions = null,Object? prs = null,}) {
  return _then(BuddyReadWorkoutsData(
sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<BuddyWorkoutSessionRow>,prs: null == prs ? _self.prs : prs // ignore: cast_nullable_to_non_nullable
as List<BuddyExercisePr>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyReadWorkoutsData].
extension BuddyReadWorkoutsDataPatterns on BuddyReadWorkoutsData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadWorkoutsData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadWorkoutsData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadWorkoutsData value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadWorkoutsData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadWorkoutsData value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadWorkoutsData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BuddyWorkoutSessionRow> sessions,  List<BuddyExercisePr> prs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadWorkoutsData() when $default != null:
return $default(_that.sessions,_that.prs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BuddyWorkoutSessionRow> sessions,  List<BuddyExercisePr> prs)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadWorkoutsData():
return $default(_that.sessions,_that.prs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BuddyWorkoutSessionRow> sessions,  List<BuddyExercisePr> prs)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadWorkoutsData() when $default != null:
return $default(_that.sessions,_that.prs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadWorkoutsData implements BuddyReadWorkoutsData {
  const _BuddyReadWorkoutsData({required  List<BuddyWorkoutSessionRow> sessions, required  List<BuddyExercisePr> prs}): _sessions = sessions,_prs = prs;
  factory _BuddyReadWorkoutsData.fromJson(Map<String, dynamic> json) => _$BuddyReadWorkoutsDataFromJson(json);

 final  List<BuddyWorkoutSessionRow> _sessions;
@override List<BuddyWorkoutSessionRow> get sessions {
  if (_sessions is EqualUnmodifiableListView) return _sessions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sessions);
}

 final  List<BuddyExercisePr> _prs;
@override List<BuddyExercisePr> get prs {
  if (_prs is EqualUnmodifiableListView) return _prs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_prs);
}


/// Create a copy of BuddyReadWorkoutsData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadWorkoutsDataCopyWith<_BuddyReadWorkoutsData> get copyWith => __$BuddyReadWorkoutsDataCopyWithImpl<_BuddyReadWorkoutsData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadWorkoutsDataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadWorkoutsData&&const DeepCollectionEquality().equals(other.sessions, _sessions)&&const DeepCollectionEquality().equals(other.prs, _prs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_sessions),const DeepCollectionEquality().hash(_prs));
}

@override
String toString() {
    return 'BuddyReadWorkoutsData(sessions: $sessions, prs: $prs)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadWorkoutsDataCopyWith<$Res> implements $BuddyReadWorkoutsDataCopyWith<$Res> {
  factory _$BuddyReadWorkoutsDataCopyWith(_BuddyReadWorkoutsData value, $Res Function(_BuddyReadWorkoutsData) _then) = __$BuddyReadWorkoutsDataCopyWithImpl;
@override @useResult
$Res call({
 List<BuddyWorkoutSessionRow> sessions, List<BuddyExercisePr> prs
});




}
/// @nodoc
class __$BuddyReadWorkoutsDataCopyWithImpl<$Res>
    implements _$BuddyReadWorkoutsDataCopyWith<$Res> {
  __$BuddyReadWorkoutsDataCopyWithImpl(this._self, this._then);

  final _BuddyReadWorkoutsData _self;
  final $Res Function(_BuddyReadWorkoutsData) _then;

/// Create a copy of BuddyReadWorkoutsData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessions = null,Object? prs = null,}) {
  return _then(_BuddyReadWorkoutsData(
sessions: null == sessions ? _self._sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<BuddyWorkoutSessionRow>,prs: null == prs ? _self._prs : prs // ignore: cast_nullable_to_non_nullable
as List<BuddyExercisePr>,
  ));
}


}

// dart format on
