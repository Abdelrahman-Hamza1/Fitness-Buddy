// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_memory_call.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadMemoryCall {

 BuddyReadMemoryCallName get name; String get callId; BuddyReadMemoryArgs get args;
/// Create a copy of BuddyReadMemoryCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadMemoryCallCopyWith<BuddyReadMemoryCall> get copyWith => _$BuddyReadMemoryCallCopyWithImpl<BuddyReadMemoryCall>(this as BuddyReadMemoryCall, _$identity);

  /// Serializes this BuddyReadMemoryCall to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadMemoryCall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadMemoryCall&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.callId, _this.callId) || other.callId == _this.callId)&&(identical(other.args, _this.args) || other.args == _this.args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadMemoryCall;
  return Object.hash(runtimeType,_this.name,_this.callId,_this.args);
}

@override
String toString() {
  final _this = this as BuddyReadMemoryCall;
  return 'BuddyReadMemoryCall(name: ${_this.name}, callId: ${_this.callId}, args: ${_this.args})';
}


}

/// @nodoc
abstract mixin class $BuddyReadMemoryCallCopyWith<$Res>  {
  factory $BuddyReadMemoryCallCopyWith(BuddyReadMemoryCall value, $Res Function(BuddyReadMemoryCall) _then) = _$BuddyReadMemoryCallCopyWithImpl;
@useResult
$Res call({
 BuddyReadMemoryCallName name, String callId, BuddyReadMemoryArgs args
});


$BuddyReadMemoryArgsCopyWith<$Res> get args;

}
/// @nodoc
class _$BuddyReadMemoryCallCopyWithImpl<$Res>
    implements $BuddyReadMemoryCallCopyWith<$Res> {
  _$BuddyReadMemoryCallCopyWithImpl(this._self, this._then);

  final BuddyReadMemoryCall _self;
  final $Res Function(BuddyReadMemoryCall) _then;

/// Create a copy of BuddyReadMemoryCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(BuddyReadMemoryCall(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadMemoryCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyReadMemoryArgs,
  ));
}
/// Create a copy of BuddyReadMemoryCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadMemoryArgsCopyWith<$Res> get args {
  
  return $BuddyReadMemoryArgsCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyReadMemoryCall].
extension BuddyReadMemoryCallPatterns on BuddyReadMemoryCall {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadMemoryCall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadMemoryCall() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadMemoryCall value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadMemoryCall():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadMemoryCall value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadMemoryCall() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyReadMemoryCallName name,  String callId,  BuddyReadMemoryArgs args)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadMemoryCall() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyReadMemoryCallName name,  String callId,  BuddyReadMemoryArgs args)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadMemoryCall():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyReadMemoryCallName name,  String callId,  BuddyReadMemoryArgs args)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadMemoryCall() when $default != null:
return $default(_that.name,_that.callId,_that.args);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadMemoryCall implements BuddyReadMemoryCall {
  const _BuddyReadMemoryCall({required this.name, required this.callId, required this.args});
  factory _BuddyReadMemoryCall.fromJson(Map<String, dynamic> json) => _$BuddyReadMemoryCallFromJson(json);

@override final  BuddyReadMemoryCallName name;
@override final  String callId;
@override final  BuddyReadMemoryArgs args;

/// Create a copy of BuddyReadMemoryCall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadMemoryCallCopyWith<_BuddyReadMemoryCall> get copyWith => __$BuddyReadMemoryCallCopyWithImpl<_BuddyReadMemoryCall>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadMemoryCallToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadMemoryCall&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.args, args) || other.args == args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,args);
}

@override
String toString() {
    return 'BuddyReadMemoryCall(name: $name, callId: $callId, args: $args)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadMemoryCallCopyWith<$Res> implements $BuddyReadMemoryCallCopyWith<$Res> {
  factory _$BuddyReadMemoryCallCopyWith(_BuddyReadMemoryCall value, $Res Function(_BuddyReadMemoryCall) _then) = __$BuddyReadMemoryCallCopyWithImpl;
@override @useResult
$Res call({
 BuddyReadMemoryCallName name, String callId, BuddyReadMemoryArgs args
});


@override $BuddyReadMemoryArgsCopyWith<$Res> get args;

}
/// @nodoc
class __$BuddyReadMemoryCallCopyWithImpl<$Res>
    implements _$BuddyReadMemoryCallCopyWith<$Res> {
  __$BuddyReadMemoryCallCopyWithImpl(this._self, this._then);

  final _BuddyReadMemoryCall _self;
  final $Res Function(_BuddyReadMemoryCall) _then;

/// Create a copy of BuddyReadMemoryCall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(_BuddyReadMemoryCall(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadMemoryCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyReadMemoryArgs,
  ));
}

/// Create a copy of BuddyReadMemoryCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadMemoryArgsCopyWith<$Res> get args {
  
  return $BuddyReadMemoryArgsCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}

// dart format on
