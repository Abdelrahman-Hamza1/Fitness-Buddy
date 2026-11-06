// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_body_call.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadBodyCall {

 BuddyReadBodyCallName get name; String get callId; BuddyReadBodyArgs get args;
/// Create a copy of BuddyReadBodyCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadBodyCallCopyWith<BuddyReadBodyCall> get copyWith => _$BuddyReadBodyCallCopyWithImpl<BuddyReadBodyCall>(this as BuddyReadBodyCall, _$identity);

  /// Serializes this BuddyReadBodyCall to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadBodyCall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadBodyCall&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.callId, _this.callId) || other.callId == _this.callId)&&(identical(other.args, _this.args) || other.args == _this.args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadBodyCall;
  return Object.hash(runtimeType,_this.name,_this.callId,_this.args);
}

@override
String toString() {
  final _this = this as BuddyReadBodyCall;
  return 'BuddyReadBodyCall(name: ${_this.name}, callId: ${_this.callId}, args: ${_this.args})';
}


}

/// @nodoc
abstract mixin class $BuddyReadBodyCallCopyWith<$Res>  {
  factory $BuddyReadBodyCallCopyWith(BuddyReadBodyCall value, $Res Function(BuddyReadBodyCall) _then) = _$BuddyReadBodyCallCopyWithImpl;
@useResult
$Res call({
 BuddyReadBodyCallName name, String callId, BuddyReadBodyArgs args
});


$BuddyReadBodyArgsCopyWith<$Res> get args;

}
/// @nodoc
class _$BuddyReadBodyCallCopyWithImpl<$Res>
    implements $BuddyReadBodyCallCopyWith<$Res> {
  _$BuddyReadBodyCallCopyWithImpl(this._self, this._then);

  final BuddyReadBodyCall _self;
  final $Res Function(BuddyReadBodyCall) _then;

/// Create a copy of BuddyReadBodyCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(BuddyReadBodyCall(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadBodyCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyReadBodyArgs,
  ));
}
/// Create a copy of BuddyReadBodyCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadBodyArgsCopyWith<$Res> get args {
  
  return $BuddyReadBodyArgsCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyReadBodyCall].
extension BuddyReadBodyCallPatterns on BuddyReadBodyCall {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadBodyCall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadBodyCall() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadBodyCall value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadBodyCall():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadBodyCall value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadBodyCall() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyReadBodyCallName name,  String callId,  BuddyReadBodyArgs args)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadBodyCall() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyReadBodyCallName name,  String callId,  BuddyReadBodyArgs args)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadBodyCall():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyReadBodyCallName name,  String callId,  BuddyReadBodyArgs args)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadBodyCall() when $default != null:
return $default(_that.name,_that.callId,_that.args);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadBodyCall implements BuddyReadBodyCall {
  const _BuddyReadBodyCall({required this.name, required this.callId, required this.args});
  factory _BuddyReadBodyCall.fromJson(Map<String, dynamic> json) => _$BuddyReadBodyCallFromJson(json);

@override final  BuddyReadBodyCallName name;
@override final  String callId;
@override final  BuddyReadBodyArgs args;

/// Create a copy of BuddyReadBodyCall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadBodyCallCopyWith<_BuddyReadBodyCall> get copyWith => __$BuddyReadBodyCallCopyWithImpl<_BuddyReadBodyCall>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadBodyCallToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadBodyCall&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.args, args) || other.args == args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,args);
}

@override
String toString() {
    return 'BuddyReadBodyCall(name: $name, callId: $callId, args: $args)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadBodyCallCopyWith<$Res> implements $BuddyReadBodyCallCopyWith<$Res> {
  factory _$BuddyReadBodyCallCopyWith(_BuddyReadBodyCall value, $Res Function(_BuddyReadBodyCall) _then) = __$BuddyReadBodyCallCopyWithImpl;
@override @useResult
$Res call({
 BuddyReadBodyCallName name, String callId, BuddyReadBodyArgs args
});


@override $BuddyReadBodyArgsCopyWith<$Res> get args;

}
/// @nodoc
class __$BuddyReadBodyCallCopyWithImpl<$Res>
    implements _$BuddyReadBodyCallCopyWith<$Res> {
  __$BuddyReadBodyCallCopyWithImpl(this._self, this._then);

  final _BuddyReadBodyCall _self;
  final $Res Function(_BuddyReadBodyCall) _then;

/// Create a copy of BuddyReadBodyCall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(_BuddyReadBodyCall(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadBodyCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyReadBodyArgs,
  ));
}

/// Create a copy of BuddyReadBodyCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadBodyArgsCopyWith<$Res> get args {
  
  return $BuddyReadBodyArgsCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}

// dart format on
