// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_query_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyQueryLink {

 BuddyLinkScreen get screen; String? get date; String? get from; String? get to; String? get exerciseRef; String? get workoutId;
/// Create a copy of BuddyQueryLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyQueryLinkCopyWith<BuddyQueryLink> get copyWith => _$BuddyQueryLinkCopyWithImpl<BuddyQueryLink>(this as BuddyQueryLink, _$identity);

  /// Serializes this BuddyQueryLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyQueryLink;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyQueryLink&&(identical(other.screen, _this.screen) || other.screen == _this.screen)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.to, _this.to) || other.to == _this.to)&&(identical(other.exerciseRef, _this.exerciseRef) || other.exerciseRef == _this.exerciseRef)&&(identical(other.workoutId, _this.workoutId) || other.workoutId == _this.workoutId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyQueryLink;
  return Object.hash(runtimeType,_this.screen,_this.date,_this.from,_this.to,_this.exerciseRef,_this.workoutId);
}

@override
String toString() {
  final _this = this as BuddyQueryLink;
  return 'BuddyQueryLink(screen: ${_this.screen}, date: ${_this.date}, from: ${_this.from}, to: ${_this.to}, exerciseRef: ${_this.exerciseRef}, workoutId: ${_this.workoutId})';
}


}

/// @nodoc
abstract mixin class $BuddyQueryLinkCopyWith<$Res>  {
  factory $BuddyQueryLinkCopyWith(BuddyQueryLink value, $Res Function(BuddyQueryLink) _then) = _$BuddyQueryLinkCopyWithImpl;
@useResult
$Res call({
 BuddyLinkScreen screen, String? date, String? from, String? to, String? exerciseRef, String? workoutId
});




}
/// @nodoc
class _$BuddyQueryLinkCopyWithImpl<$Res>
    implements $BuddyQueryLinkCopyWith<$Res> {
  _$BuddyQueryLinkCopyWithImpl(this._self, this._then);

  final BuddyQueryLink _self;
  final $Res Function(BuddyQueryLink) _then;

/// Create a copy of BuddyQueryLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? screen = null,Object? date = freezed,Object? from = freezed,Object? to = freezed,Object? exerciseRef = freezed,Object? workoutId = freezed,}) {
  return _then(BuddyQueryLink(
screen: null == screen ? _self.screen : screen // ignore: cast_nullable_to_non_nullable
as BuddyLinkScreen,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,exerciseRef: freezed == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String?,workoutId: freezed == workoutId ? _self.workoutId : workoutId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyQueryLink].
extension BuddyQueryLinkPatterns on BuddyQueryLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyQueryLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyQueryLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyQueryLink value)  $default,){
final _that = this;
switch (_that) {
case _BuddyQueryLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyQueryLink value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyQueryLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyLinkScreen screen,  String? date,  String? from,  String? to,  String? exerciseRef,  String? workoutId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyQueryLink() when $default != null:
return $default(_that.screen,_that.date,_that.from,_that.to,_that.exerciseRef,_that.workoutId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyLinkScreen screen,  String? date,  String? from,  String? to,  String? exerciseRef,  String? workoutId)  $default,) {final _that = this;
switch (_that) {
case _BuddyQueryLink():
return $default(_that.screen,_that.date,_that.from,_that.to,_that.exerciseRef,_that.workoutId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyLinkScreen screen,  String? date,  String? from,  String? to,  String? exerciseRef,  String? workoutId)?  $default,) {final _that = this;
switch (_that) {
case _BuddyQueryLink() when $default != null:
return $default(_that.screen,_that.date,_that.from,_that.to,_that.exerciseRef,_that.workoutId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyQueryLink implements BuddyQueryLink {
  const _BuddyQueryLink({required this.screen, required this.date, required this.from, required this.to, required this.exerciseRef, required this.workoutId});
  factory _BuddyQueryLink.fromJson(Map<String, dynamic> json) => _$BuddyQueryLinkFromJson(json);

@override final  BuddyLinkScreen screen;
@override final  String? date;
@override final  String? from;
@override final  String? to;
@override final  String? exerciseRef;
@override final  String? workoutId;

/// Create a copy of BuddyQueryLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyQueryLinkCopyWith<_BuddyQueryLink> get copyWith => __$BuddyQueryLinkCopyWithImpl<_BuddyQueryLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyQueryLinkToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyQueryLink&&(identical(other.screen, screen) || other.screen == screen)&&(identical(other.date, date) || other.date == date)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.exerciseRef, exerciseRef) || other.exerciseRef == exerciseRef)&&(identical(other.workoutId, workoutId) || other.workoutId == workoutId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,screen,date,from,to,exerciseRef,workoutId);
}

@override
String toString() {
    return 'BuddyQueryLink(screen: $screen, date: $date, from: $from, to: $to, exerciseRef: $exerciseRef, workoutId: $workoutId)';
}


}

/// @nodoc
abstract mixin class _$BuddyQueryLinkCopyWith<$Res> implements $BuddyQueryLinkCopyWith<$Res> {
  factory _$BuddyQueryLinkCopyWith(_BuddyQueryLink value, $Res Function(_BuddyQueryLink) _then) = __$BuddyQueryLinkCopyWithImpl;
@override @useResult
$Res call({
 BuddyLinkScreen screen, String? date, String? from, String? to, String? exerciseRef, String? workoutId
});




}
/// @nodoc
class __$BuddyQueryLinkCopyWithImpl<$Res>
    implements _$BuddyQueryLinkCopyWith<$Res> {
  __$BuddyQueryLinkCopyWithImpl(this._self, this._then);

  final _BuddyQueryLink _self;
  final $Res Function(_BuddyQueryLink) _then;

/// Create a copy of BuddyQueryLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? screen = null,Object? date = freezed,Object? from = freezed,Object? to = freezed,Object? exerciseRef = freezed,Object? workoutId = freezed,}) {
  return _then(_BuddyQueryLink(
screen: null == screen ? _self.screen : screen // ignore: cast_nullable_to_non_nullable
as BuddyLinkScreen,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,exerciseRef: freezed == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String?,workoutId: freezed == workoutId ? _self.workoutId : workoutId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
