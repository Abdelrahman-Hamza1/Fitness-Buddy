// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_amount.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyAmount {

 double? get value; String? get unit; bool get explicit;
/// Create a copy of BuddyAmount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyAmountCopyWith<BuddyAmount> get copyWith => _$BuddyAmountCopyWithImpl<BuddyAmount>(this as BuddyAmount, _$identity);

  /// Serializes this BuddyAmount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyAmount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyAmount&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.explicit, _this.explicit) || other.explicit == _this.explicit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyAmount;
  return Object.hash(runtimeType,_this.value,_this.unit,_this.explicit);
}

@override
String toString() {
  final _this = this as BuddyAmount;
  return 'BuddyAmount(value: ${_this.value}, unit: ${_this.unit}, explicit: ${_this.explicit})';
}


}

/// @nodoc
abstract mixin class $BuddyAmountCopyWith<$Res>  {
  factory $BuddyAmountCopyWith(BuddyAmount value, $Res Function(BuddyAmount) _then) = _$BuddyAmountCopyWithImpl;
@useResult
$Res call({
 double? value, String? unit, bool explicit
});




}
/// @nodoc
class _$BuddyAmountCopyWithImpl<$Res>
    implements $BuddyAmountCopyWith<$Res> {
  _$BuddyAmountCopyWithImpl(this._self, this._then);

  final BuddyAmount _self;
  final $Res Function(BuddyAmount) _then;

/// Create a copy of BuddyAmount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = freezed,Object? unit = freezed,Object? explicit = null,}) {
  return _then(BuddyAmount(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,explicit: null == explicit ? _self.explicit : explicit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyAmount].
extension BuddyAmountPatterns on BuddyAmount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyAmount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyAmount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyAmount value)  $default,){
final _that = this;
switch (_that) {
case _BuddyAmount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyAmount value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyAmount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? value,  String? unit,  bool explicit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyAmount() when $default != null:
return $default(_that.value,_that.unit,_that.explicit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? value,  String? unit,  bool explicit)  $default,) {final _that = this;
switch (_that) {
case _BuddyAmount():
return $default(_that.value,_that.unit,_that.explicit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? value,  String? unit,  bool explicit)?  $default,) {final _that = this;
switch (_that) {
case _BuddyAmount() when $default != null:
return $default(_that.value,_that.unit,_that.explicit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyAmount implements BuddyAmount {
  const _BuddyAmount({required this.value, required this.unit, required this.explicit});
  factory _BuddyAmount.fromJson(Map<String, dynamic> json) => _$BuddyAmountFromJson(json);

@override final  double? value;
@override final  String? unit;
@override final  bool explicit;

/// Create a copy of BuddyAmount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyAmountCopyWith<_BuddyAmount> get copyWith => __$BuddyAmountCopyWithImpl<_BuddyAmount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyAmountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyAmount&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.explicit, explicit) || other.explicit == explicit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,value,unit,explicit);
}

@override
String toString() {
    return 'BuddyAmount(value: $value, unit: $unit, explicit: $explicit)';
}


}

/// @nodoc
abstract mixin class _$BuddyAmountCopyWith<$Res> implements $BuddyAmountCopyWith<$Res> {
  factory _$BuddyAmountCopyWith(_BuddyAmount value, $Res Function(_BuddyAmount) _then) = __$BuddyAmountCopyWithImpl;
@override @useResult
$Res call({
 double? value, String? unit, bool explicit
});




}
/// @nodoc
class __$BuddyAmountCopyWithImpl<$Res>
    implements _$BuddyAmountCopyWith<$Res> {
  __$BuddyAmountCopyWithImpl(this._self, this._then);

  final _BuddyAmount _self;
  final $Res Function(_BuddyAmount) _then;

/// Create a copy of BuddyAmount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = freezed,Object? unit = freezed,Object? explicit = null,}) {
  return _then(_BuddyAmount(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,explicit: null == explicit ? _self.explicit : explicit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
