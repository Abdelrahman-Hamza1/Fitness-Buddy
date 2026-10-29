// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_diary_patch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyDiaryPatch {

 BuddyAmount? get amount; BuddyFoodItem? get replacement; BuddyDayHint? get move;
/// Create a copy of BuddyDiaryPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyDiaryPatchCopyWith<BuddyDiaryPatch> get copyWith => _$BuddyDiaryPatchCopyWithImpl<BuddyDiaryPatch>(this as BuddyDiaryPatch, _$identity);

  /// Serializes this BuddyDiaryPatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyDiaryPatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyDiaryPatch&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.replacement, _this.replacement) || other.replacement == _this.replacement)&&(identical(other.move, _this.move) || other.move == _this.move));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyDiaryPatch;
  return Object.hash(runtimeType,_this.amount,_this.replacement,_this.move);
}

@override
String toString() {
  final _this = this as BuddyDiaryPatch;
  return 'BuddyDiaryPatch(amount: ${_this.amount}, replacement: ${_this.replacement}, move: ${_this.move})';
}


}

/// @nodoc
abstract mixin class $BuddyDiaryPatchCopyWith<$Res>  {
  factory $BuddyDiaryPatchCopyWith(BuddyDiaryPatch value, $Res Function(BuddyDiaryPatch) _then) = _$BuddyDiaryPatchCopyWithImpl;
@useResult
$Res call({
 BuddyAmount? amount, BuddyFoodItem? replacement, BuddyDayHint? move
});


$BuddyAmountCopyWith<$Res>? get amount;$BuddyFoodItemCopyWith<$Res>? get replacement;$BuddyDayHintCopyWith<$Res>? get move;

}
/// @nodoc
class _$BuddyDiaryPatchCopyWithImpl<$Res>
    implements $BuddyDiaryPatchCopyWith<$Res> {
  _$BuddyDiaryPatchCopyWithImpl(this._self, this._then);

  final BuddyDiaryPatch _self;
  final $Res Function(BuddyDiaryPatch) _then;

/// Create a copy of BuddyDiaryPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = freezed,Object? replacement = freezed,Object? move = freezed,}) {
  return _then(BuddyDiaryPatch(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BuddyAmount?,replacement: freezed == replacement ? _self.replacement : replacement // ignore: cast_nullable_to_non_nullable
as BuddyFoodItem?,move: freezed == move ? _self.move : move // ignore: cast_nullable_to_non_nullable
as BuddyDayHint?,
  ));
}
/// Create a copy of BuddyDiaryPatch
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
}/// Create a copy of BuddyDiaryPatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyFoodItemCopyWith<$Res>? get replacement {
    if (_self.replacement == null) {
    return null;
  }

  return $BuddyFoodItemCopyWith<$Res>(_self.replacement!, (value) {
    return _then(_self.copyWith(replacement: value));
  });
}/// Create a copy of BuddyDiaryPatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayHintCopyWith<$Res>? get move {
    if (_self.move == null) {
    return null;
  }

  return $BuddyDayHintCopyWith<$Res>(_self.move!, (value) {
    return _then(_self.copyWith(move: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyDiaryPatch].
extension BuddyDiaryPatchPatterns on BuddyDiaryPatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyDiaryPatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyDiaryPatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyDiaryPatch value)  $default,){
final _that = this;
switch (_that) {
case _BuddyDiaryPatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyDiaryPatch value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyDiaryPatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyAmount? amount,  BuddyFoodItem? replacement,  BuddyDayHint? move)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyDiaryPatch() when $default != null:
return $default(_that.amount,_that.replacement,_that.move);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyAmount? amount,  BuddyFoodItem? replacement,  BuddyDayHint? move)  $default,) {final _that = this;
switch (_that) {
case _BuddyDiaryPatch():
return $default(_that.amount,_that.replacement,_that.move);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyAmount? amount,  BuddyFoodItem? replacement,  BuddyDayHint? move)?  $default,) {final _that = this;
switch (_that) {
case _BuddyDiaryPatch() when $default != null:
return $default(_that.amount,_that.replacement,_that.move);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyDiaryPatch implements BuddyDiaryPatch {
  const _BuddyDiaryPatch({required this.amount, required this.replacement, required this.move});
  factory _BuddyDiaryPatch.fromJson(Map<String, dynamic> json) => _$BuddyDiaryPatchFromJson(json);

@override final  BuddyAmount? amount;
@override final  BuddyFoodItem? replacement;
@override final  BuddyDayHint? move;

/// Create a copy of BuddyDiaryPatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyDiaryPatchCopyWith<_BuddyDiaryPatch> get copyWith => __$BuddyDiaryPatchCopyWithImpl<_BuddyDiaryPatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyDiaryPatchToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyDiaryPatch&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.replacement, replacement) || other.replacement == replacement)&&(identical(other.move, move) || other.move == move));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,amount,replacement,move);
}

@override
String toString() {
    return 'BuddyDiaryPatch(amount: $amount, replacement: $replacement, move: $move)';
}


}

/// @nodoc
abstract mixin class _$BuddyDiaryPatchCopyWith<$Res> implements $BuddyDiaryPatchCopyWith<$Res> {
  factory _$BuddyDiaryPatchCopyWith(_BuddyDiaryPatch value, $Res Function(_BuddyDiaryPatch) _then) = __$BuddyDiaryPatchCopyWithImpl;
@override @useResult
$Res call({
 BuddyAmount? amount, BuddyFoodItem? replacement, BuddyDayHint? move
});


@override $BuddyAmountCopyWith<$Res>? get amount;@override $BuddyFoodItemCopyWith<$Res>? get replacement;@override $BuddyDayHintCopyWith<$Res>? get move;

}
/// @nodoc
class __$BuddyDiaryPatchCopyWithImpl<$Res>
    implements _$BuddyDiaryPatchCopyWith<$Res> {
  __$BuddyDiaryPatchCopyWithImpl(this._self, this._then);

  final _BuddyDiaryPatch _self;
  final $Res Function(_BuddyDiaryPatch) _then;

/// Create a copy of BuddyDiaryPatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = freezed,Object? replacement = freezed,Object? move = freezed,}) {
  return _then(_BuddyDiaryPatch(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BuddyAmount?,replacement: freezed == replacement ? _self.replacement : replacement // ignore: cast_nullable_to_non_nullable
as BuddyFoodItem?,move: freezed == move ? _self.move : move // ignore: cast_nullable_to_non_nullable
as BuddyDayHint?,
  ));
}

/// Create a copy of BuddyDiaryPatch
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
}/// Create a copy of BuddyDiaryPatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyFoodItemCopyWith<$Res>? get replacement {
    if (_self.replacement == null) {
    return null;
  }

  return $BuddyFoodItemCopyWith<$Res>(_self.replacement!, (value) {
    return _then(_self.copyWith(replacement: value));
  });
}/// Create a copy of BuddyDiaryPatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayHintCopyWith<$Res>? get move {
    if (_self.move == null) {
    return null;
  }

  return $BuddyDayHintCopyWith<$Res>(_self.move!, (value) {
    return _then(_self.copyWith(move: value));
  });
}
}

// dart format on
