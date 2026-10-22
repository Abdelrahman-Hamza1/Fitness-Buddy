// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_slot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddySlot {

 String get id; String get name; String? get window;
/// Create a copy of BuddySlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddySlotCopyWith<BuddySlot> get copyWith => _$BuddySlotCopyWithImpl<BuddySlot>(this as BuddySlot, _$identity);

  /// Serializes this BuddySlot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddySlot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddySlot&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.window, _this.window) || other.window == _this.window));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddySlot;
  return Object.hash(runtimeType,_this.id,_this.name,_this.window);
}

@override
String toString() {
  final _this = this as BuddySlot;
  return 'BuddySlot(id: ${_this.id}, name: ${_this.name}, window: ${_this.window})';
}


}

/// @nodoc
abstract mixin class $BuddySlotCopyWith<$Res>  {
  factory $BuddySlotCopyWith(BuddySlot value, $Res Function(BuddySlot) _then) = _$BuddySlotCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? window
});




}
/// @nodoc
class _$BuddySlotCopyWithImpl<$Res>
    implements $BuddySlotCopyWith<$Res> {
  _$BuddySlotCopyWithImpl(this._self, this._then);

  final BuddySlot _self;
  final $Res Function(BuddySlot) _then;

/// Create a copy of BuddySlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? window = freezed,}) {
  return _then(BuddySlot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,window: freezed == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddySlot].
extension BuddySlotPatterns on BuddySlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddySlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddySlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddySlot value)  $default,){
final _that = this;
switch (_that) {
case _BuddySlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddySlot value)?  $default,){
final _that = this;
switch (_that) {
case _BuddySlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? window)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddySlot() when $default != null:
return $default(_that.id,_that.name,_that.window);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? window)  $default,) {final _that = this;
switch (_that) {
case _BuddySlot():
return $default(_that.id,_that.name,_that.window);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? window)?  $default,) {final _that = this;
switch (_that) {
case _BuddySlot() when $default != null:
return $default(_that.id,_that.name,_that.window);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddySlot implements BuddySlot {
  const _BuddySlot({required this.id, required this.name, required this.window});
  factory _BuddySlot.fromJson(Map<String, dynamic> json) => _$BuddySlotFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? window;

/// Create a copy of BuddySlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddySlotCopyWith<_BuddySlot> get copyWith => __$BuddySlotCopyWithImpl<_BuddySlot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddySlotToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddySlot&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.window, window) || other.window == window));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,window);
}

@override
String toString() {
    return 'BuddySlot(id: $id, name: $name, window: $window)';
}


}

/// @nodoc
abstract mixin class _$BuddySlotCopyWith<$Res> implements $BuddySlotCopyWith<$Res> {
  factory _$BuddySlotCopyWith(_BuddySlot value, $Res Function(_BuddySlot) _then) = __$BuddySlotCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? window
});




}
/// @nodoc
class __$BuddySlotCopyWithImpl<$Res>
    implements _$BuddySlotCopyWith<$Res> {
  __$BuddySlotCopyWithImpl(this._self, this._then);

  final _BuddySlot _self;
  final $Res Function(_BuddySlot) _then;

/// Create a copy of BuddySlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? window = freezed,}) {
  return _then(_BuddySlot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,window: freezed == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
