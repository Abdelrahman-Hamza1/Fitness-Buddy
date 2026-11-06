// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_workouts_call.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadWorkoutsCall {

 BuddyReadWorkoutsCallName get name; String get callId; BuddyReadWorkoutsArgs get args;
/// Create a copy of BuddyReadWorkoutsCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadWorkoutsCallCopyWith<BuddyReadWorkoutsCall> get copyWith => _$BuddyReadWorkoutsCallCopyWithImpl<BuddyReadWorkoutsCall>(this as BuddyReadWorkoutsCall, _$identity);

  /// Serializes this BuddyReadWorkoutsCall to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadWorkoutsCall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadWorkoutsCall&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.callId, _this.callId) || other.callId == _this.callId)&&(identical(other.args, _this.args) || other.args == _this.args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadWorkoutsCall;
  return Object.hash(runtimeType,_this.name,_this.callId,_this.args);
}

@override
String toString() {
  final _this = this as BuddyReadWorkoutsCall;
  return 'BuddyReadWorkoutsCall(name: ${_this.name}, callId: ${_this.callId}, args: ${_this.args})';
}


}

/// @nodoc
abstract mixin class $BuddyReadWorkoutsCallCopyWith<$Res>  {
  factory $BuddyReadWorkoutsCallCopyWith(BuddyReadWorkoutsCall value, $Res Function(BuddyReadWorkoutsCall) _then) = _$BuddyReadWorkoutsCallCopyWithImpl;
@useResult
$Res call({
 BuddyReadWorkoutsCallName name, String callId, BuddyReadWorkoutsArgs args
});


$BuddyReadWorkoutsArgsCopyWith<$Res> get args;

}
/// @nodoc
class _$BuddyReadWorkoutsCallCopyWithImpl<$Res>
    implements $BuddyReadWorkoutsCallCopyWith<$Res> {
  _$BuddyReadWorkoutsCallCopyWithImpl(this._self, this._then);

  final BuddyReadWorkoutsCall _self;
  final $Res Function(BuddyReadWorkoutsCall) _then;

/// Create a copy of BuddyReadWorkoutsCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(BuddyReadWorkoutsCall(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadWorkoutsCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyReadWorkoutsArgs,
  ));
}
/// Create a copy of BuddyReadWorkoutsCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadWorkoutsArgsCopyWith<$Res> get args {
  
  return $BuddyReadWorkoutsArgsCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyReadWorkoutsCall].
extension BuddyReadWorkoutsCallPatterns on BuddyReadWorkoutsCall {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadWorkoutsCall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadWorkoutsCall() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadWorkoutsCall value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadWorkoutsCall():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadWorkoutsCall value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadWorkoutsCall() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyReadWorkoutsCallName name,  String callId,  BuddyReadWorkoutsArgs args)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadWorkoutsCall() when $default != null:
return $default(_that.name,_that.callId,_that.args);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyReadWorkoutsCallName name,  String callId,  BuddyReadWorkoutsArgs args)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadWorkoutsCall():
return $default(_that.name,_that.callId,_that.args);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyReadWorkoutsCallName name,  String callId,  BuddyReadWorkoutsArgs args)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadWorkoutsCall() when $default != null:
return $default(_that.name,_that.callId,_that.args);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadWorkoutsCall implements BuddyReadWorkoutsCall {
  const _BuddyReadWorkoutsCall({required this.name, required this.callId, required this.args});
  factory _BuddyReadWorkoutsCall.fromJson(Map<String, dynamic> json) => _$BuddyReadWorkoutsCallFromJson(json);

@override final  BuddyReadWorkoutsCallName name;
@override final  String callId;
@override final  BuddyReadWorkoutsArgs args;

/// Create a copy of BuddyReadWorkoutsCall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadWorkoutsCallCopyWith<_BuddyReadWorkoutsCall> get copyWith => __$BuddyReadWorkoutsCallCopyWithImpl<_BuddyReadWorkoutsCall>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadWorkoutsCallToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadWorkoutsCall&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.args, args) || other.args == args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,args);
}

@override
String toString() {
    return 'BuddyReadWorkoutsCall(name: $name, callId: $callId, args: $args)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadWorkoutsCallCopyWith<$Res> implements $BuddyReadWorkoutsCallCopyWith<$Res> {
  factory _$BuddyReadWorkoutsCallCopyWith(_BuddyReadWorkoutsCall value, $Res Function(_BuddyReadWorkoutsCall) _then) = __$BuddyReadWorkoutsCallCopyWithImpl;
@override @useResult
$Res call({
 BuddyReadWorkoutsCallName name, String callId, BuddyReadWorkoutsArgs args
});


@override $BuddyReadWorkoutsArgsCopyWith<$Res> get args;

}
/// @nodoc
class __$BuddyReadWorkoutsCallCopyWithImpl<$Res>
    implements _$BuddyReadWorkoutsCallCopyWith<$Res> {
  __$BuddyReadWorkoutsCallCopyWithImpl(this._self, this._then);

  final _BuddyReadWorkoutsCall _self;
  final $Res Function(_BuddyReadWorkoutsCall) _then;

/// Create a copy of BuddyReadWorkoutsCall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(_BuddyReadWorkoutsCall(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadWorkoutsCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyReadWorkoutsArgs,
  ));
}

/// Create a copy of BuddyReadWorkoutsCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadWorkoutsArgsCopyWith<$Res> get args {
  
  return $BuddyReadWorkoutsArgsCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}

// dart format on
