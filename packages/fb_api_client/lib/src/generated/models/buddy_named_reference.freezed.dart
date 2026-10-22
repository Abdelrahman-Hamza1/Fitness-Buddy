// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_named_reference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyNamedReference {

 String get id; String get name;
/// Create a copy of BuddyNamedReference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyNamedReferenceCopyWith<BuddyNamedReference> get copyWith => _$BuddyNamedReferenceCopyWithImpl<BuddyNamedReference>(this as BuddyNamedReference, _$identity);

  /// Serializes this BuddyNamedReference to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyNamedReference;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyNamedReference&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyNamedReference;
  return Object.hash(runtimeType,_this.id,_this.name);
}

@override
String toString() {
  final _this = this as BuddyNamedReference;
  return 'BuddyNamedReference(id: ${_this.id}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $BuddyNamedReferenceCopyWith<$Res>  {
  factory $BuddyNamedReferenceCopyWith(BuddyNamedReference value, $Res Function(BuddyNamedReference) _then) = _$BuddyNamedReferenceCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$BuddyNamedReferenceCopyWithImpl<$Res>
    implements $BuddyNamedReferenceCopyWith<$Res> {
  _$BuddyNamedReferenceCopyWithImpl(this._self, this._then);

  final BuddyNamedReference _self;
  final $Res Function(BuddyNamedReference) _then;

/// Create a copy of BuddyNamedReference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(BuddyNamedReference(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyNamedReference].
extension BuddyNamedReferencePatterns on BuddyNamedReference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyNamedReference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyNamedReference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyNamedReference value)  $default,){
final _that = this;
switch (_that) {
case _BuddyNamedReference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyNamedReference value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyNamedReference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyNamedReference() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _BuddyNamedReference():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _BuddyNamedReference() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyNamedReference implements BuddyNamedReference {
  const _BuddyNamedReference({required this.id, required this.name});
  factory _BuddyNamedReference.fromJson(Map<String, dynamic> json) => _$BuddyNamedReferenceFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of BuddyNamedReference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyNamedReferenceCopyWith<_BuddyNamedReference> get copyWith => __$BuddyNamedReferenceCopyWithImpl<_BuddyNamedReference>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyNamedReferenceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyNamedReference&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name);
}

@override
String toString() {
    return 'BuddyNamedReference(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$BuddyNamedReferenceCopyWith<$Res> implements $BuddyNamedReferenceCopyWith<$Res> {
  factory _$BuddyNamedReferenceCopyWith(_BuddyNamedReference value, $Res Function(_BuddyNamedReference) _then) = __$BuddyNamedReferenceCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$BuddyNamedReferenceCopyWithImpl<$Res>
    implements _$BuddyNamedReferenceCopyWith<$Res> {
  __$BuddyNamedReferenceCopyWithImpl(this._self, this._then);

  final _BuddyNamedReference _self;
  final $Res Function(_BuddyNamedReference) _then;

/// Create a copy of BuddyNamedReference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_BuddyNamedReference(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
