// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_body_args.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadBodyArgs {

 BuddyDateRange get range; BuddyBodyRead get what;
/// Create a copy of BuddyReadBodyArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadBodyArgsCopyWith<BuddyReadBodyArgs> get copyWith => _$BuddyReadBodyArgsCopyWithImpl<BuddyReadBodyArgs>(this as BuddyReadBodyArgs, _$identity);

  /// Serializes this BuddyReadBodyArgs to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadBodyArgs;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadBodyArgs&&(identical(other.range, _this.range) || other.range == _this.range)&&(identical(other.what, _this.what) || other.what == _this.what));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadBodyArgs;
  return Object.hash(runtimeType,_this.range,_this.what);
}

@override
String toString() {
  final _this = this as BuddyReadBodyArgs;
  return 'BuddyReadBodyArgs(range: ${_this.range}, what: ${_this.what})';
}


}

/// @nodoc
abstract mixin class $BuddyReadBodyArgsCopyWith<$Res>  {
  factory $BuddyReadBodyArgsCopyWith(BuddyReadBodyArgs value, $Res Function(BuddyReadBodyArgs) _then) = _$BuddyReadBodyArgsCopyWithImpl;
@useResult
$Res call({
 BuddyDateRange range, BuddyBodyRead what
});


$BuddyDateRangeCopyWith<$Res> get range;

}
/// @nodoc
class _$BuddyReadBodyArgsCopyWithImpl<$Res>
    implements $BuddyReadBodyArgsCopyWith<$Res> {
  _$BuddyReadBodyArgsCopyWithImpl(this._self, this._then);

  final BuddyReadBodyArgs _self;
  final $Res Function(BuddyReadBodyArgs) _then;

/// Create a copy of BuddyReadBodyArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? range = null,Object? what = null,}) {
  return _then(BuddyReadBodyArgs(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as BuddyDateRange,what: null == what ? _self.what : what // ignore: cast_nullable_to_non_nullable
as BuddyBodyRead,
  ));
}
/// Create a copy of BuddyReadBodyArgs
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDateRangeCopyWith<$Res> get range {
  
  return $BuddyDateRangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyReadBodyArgs].
extension BuddyReadBodyArgsPatterns on BuddyReadBodyArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadBodyArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadBodyArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadBodyArgs value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadBodyArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadBodyArgs value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadBodyArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyDateRange range,  BuddyBodyRead what)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadBodyArgs() when $default != null:
return $default(_that.range,_that.what);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyDateRange range,  BuddyBodyRead what)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadBodyArgs():
return $default(_that.range,_that.what);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyDateRange range,  BuddyBodyRead what)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadBodyArgs() when $default != null:
return $default(_that.range,_that.what);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadBodyArgs implements BuddyReadBodyArgs {
  const _BuddyReadBodyArgs({required this.range, required this.what});
  factory _BuddyReadBodyArgs.fromJson(Map<String, dynamic> json) => _$BuddyReadBodyArgsFromJson(json);

@override final  BuddyDateRange range;
@override final  BuddyBodyRead what;

/// Create a copy of BuddyReadBodyArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadBodyArgsCopyWith<_BuddyReadBodyArgs> get copyWith => __$BuddyReadBodyArgsCopyWithImpl<_BuddyReadBodyArgs>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadBodyArgsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadBodyArgs&&(identical(other.range, range) || other.range == range)&&(identical(other.what, what) || other.what == what));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,range,what);
}

@override
String toString() {
    return 'BuddyReadBodyArgs(range: $range, what: $what)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadBodyArgsCopyWith<$Res> implements $BuddyReadBodyArgsCopyWith<$Res> {
  factory _$BuddyReadBodyArgsCopyWith(_BuddyReadBodyArgs value, $Res Function(_BuddyReadBodyArgs) _then) = __$BuddyReadBodyArgsCopyWithImpl;
@override @useResult
$Res call({
 BuddyDateRange range, BuddyBodyRead what
});


@override $BuddyDateRangeCopyWith<$Res> get range;

}
/// @nodoc
class __$BuddyReadBodyArgsCopyWithImpl<$Res>
    implements _$BuddyReadBodyArgsCopyWith<$Res> {
  __$BuddyReadBodyArgsCopyWithImpl(this._self, this._then);

  final _BuddyReadBodyArgs _self;
  final $Res Function(_BuddyReadBodyArgs) _then;

/// Create a copy of BuddyReadBodyArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? range = null,Object? what = null,}) {
  return _then(_BuddyReadBodyArgs(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as BuddyDateRange,what: null == what ? _self.what : what // ignore: cast_nullable_to_non_nullable
as BuddyBodyRead,
  ));
}

/// Create a copy of BuddyReadBodyArgs
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDateRangeCopyWith<$Res> get range {
  
  return $BuddyDateRangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}

// dart format on
