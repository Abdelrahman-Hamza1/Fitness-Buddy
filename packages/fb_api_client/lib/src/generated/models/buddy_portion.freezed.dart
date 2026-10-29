// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_portion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyPortion {

 BuddyAmount? get amount; BuddyShare? get share;
/// Create a copy of BuddyPortion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPortionCopyWith<BuddyPortion> get copyWith => _$BuddyPortionCopyWithImpl<BuddyPortion>(this as BuddyPortion, _$identity);

  /// Serializes this BuddyPortion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyPortion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPortion&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.share, _this.share) || other.share == _this.share));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyPortion;
  return Object.hash(runtimeType,_this.amount,_this.share);
}

@override
String toString() {
  final _this = this as BuddyPortion;
  return 'BuddyPortion(amount: ${_this.amount}, share: ${_this.share})';
}


}

/// @nodoc
abstract mixin class $BuddyPortionCopyWith<$Res>  {
  factory $BuddyPortionCopyWith(BuddyPortion value, $Res Function(BuddyPortion) _then) = _$BuddyPortionCopyWithImpl;
@useResult
$Res call({
 BuddyAmount? amount, BuddyShare? share
});


$BuddyAmountCopyWith<$Res>? get amount;$BuddyShareCopyWith<$Res>? get share;

}
/// @nodoc
class _$BuddyPortionCopyWithImpl<$Res>
    implements $BuddyPortionCopyWith<$Res> {
  _$BuddyPortionCopyWithImpl(this._self, this._then);

  final BuddyPortion _self;
  final $Res Function(BuddyPortion) _then;

/// Create a copy of BuddyPortion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = freezed,Object? share = freezed,}) {
  return _then(BuddyPortion(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BuddyAmount?,share: freezed == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as BuddyShare?,
  ));
}
/// Create a copy of BuddyPortion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyAmountCopyWith<$Res>? get amount {
    if (_self.amount == null) {
    return null;
  }

  return $BuddyAmountCopyWith<$Res>(_self.amount!, (value) {
    return _then(_self.copyWith(amount: value));
  });
}/// Create a copy of BuddyPortion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyShareCopyWith<$Res>? get share {
    if (_self.share == null) {
    return null;
  }

  return $BuddyShareCopyWith<$Res>(_self.share!, (value) {
    return _then(_self.copyWith(share: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyPortion].
extension BuddyPortionPatterns on BuddyPortion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyPortion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyPortion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyPortion value)  $default,){
final _that = this;
switch (_that) {
case _BuddyPortion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyPortion value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyPortion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyAmount? amount,  BuddyShare? share)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyPortion() when $default != null:
return $default(_that.amount,_that.share);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyAmount? amount,  BuddyShare? share)  $default,) {final _that = this;
switch (_that) {
case _BuddyPortion():
return $default(_that.amount,_that.share);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyAmount? amount,  BuddyShare? share)?  $default,) {final _that = this;
switch (_that) {
case _BuddyPortion() when $default != null:
return $default(_that.amount,_that.share);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyPortion implements BuddyPortion {
  const _BuddyPortion({required this.amount, required this.share});
  factory _BuddyPortion.fromJson(Map<String, dynamic> json) => _$BuddyPortionFromJson(json);

@override final  BuddyAmount? amount;
@override final  BuddyShare? share;

/// Create a copy of BuddyPortion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyPortionCopyWith<_BuddyPortion> get copyWith => __$BuddyPortionCopyWithImpl<_BuddyPortion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPortionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyPortion&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.share, share) || other.share == share));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,amount,share);
}

@override
String toString() {
    return 'BuddyPortion(amount: $amount, share: $share)';
}


}

/// @nodoc
abstract mixin class _$BuddyPortionCopyWith<$Res> implements $BuddyPortionCopyWith<$Res> {
  factory _$BuddyPortionCopyWith(_BuddyPortion value, $Res Function(_BuddyPortion) _then) = __$BuddyPortionCopyWithImpl;
@override @useResult
$Res call({
 BuddyAmount? amount, BuddyShare? share
});


@override $BuddyAmountCopyWith<$Res>? get amount;@override $BuddyShareCopyWith<$Res>? get share;

}
/// @nodoc
class __$BuddyPortionCopyWithImpl<$Res>
    implements _$BuddyPortionCopyWith<$Res> {
  __$BuddyPortionCopyWithImpl(this._self, this._then);

  final _BuddyPortion _self;
  final $Res Function(_BuddyPortion) _then;

/// Create a copy of BuddyPortion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = freezed,Object? share = freezed,}) {
  return _then(_BuddyPortion(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BuddyAmount?,share: freezed == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as BuddyShare?,
  ));
}

/// Create a copy of BuddyPortion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyAmountCopyWith<$Res>? get amount {
    if (_self.amount == null) {
    return null;
  }

  return $BuddyAmountCopyWith<$Res>(_self.amount!, (value) {
    return _then(_self.copyWith(amount: value));
  });
}/// Create a copy of BuddyPortion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyShareCopyWith<$Res>? get share {
    if (_self.share == null) {
    return null;
  }

  return $BuddyShareCopyWith<$Res>(_self.share!, (value) {
    return _then(_self.copyWith(share: value));
  });
}
}

// dart format on
