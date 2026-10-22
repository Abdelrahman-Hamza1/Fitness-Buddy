// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyShare {

 double? get fraction; int? get people;
/// Create a copy of BuddyShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyShareCopyWith<BuddyShare> get copyWith => _$BuddyShareCopyWithImpl<BuddyShare>(this as BuddyShare, _$identity);

  /// Serializes this BuddyShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyShare;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyShare&&(identical(other.fraction, _this.fraction) || other.fraction == _this.fraction)&&(identical(other.people, _this.people) || other.people == _this.people));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyShare;
  return Object.hash(runtimeType,_this.fraction,_this.people);
}

@override
String toString() {
  final _this = this as BuddyShare;
  return 'BuddyShare(fraction: ${_this.fraction}, people: ${_this.people})';
}


}

/// @nodoc
abstract mixin class $BuddyShareCopyWith<$Res>  {
  factory $BuddyShareCopyWith(BuddyShare value, $Res Function(BuddyShare) _then) = _$BuddyShareCopyWithImpl;
@useResult
$Res call({
 double? fraction, int? people
});




}
/// @nodoc
class _$BuddyShareCopyWithImpl<$Res>
    implements $BuddyShareCopyWith<$Res> {
  _$BuddyShareCopyWithImpl(this._self, this._then);

  final BuddyShare _self;
  final $Res Function(BuddyShare) _then;

/// Create a copy of BuddyShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fraction = freezed,Object? people = freezed,}) {
  return _then(BuddyShare(
fraction: freezed == fraction ? _self.fraction : fraction // ignore: cast_nullable_to_non_nullable
as double?,people: freezed == people ? _self.people : people // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyShare].
extension BuddySharePatterns on BuddyShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyShare value)  $default,){
final _that = this;
switch (_that) {
case _BuddyShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyShare value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? fraction,  int? people)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyShare() when $default != null:
return $default(_that.fraction,_that.people);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? fraction,  int? people)  $default,) {final _that = this;
switch (_that) {
case _BuddyShare():
return $default(_that.fraction,_that.people);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? fraction,  int? people)?  $default,) {final _that = this;
switch (_that) {
case _BuddyShare() when $default != null:
return $default(_that.fraction,_that.people);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyShare implements BuddyShare {
  const _BuddyShare({required this.fraction, required this.people});
  factory _BuddyShare.fromJson(Map<String, dynamic> json) => _$BuddyShareFromJson(json);

@override final  double? fraction;
@override final  int? people;

/// Create a copy of BuddyShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyShareCopyWith<_BuddyShare> get copyWith => __$BuddyShareCopyWithImpl<_BuddyShare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyShareToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyShare&&(identical(other.fraction, fraction) || other.fraction == fraction)&&(identical(other.people, people) || other.people == people));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,fraction,people);
}

@override
String toString() {
    return 'BuddyShare(fraction: $fraction, people: $people)';
}


}

/// @nodoc
abstract mixin class _$BuddyShareCopyWith<$Res> implements $BuddyShareCopyWith<$Res> {
  factory _$BuddyShareCopyWith(_BuddyShare value, $Res Function(_BuddyShare) _then) = __$BuddyShareCopyWithImpl;
@override @useResult
$Res call({
 double? fraction, int? people
});




}
/// @nodoc
class __$BuddyShareCopyWithImpl<$Res>
    implements _$BuddyShareCopyWith<$Res> {
  __$BuddyShareCopyWithImpl(this._self, this._then);

  final _BuddyShare _self;
  final $Res Function(_BuddyShare) _then;

/// Create a copy of BuddyShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fraction = freezed,Object? people = freezed,}) {
  return _then(_BuddyShare(
fraction: freezed == fraction ? _self.fraction : fraction // ignore: cast_nullable_to_non_nullable
as double?,people: freezed == people ? _self.people : people // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
