// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_dimension_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyDimensionOption {

 String get value; String? get candidateKey; double? get amount; String? get unit; BuddyCandidate? get candidate;
/// Create a copy of BuddyDimensionOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyDimensionOptionCopyWith<BuddyDimensionOption> get copyWith => _$BuddyDimensionOptionCopyWithImpl<BuddyDimensionOption>(this as BuddyDimensionOption, _$identity);

  /// Serializes this BuddyDimensionOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyDimensionOption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyDimensionOption&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.candidateKey, _this.candidateKey) || other.candidateKey == _this.candidateKey)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.candidate, _this.candidate) || other.candidate == _this.candidate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyDimensionOption;
  return Object.hash(runtimeType,_this.value,_this.candidateKey,_this.amount,_this.unit,_this.candidate);
}

@override
String toString() {
  final _this = this as BuddyDimensionOption;
  return 'BuddyDimensionOption(value: ${_this.value}, candidateKey: ${_this.candidateKey}, amount: ${_this.amount}, unit: ${_this.unit}, candidate: ${_this.candidate})';
}


}

/// @nodoc
abstract mixin class $BuddyDimensionOptionCopyWith<$Res>  {
  factory $BuddyDimensionOptionCopyWith(BuddyDimensionOption value, $Res Function(BuddyDimensionOption) _then) = _$BuddyDimensionOptionCopyWithImpl;
@useResult
$Res call({
 String value, String? candidateKey, double? amount, String? unit, BuddyCandidate? candidate
});


$BuddyCandidateCopyWith<$Res>? get candidate;

}
/// @nodoc
class _$BuddyDimensionOptionCopyWithImpl<$Res>
    implements $BuddyDimensionOptionCopyWith<$Res> {
  _$BuddyDimensionOptionCopyWithImpl(this._self, this._then);

  final BuddyDimensionOption _self;
  final $Res Function(BuddyDimensionOption) _then;

/// Create a copy of BuddyDimensionOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? candidateKey = freezed,Object? amount = freezed,Object? unit = freezed,Object? candidate = freezed,}) {
  return _then(BuddyDimensionOption(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,candidateKey: freezed == candidateKey ? _self.candidateKey : candidateKey // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,candidate: freezed == candidate ? _self.candidate : candidate // ignore: cast_nullable_to_non_nullable
as BuddyCandidate?,
  ));
}
/// Create a copy of BuddyDimensionOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyCandidateCopyWith<$Res>? get candidate {
    if (_self.candidate == null) {
    return null;
  }

  return $BuddyCandidateCopyWith<$Res>(_self.candidate!, (value) {
    return _then(_self.copyWith(candidate: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyDimensionOption].
extension BuddyDimensionOptionPatterns on BuddyDimensionOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyDimensionOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyDimensionOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyDimensionOption value)  $default,){
final _that = this;
switch (_that) {
case _BuddyDimensionOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyDimensionOption value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyDimensionOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value,  String? candidateKey,  double? amount,  String? unit,  BuddyCandidate? candidate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyDimensionOption() when $default != null:
return $default(_that.value,_that.candidateKey,_that.amount,_that.unit,_that.candidate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value,  String? candidateKey,  double? amount,  String? unit,  BuddyCandidate? candidate)  $default,) {final _that = this;
switch (_that) {
case _BuddyDimensionOption():
return $default(_that.value,_that.candidateKey,_that.amount,_that.unit,_that.candidate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value,  String? candidateKey,  double? amount,  String? unit,  BuddyCandidate? candidate)?  $default,) {final _that = this;
switch (_that) {
case _BuddyDimensionOption() when $default != null:
return $default(_that.value,_that.candidateKey,_that.amount,_that.unit,_that.candidate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyDimensionOption implements BuddyDimensionOption {
  const _BuddyDimensionOption({required this.value, required this.candidateKey, required this.amount, required this.unit, required this.candidate});
  factory _BuddyDimensionOption.fromJson(Map<String, dynamic> json) => _$BuddyDimensionOptionFromJson(json);

@override final  String value;
@override final  String? candidateKey;
@override final  double? amount;
@override final  String? unit;
@override final  BuddyCandidate? candidate;

/// Create a copy of BuddyDimensionOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyDimensionOptionCopyWith<_BuddyDimensionOption> get copyWith => __$BuddyDimensionOptionCopyWithImpl<_BuddyDimensionOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyDimensionOptionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyDimensionOption&&(identical(other.value, value) || other.value == value)&&(identical(other.candidateKey, candidateKey) || other.candidateKey == candidateKey)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.candidate, candidate) || other.candidate == candidate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,value,candidateKey,amount,unit,candidate);
}

@override
String toString() {
    return 'BuddyDimensionOption(value: $value, candidateKey: $candidateKey, amount: $amount, unit: $unit, candidate: $candidate)';
}


}

/// @nodoc
abstract mixin class _$BuddyDimensionOptionCopyWith<$Res> implements $BuddyDimensionOptionCopyWith<$Res> {
  factory _$BuddyDimensionOptionCopyWith(_BuddyDimensionOption value, $Res Function(_BuddyDimensionOption) _then) = __$BuddyDimensionOptionCopyWithImpl;
@override @useResult
$Res call({
 String value, String? candidateKey, double? amount, String? unit, BuddyCandidate? candidate
});


@override $BuddyCandidateCopyWith<$Res>? get candidate;

}
/// @nodoc
class __$BuddyDimensionOptionCopyWithImpl<$Res>
    implements _$BuddyDimensionOptionCopyWith<$Res> {
  __$BuddyDimensionOptionCopyWithImpl(this._self, this._then);

  final _BuddyDimensionOption _self;
  final $Res Function(_BuddyDimensionOption) _then;

/// Create a copy of BuddyDimensionOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? candidateKey = freezed,Object? amount = freezed,Object? unit = freezed,Object? candidate = freezed,}) {
  return _then(_BuddyDimensionOption(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,candidateKey: freezed == candidateKey ? _self.candidateKey : candidateKey // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,candidate: freezed == candidate ? _self.candidate : candidate // ignore: cast_nullable_to_non_nullable
as BuddyCandidate?,
  ));
}

/// Create a copy of BuddyDimensionOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyCandidateCopyWith<$Res>? get candidate {
    if (_self.candidate == null) {
    return null;
  }

  return $BuddyCandidateCopyWith<$Res>(_self.candidate!, (value) {
    return _then(_self.copyWith(candidate: value));
  });
}
}

// dart format on
