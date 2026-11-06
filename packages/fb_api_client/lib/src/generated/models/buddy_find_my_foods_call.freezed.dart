// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_find_my_foods_call.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyFindMyFoodsCall {

 BuddyFindMyFoodsCallName get name; String get callId; BuddyFindMyFoodsArgs get args;
/// Create a copy of BuddyFindMyFoodsCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyFindMyFoodsCallCopyWith<BuddyFindMyFoodsCall> get copyWith => _$BuddyFindMyFoodsCallCopyWithImpl<BuddyFindMyFoodsCall>(this as BuddyFindMyFoodsCall, _$identity);

  /// Serializes this BuddyFindMyFoodsCall to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyFindMyFoodsCall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyFindMyFoodsCall&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.callId, _this.callId) || other.callId == _this.callId)&&(identical(other.args, _this.args) || other.args == _this.args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyFindMyFoodsCall;
  return Object.hash(runtimeType,_this.name,_this.callId,_this.args);
}

@override
String toString() {
  final _this = this as BuddyFindMyFoodsCall;
  return 'BuddyFindMyFoodsCall(name: ${_this.name}, callId: ${_this.callId}, args: ${_this.args})';
}


}

/// @nodoc
abstract mixin class $BuddyFindMyFoodsCallCopyWith<$Res>  {
  factory $BuddyFindMyFoodsCallCopyWith(BuddyFindMyFoodsCall value, $Res Function(BuddyFindMyFoodsCall) _then) = _$BuddyFindMyFoodsCallCopyWithImpl;
@useResult
$Res call({
 BuddyFindMyFoodsCallName name, String callId, BuddyFindMyFoodsArgs args
});


$BuddyFindMyFoodsArgsCopyWith<$Res> get args;

}
/// @nodoc
class _$BuddyFindMyFoodsCallCopyWithImpl<$Res>
    implements $BuddyFindMyFoodsCallCopyWith<$Res> {
  _$BuddyFindMyFoodsCallCopyWithImpl(this._self, this._then);

  final BuddyFindMyFoodsCall _self;
  final $Res Function(BuddyFindMyFoodsCall) _then;

/// Create a copy of BuddyFindMyFoodsCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(BuddyFindMyFoodsCall(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyFindMyFoodsCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyFindMyFoodsArgs,
  ));
}
/// Create a copy of BuddyFindMyFoodsCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyFindMyFoodsArgsCopyWith<$Res> get args {
  
  return $BuddyFindMyFoodsArgsCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyFindMyFoodsCall].
extension BuddyFindMyFoodsCallPatterns on BuddyFindMyFoodsCall {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyFindMyFoodsCall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyFindMyFoodsCall() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyFindMyFoodsCall value)  $default,){
final _that = this;
switch (_that) {
case _BuddyFindMyFoodsCall():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyFindMyFoodsCall value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyFindMyFoodsCall() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyFindMyFoodsCallName name,  String callId,  BuddyFindMyFoodsArgs args)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyFindMyFoodsCall() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyFindMyFoodsCallName name,  String callId,  BuddyFindMyFoodsArgs args)  $default,) {final _that = this;
switch (_that) {
case _BuddyFindMyFoodsCall():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyFindMyFoodsCallName name,  String callId,  BuddyFindMyFoodsArgs args)?  $default,) {final _that = this;
switch (_that) {
case _BuddyFindMyFoodsCall() when $default != null:
return $default(_that.name,_that.callId,_that.args);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyFindMyFoodsCall implements BuddyFindMyFoodsCall {
  const _BuddyFindMyFoodsCall({required this.name, required this.callId, required this.args});
  factory _BuddyFindMyFoodsCall.fromJson(Map<String, dynamic> json) => _$BuddyFindMyFoodsCallFromJson(json);

@override final  BuddyFindMyFoodsCallName name;
@override final  String callId;
@override final  BuddyFindMyFoodsArgs args;

/// Create a copy of BuddyFindMyFoodsCall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyFindMyFoodsCallCopyWith<_BuddyFindMyFoodsCall> get copyWith => __$BuddyFindMyFoodsCallCopyWithImpl<_BuddyFindMyFoodsCall>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyFindMyFoodsCallToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyFindMyFoodsCall&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.args, args) || other.args == args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,args);
}

@override
String toString() {
    return 'BuddyFindMyFoodsCall(name: $name, callId: $callId, args: $args)';
}


}

/// @nodoc
abstract mixin class _$BuddyFindMyFoodsCallCopyWith<$Res> implements $BuddyFindMyFoodsCallCopyWith<$Res> {
  factory _$BuddyFindMyFoodsCallCopyWith(_BuddyFindMyFoodsCall value, $Res Function(_BuddyFindMyFoodsCall) _then) = __$BuddyFindMyFoodsCallCopyWithImpl;
@override @useResult
$Res call({
 BuddyFindMyFoodsCallName name, String callId, BuddyFindMyFoodsArgs args
});


@override $BuddyFindMyFoodsArgsCopyWith<$Res> get args;

}
/// @nodoc
class __$BuddyFindMyFoodsCallCopyWithImpl<$Res>
    implements _$BuddyFindMyFoodsCallCopyWith<$Res> {
  __$BuddyFindMyFoodsCallCopyWithImpl(this._self, this._then);

  final _BuddyFindMyFoodsCall _self;
  final $Res Function(_BuddyFindMyFoodsCall) _then;

/// Create a copy of BuddyFindMyFoodsCall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(_BuddyFindMyFoodsCall(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyFindMyFoodsCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyFindMyFoodsArgs,
  ));
}

/// Create a copy of BuddyFindMyFoodsCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyFindMyFoodsArgsCopyWith<$Res> get args {
  
  return $BuddyFindMyFoodsArgsCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}

// dart format on
