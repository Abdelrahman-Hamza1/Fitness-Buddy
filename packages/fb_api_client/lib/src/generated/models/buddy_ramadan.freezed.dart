// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_ramadan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyRamadan {

 bool get active; String? get fajr; String? get maghrib;
/// Create a copy of BuddyRamadan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyRamadanCopyWith<BuddyRamadan> get copyWith => _$BuddyRamadanCopyWithImpl<BuddyRamadan>(this as BuddyRamadan, _$identity);

  /// Serializes this BuddyRamadan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyRamadan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyRamadan&&(identical(other.active, _this.active) || other.active == _this.active)&&(identical(other.fajr, _this.fajr) || other.fajr == _this.fajr)&&(identical(other.maghrib, _this.maghrib) || other.maghrib == _this.maghrib));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyRamadan;
  return Object.hash(runtimeType,_this.active,_this.fajr,_this.maghrib);
}

@override
String toString() {
  final _this = this as BuddyRamadan;
  return 'BuddyRamadan(active: ${_this.active}, fajr: ${_this.fajr}, maghrib: ${_this.maghrib})';
}


}

/// @nodoc
abstract mixin class $BuddyRamadanCopyWith<$Res>  {
  factory $BuddyRamadanCopyWith(BuddyRamadan value, $Res Function(BuddyRamadan) _then) = _$BuddyRamadanCopyWithImpl;
@useResult
$Res call({
 bool active, String? fajr, String? maghrib
});




}
/// @nodoc
class _$BuddyRamadanCopyWithImpl<$Res>
    implements $BuddyRamadanCopyWith<$Res> {
  _$BuddyRamadanCopyWithImpl(this._self, this._then);

  final BuddyRamadan _self;
  final $Res Function(BuddyRamadan) _then;

/// Create a copy of BuddyRamadan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? active = null,Object? fajr = freezed,Object? maghrib = freezed,}) {
  return _then(BuddyRamadan(
active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,fajr: freezed == fajr ? _self.fajr : fajr // ignore: cast_nullable_to_non_nullable
as String?,maghrib: freezed == maghrib ? _self.maghrib : maghrib // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyRamadan].
extension BuddyRamadanPatterns on BuddyRamadan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyRamadan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyRamadan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyRamadan value)  $default,){
final _that = this;
switch (_that) {
case _BuddyRamadan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyRamadan value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyRamadan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool active,  String? fajr,  String? maghrib)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyRamadan() when $default != null:
return $default(_that.active,_that.fajr,_that.maghrib);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool active,  String? fajr,  String? maghrib)  $default,) {final _that = this;
switch (_that) {
case _BuddyRamadan():
return $default(_that.active,_that.fajr,_that.maghrib);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool active,  String? fajr,  String? maghrib)?  $default,) {final _that = this;
switch (_that) {
case _BuddyRamadan() when $default != null:
return $default(_that.active,_that.fajr,_that.maghrib);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyRamadan implements BuddyRamadan {
  const _BuddyRamadan({required this.active, required this.fajr, required this.maghrib});
  factory _BuddyRamadan.fromJson(Map<String, dynamic> json) => _$BuddyRamadanFromJson(json);

@override final  bool active;
@override final  String? fajr;
@override final  String? maghrib;

/// Create a copy of BuddyRamadan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyRamadanCopyWith<_BuddyRamadan> get copyWith => __$BuddyRamadanCopyWithImpl<_BuddyRamadan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyRamadanToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyRamadan&&(identical(other.active, active) || other.active == active)&&(identical(other.fajr, fajr) || other.fajr == fajr)&&(identical(other.maghrib, maghrib) || other.maghrib == maghrib));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,active,fajr,maghrib);
}

@override
String toString() {
    return 'BuddyRamadan(active: $active, fajr: $fajr, maghrib: $maghrib)';
}


}

/// @nodoc
abstract mixin class _$BuddyRamadanCopyWith<$Res> implements $BuddyRamadanCopyWith<$Res> {
  factory _$BuddyRamadanCopyWith(_BuddyRamadan value, $Res Function(_BuddyRamadan) _then) = __$BuddyRamadanCopyWithImpl;
@override @useResult
$Res call({
 bool active, String? fajr, String? maghrib
});




}
/// @nodoc
class __$BuddyRamadanCopyWithImpl<$Res>
    implements _$BuddyRamadanCopyWith<$Res> {
  __$BuddyRamadanCopyWithImpl(this._self, this._then);

  final _BuddyRamadan _self;
  final $Res Function(_BuddyRamadan) _then;

/// Create a copy of BuddyRamadan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? active = null,Object? fajr = freezed,Object? maghrib = freezed,}) {
  return _then(_BuddyRamadan(
active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,fajr: freezed == fajr ? _self.fajr : fajr // ignore: cast_nullable_to_non_nullable
as String?,maghrib: freezed == maghrib ? _self.maghrib : maghrib // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
