// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_label_text.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyLabelText {

 String? get value; BuddyLabelConfidence get confidence;
/// Create a copy of BuddyLabelText
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyLabelTextCopyWith<BuddyLabelText> get copyWith => _$BuddyLabelTextCopyWithImpl<BuddyLabelText>(this as BuddyLabelText, _$identity);

  /// Serializes this BuddyLabelText to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyLabelText;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyLabelText&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.confidence, _this.confidence) || other.confidence == _this.confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyLabelText;
  return Object.hash(runtimeType,_this.value,_this.confidence);
}

@override
String toString() {
  final _this = this as BuddyLabelText;
  return 'BuddyLabelText(value: ${_this.value}, confidence: ${_this.confidence})';
}


}

/// @nodoc
abstract mixin class $BuddyLabelTextCopyWith<$Res>  {
  factory $BuddyLabelTextCopyWith(BuddyLabelText value, $Res Function(BuddyLabelText) _then) = _$BuddyLabelTextCopyWithImpl;
@useResult
$Res call({
 String? value, BuddyLabelConfidence confidence
});




}
/// @nodoc
class _$BuddyLabelTextCopyWithImpl<$Res>
    implements $BuddyLabelTextCopyWith<$Res> {
  _$BuddyLabelTextCopyWithImpl(this._self, this._then);

  final BuddyLabelText _self;
  final $Res Function(BuddyLabelText) _then;

/// Create a copy of BuddyLabelText
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = freezed,Object? confidence = null,}) {
  return _then(BuddyLabelText(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as BuddyLabelConfidence,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyLabelText].
extension BuddyLabelTextPatterns on BuddyLabelText {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyLabelText value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyLabelText() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyLabelText value)  $default,){
final _that = this;
switch (_that) {
case _BuddyLabelText():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyLabelText value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyLabelText() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? value,  BuddyLabelConfidence confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyLabelText() when $default != null:
return $default(_that.value,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? value,  BuddyLabelConfidence confidence)  $default,) {final _that = this;
switch (_that) {
case _BuddyLabelText():
return $default(_that.value,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? value,  BuddyLabelConfidence confidence)?  $default,) {final _that = this;
switch (_that) {
case _BuddyLabelText() when $default != null:
return $default(_that.value,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyLabelText implements BuddyLabelText {
  const _BuddyLabelText({required this.value, required this.confidence});
  factory _BuddyLabelText.fromJson(Map<String, dynamic> json) => _$BuddyLabelTextFromJson(json);

@override final  String? value;
@override final  BuddyLabelConfidence confidence;

/// Create a copy of BuddyLabelText
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyLabelTextCopyWith<_BuddyLabelText> get copyWith => __$BuddyLabelTextCopyWithImpl<_BuddyLabelText>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyLabelTextToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyLabelText&&(identical(other.value, value) || other.value == value)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,value,confidence);
}

@override
String toString() {
    return 'BuddyLabelText(value: $value, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$BuddyLabelTextCopyWith<$Res> implements $BuddyLabelTextCopyWith<$Res> {
  factory _$BuddyLabelTextCopyWith(_BuddyLabelText value, $Res Function(_BuddyLabelText) _then) = __$BuddyLabelTextCopyWithImpl;
@override @useResult
$Res call({
 String? value, BuddyLabelConfidence confidence
});




}
/// @nodoc
class __$BuddyLabelTextCopyWithImpl<$Res>
    implements _$BuddyLabelTextCopyWith<$Res> {
  __$BuddyLabelTextCopyWithImpl(this._self, this._then);

  final _BuddyLabelText _self;
  final $Res Function(_BuddyLabelText) _then;

/// Create a copy of BuddyLabelText
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = freezed,Object? confidence = null,}) {
  return _then(_BuddyLabelText(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as BuddyLabelConfidence,
  ));
}


}

// dart format on
