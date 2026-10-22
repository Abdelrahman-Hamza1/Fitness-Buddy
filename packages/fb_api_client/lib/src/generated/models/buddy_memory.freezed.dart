// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_memory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyMemory {

 String get kind; String get key; String get value;
/// Create a copy of BuddyMemory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyMemoryCopyWith<BuddyMemory> get copyWith => _$BuddyMemoryCopyWithImpl<BuddyMemory>(this as BuddyMemory, _$identity);

  /// Serializes this BuddyMemory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyMemory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyMemory&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.value, _this.value) || other.value == _this.value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyMemory;
  return Object.hash(runtimeType,_this.kind,_this.key,_this.value);
}

@override
String toString() {
  final _this = this as BuddyMemory;
  return 'BuddyMemory(kind: ${_this.kind}, key: ${_this.key}, value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $BuddyMemoryCopyWith<$Res>  {
  factory $BuddyMemoryCopyWith(BuddyMemory value, $Res Function(BuddyMemory) _then) = _$BuddyMemoryCopyWithImpl;
@useResult
$Res call({
 String kind, String key, String value
});




}
/// @nodoc
class _$BuddyMemoryCopyWithImpl<$Res>
    implements $BuddyMemoryCopyWith<$Res> {
  _$BuddyMemoryCopyWithImpl(this._self, this._then);

  final BuddyMemory _self;
  final $Res Function(BuddyMemory) _then;

/// Create a copy of BuddyMemory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? key = null,Object? value = null,}) {
  return _then(BuddyMemory(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyMemory].
extension BuddyMemoryPatterns on BuddyMemory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyMemory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyMemory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyMemory value)  $default,){
final _that = this;
switch (_that) {
case _BuddyMemory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyMemory value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyMemory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String key,  String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyMemory() when $default != null:
return $default(_that.kind,_that.key,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String key,  String value)  $default,) {final _that = this;
switch (_that) {
case _BuddyMemory():
return $default(_that.kind,_that.key,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String key,  String value)?  $default,) {final _that = this;
switch (_that) {
case _BuddyMemory() when $default != null:
return $default(_that.kind,_that.key,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyMemory implements BuddyMemory {
  const _BuddyMemory({required this.kind, required this.key, required this.value});
  factory _BuddyMemory.fromJson(Map<String, dynamic> json) => _$BuddyMemoryFromJson(json);

@override final  String kind;
@override final  String key;
@override final  String value;

/// Create a copy of BuddyMemory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyMemoryCopyWith<_BuddyMemory> get copyWith => __$BuddyMemoryCopyWithImpl<_BuddyMemory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyMemoryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyMemory&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,key,value);
}

@override
String toString() {
    return 'BuddyMemory(kind: $kind, key: $key, value: $value)';
}


}

/// @nodoc
abstract mixin class _$BuddyMemoryCopyWith<$Res> implements $BuddyMemoryCopyWith<$Res> {
  factory _$BuddyMemoryCopyWith(_BuddyMemory value, $Res Function(_BuddyMemory) _then) = __$BuddyMemoryCopyWithImpl;
@override @useResult
$Res call({
 String kind, String key, String value
});




}
/// @nodoc
class __$BuddyMemoryCopyWithImpl<$Res>
    implements _$BuddyMemoryCopyWith<$Res> {
  __$BuddyMemoryCopyWithImpl(this._self, this._then);

  final _BuddyMemory _self;
  final $Res Function(_BuddyMemory) _then;

/// Create a copy of BuddyMemory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? key = null,Object? value = null,}) {
  return _then(_BuddyMemory(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
