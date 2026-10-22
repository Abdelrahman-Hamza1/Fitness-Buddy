// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_dimension.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyDimension {

 String get kind; String? get statedValue; List<BuddyDimensionOption> get options;
/// Create a copy of BuddyDimension
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyDimensionCopyWith<BuddyDimension> get copyWith => _$BuddyDimensionCopyWithImpl<BuddyDimension>(this as BuddyDimension, _$identity);

  /// Serializes this BuddyDimension to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyDimension;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyDimension&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.statedValue, _this.statedValue) || other.statedValue == _this.statedValue)&&const DeepCollectionEquality().equals(other.options, _this.options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyDimension;
  return Object.hash(runtimeType,_this.kind,_this.statedValue,const DeepCollectionEquality().hash(_this.options));
}

@override
String toString() {
  final _this = this as BuddyDimension;
  return 'BuddyDimension(kind: ${_this.kind}, statedValue: ${_this.statedValue}, options: ${_this.options})';
}


}

/// @nodoc
abstract mixin class $BuddyDimensionCopyWith<$Res>  {
  factory $BuddyDimensionCopyWith(BuddyDimension value, $Res Function(BuddyDimension) _then) = _$BuddyDimensionCopyWithImpl;
@useResult
$Res call({
 String kind, String? statedValue, List<BuddyDimensionOption> options
});




}
/// @nodoc
class _$BuddyDimensionCopyWithImpl<$Res>
    implements $BuddyDimensionCopyWith<$Res> {
  _$BuddyDimensionCopyWithImpl(this._self, this._then);

  final BuddyDimension _self;
  final $Res Function(BuddyDimension) _then;

/// Create a copy of BuddyDimension
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? statedValue = freezed,Object? options = null,}) {
  return _then(BuddyDimension(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,statedValue: freezed == statedValue ? _self.statedValue : statedValue // ignore: cast_nullable_to_non_nullable
as String?,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<BuddyDimensionOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyDimension].
extension BuddyDimensionPatterns on BuddyDimension {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyDimension value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyDimension() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyDimension value)  $default,){
final _that = this;
switch (_that) {
case _BuddyDimension():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyDimension value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyDimension() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String? statedValue,  List<BuddyDimensionOption> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyDimension() when $default != null:
return $default(_that.kind,_that.statedValue,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String? statedValue,  List<BuddyDimensionOption> options)  $default,) {final _that = this;
switch (_that) {
case _BuddyDimension():
return $default(_that.kind,_that.statedValue,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String? statedValue,  List<BuddyDimensionOption> options)?  $default,) {final _that = this;
switch (_that) {
case _BuddyDimension() when $default != null:
return $default(_that.kind,_that.statedValue,_that.options);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyDimension implements BuddyDimension {
  const _BuddyDimension({required this.kind, required this.statedValue, required  List<BuddyDimensionOption> options}): _options = options;
  factory _BuddyDimension.fromJson(Map<String, dynamic> json) => _$BuddyDimensionFromJson(json);

@override final  String kind;
@override final  String? statedValue;
 final  List<BuddyDimensionOption> _options;
@override List<BuddyDimensionOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of BuddyDimension
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyDimensionCopyWith<_BuddyDimension> get copyWith => __$BuddyDimensionCopyWithImpl<_BuddyDimension>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyDimensionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyDimension&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.statedValue, statedValue) || other.statedValue == statedValue)&&const DeepCollectionEquality().equals(other.options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,statedValue,const DeepCollectionEquality().hash(_options));
}

@override
String toString() {
    return 'BuddyDimension(kind: $kind, statedValue: $statedValue, options: $options)';
}


}

/// @nodoc
abstract mixin class _$BuddyDimensionCopyWith<$Res> implements $BuddyDimensionCopyWith<$Res> {
  factory _$BuddyDimensionCopyWith(_BuddyDimension value, $Res Function(_BuddyDimension) _then) = __$BuddyDimensionCopyWithImpl;
@override @useResult
$Res call({
 String kind, String? statedValue, List<BuddyDimensionOption> options
});




}
/// @nodoc
class __$BuddyDimensionCopyWithImpl<$Res>
    implements _$BuddyDimensionCopyWith<$Res> {
  __$BuddyDimensionCopyWithImpl(this._self, this._then);

  final _BuddyDimension _self;
  final $Res Function(_BuddyDimension) _then;

/// Create a copy of BuddyDimension
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? statedValue = freezed,Object? options = null,}) {
  return _then(_BuddyDimension(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,statedValue: freezed == statedValue ? _self.statedValue : statedValue // ignore: cast_nullable_to_non_nullable
as String?,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<BuddyDimensionOption>,
  ));
}


}

// dart format on
