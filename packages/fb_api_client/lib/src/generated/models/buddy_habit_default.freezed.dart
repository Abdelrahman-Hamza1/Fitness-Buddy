// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_habit_default.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyHabitDefault {

 String get kind; String get subject; String get value;
/// Create a copy of BuddyHabitDefault
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyHabitDefaultCopyWith<BuddyHabitDefault> get copyWith => _$BuddyHabitDefaultCopyWithImpl<BuddyHabitDefault>(this as BuddyHabitDefault, _$identity);

  /// Serializes this BuddyHabitDefault to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyHabitDefault;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyHabitDefault&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.subject, _this.subject) || other.subject == _this.subject)&&(identical(other.value, _this.value) || other.value == _this.value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyHabitDefault;
  return Object.hash(runtimeType,_this.kind,_this.subject,_this.value);
}

@override
String toString() {
  final _this = this as BuddyHabitDefault;
  return 'BuddyHabitDefault(kind: ${_this.kind}, subject: ${_this.subject}, value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $BuddyHabitDefaultCopyWith<$Res>  {
  factory $BuddyHabitDefaultCopyWith(BuddyHabitDefault value, $Res Function(BuddyHabitDefault) _then) = _$BuddyHabitDefaultCopyWithImpl;
@useResult
$Res call({
 String kind, String subject, String value
});




}
/// @nodoc
class _$BuddyHabitDefaultCopyWithImpl<$Res>
    implements $BuddyHabitDefaultCopyWith<$Res> {
  _$BuddyHabitDefaultCopyWithImpl(this._self, this._then);

  final BuddyHabitDefault _self;
  final $Res Function(BuddyHabitDefault) _then;

/// Create a copy of BuddyHabitDefault
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? subject = null,Object? value = null,}) {
  return _then(BuddyHabitDefault(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyHabitDefault].
extension BuddyHabitDefaultPatterns on BuddyHabitDefault {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyHabitDefault value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyHabitDefault() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyHabitDefault value)  $default,){
final _that = this;
switch (_that) {
case _BuddyHabitDefault():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyHabitDefault value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyHabitDefault() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String subject,  String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyHabitDefault() when $default != null:
return $default(_that.kind,_that.subject,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String subject,  String value)  $default,) {final _that = this;
switch (_that) {
case _BuddyHabitDefault():
return $default(_that.kind,_that.subject,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String subject,  String value)?  $default,) {final _that = this;
switch (_that) {
case _BuddyHabitDefault() when $default != null:
return $default(_that.kind,_that.subject,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyHabitDefault implements BuddyHabitDefault {
  const _BuddyHabitDefault({required this.kind, required this.subject, required this.value});
  factory _BuddyHabitDefault.fromJson(Map<String, dynamic> json) => _$BuddyHabitDefaultFromJson(json);

@override final  String kind;
@override final  String subject;
@override final  String value;

/// Create a copy of BuddyHabitDefault
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyHabitDefaultCopyWith<_BuddyHabitDefault> get copyWith => __$BuddyHabitDefaultCopyWithImpl<_BuddyHabitDefault>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyHabitDefaultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyHabitDefault&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,subject,value);
}

@override
String toString() {
    return 'BuddyHabitDefault(kind: $kind, subject: $subject, value: $value)';
}


}

/// @nodoc
abstract mixin class _$BuddyHabitDefaultCopyWith<$Res> implements $BuddyHabitDefaultCopyWith<$Res> {
  factory _$BuddyHabitDefaultCopyWith(_BuddyHabitDefault value, $Res Function(_BuddyHabitDefault) _then) = __$BuddyHabitDefaultCopyWithImpl;
@override @useResult
$Res call({
 String kind, String subject, String value
});




}
/// @nodoc
class __$BuddyHabitDefaultCopyWithImpl<$Res>
    implements _$BuddyHabitDefaultCopyWith<$Res> {
  __$BuddyHabitDefaultCopyWithImpl(this._self, this._then);

  final _BuddyHabitDefault _self;
  final $Res Function(_BuddyHabitDefault) _then;

/// Create a copy of BuddyHabitDefault
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? subject = null,Object? value = null,}) {
  return _then(_BuddyHabitDefault(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
