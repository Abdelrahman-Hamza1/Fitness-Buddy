// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_active_card_line.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyActiveCardLine {

/// At most 200 characters.
 String get name;/// Greater than 0, or null.
 double? get amount;/// A unit code: g, ml or a serving unit (piece, loaf, plate, glass, sandwich, disc, serving, can, cup, tbsp, tsp).
 String? get unitCode;/// A FoodState code: raw, cooked, dry, drained, fried, as_sold.
 String? get state;
/// Create a copy of BuddyActiveCardLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyActiveCardLineCopyWith<BuddyActiveCardLine> get copyWith => _$BuddyActiveCardLineCopyWithImpl<BuddyActiveCardLine>(this as BuddyActiveCardLine, _$identity);

  /// Serializes this BuddyActiveCardLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyActiveCardLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyActiveCardLine&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.unitCode, _this.unitCode) || other.unitCode == _this.unitCode)&&(identical(other.state, _this.state) || other.state == _this.state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyActiveCardLine;
  return Object.hash(runtimeType,_this.name,_this.amount,_this.unitCode,_this.state);
}

@override
String toString() {
  final _this = this as BuddyActiveCardLine;
  return 'BuddyActiveCardLine(name: ${_this.name}, amount: ${_this.amount}, unitCode: ${_this.unitCode}, state: ${_this.state})';
}


}

/// @nodoc
abstract mixin class $BuddyActiveCardLineCopyWith<$Res>  {
  factory $BuddyActiveCardLineCopyWith(BuddyActiveCardLine value, $Res Function(BuddyActiveCardLine) _then) = _$BuddyActiveCardLineCopyWithImpl;
@useResult
$Res call({
 String name, double? amount, String? unitCode, String? state
});




}
/// @nodoc
class _$BuddyActiveCardLineCopyWithImpl<$Res>
    implements $BuddyActiveCardLineCopyWith<$Res> {
  _$BuddyActiveCardLineCopyWithImpl(this._self, this._then);

  final BuddyActiveCardLine _self;
  final $Res Function(BuddyActiveCardLine) _then;

/// Create a copy of BuddyActiveCardLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? amount = freezed,Object? unitCode = freezed,Object? state = freezed,}) {
  return _then(BuddyActiveCardLine(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,unitCode: freezed == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyActiveCardLine].
extension BuddyActiveCardLinePatterns on BuddyActiveCardLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyActiveCardLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyActiveCardLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyActiveCardLine value)  $default,){
final _that = this;
switch (_that) {
case _BuddyActiveCardLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyActiveCardLine value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyActiveCardLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  double? amount,  String? unitCode,  String? state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyActiveCardLine() when $default != null:
return $default(_that.name,_that.amount,_that.unitCode,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  double? amount,  String? unitCode,  String? state)  $default,) {final _that = this;
switch (_that) {
case _BuddyActiveCardLine():
return $default(_that.name,_that.amount,_that.unitCode,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  double? amount,  String? unitCode,  String? state)?  $default,) {final _that = this;
switch (_that) {
case _BuddyActiveCardLine() when $default != null:
return $default(_that.name,_that.amount,_that.unitCode,_that.state);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyActiveCardLine implements BuddyActiveCardLine {
  const _BuddyActiveCardLine({required this.name, required this.amount, required this.unitCode, required this.state});
  factory _BuddyActiveCardLine.fromJson(Map<String, dynamic> json) => _$BuddyActiveCardLineFromJson(json);

/// At most 200 characters.
@override final  String name;
/// Greater than 0, or null.
@override final  double? amount;
/// A unit code: g, ml or a serving unit (piece, loaf, plate, glass, sandwich, disc, serving, can, cup, tbsp, tsp).
@override final  String? unitCode;
/// A FoodState code: raw, cooked, dry, drained, fried, as_sold.
@override final  String? state;

/// Create a copy of BuddyActiveCardLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyActiveCardLineCopyWith<_BuddyActiveCardLine> get copyWith => __$BuddyActiveCardLineCopyWithImpl<_BuddyActiveCardLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyActiveCardLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyActiveCardLine&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unitCode, unitCode) || other.unitCode == unitCode)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,amount,unitCode,state);
}

@override
String toString() {
    return 'BuddyActiveCardLine(name: $name, amount: $amount, unitCode: $unitCode, state: $state)';
}


}

/// @nodoc
abstract mixin class _$BuddyActiveCardLineCopyWith<$Res> implements $BuddyActiveCardLineCopyWith<$Res> {
  factory _$BuddyActiveCardLineCopyWith(_BuddyActiveCardLine value, $Res Function(_BuddyActiveCardLine) _then) = __$BuddyActiveCardLineCopyWithImpl;
@override @useResult
$Res call({
 String name, double? amount, String? unitCode, String? state
});




}
/// @nodoc
class __$BuddyActiveCardLineCopyWithImpl<$Res>
    implements _$BuddyActiveCardLineCopyWith<$Res> {
  __$BuddyActiveCardLineCopyWithImpl(this._self, this._then);

  final _BuddyActiveCardLine _self;
  final $Res Function(_BuddyActiveCardLine) _then;

/// Create a copy of BuddyActiveCardLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? amount = freezed,Object? unitCode = freezed,Object? state = freezed,}) {
  return _then(_BuddyActiveCardLine(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,unitCode: freezed == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
