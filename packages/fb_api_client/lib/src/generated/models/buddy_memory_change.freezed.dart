// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_memory_change.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyMemoryChange {

 BuddyMemoryChangeKind get kind; String get language; String get script; BuddyMemoryOperation get operation; BuddyMemoryKind get memoryKind;/// The food or name the statement is about, as the user said it.
 String? get subject; BuddyMemoryDimension? get dimension;/// Closed for state (raw, cooked, dry, drained, fried) and fat (none, oil); literal otherwise (alias, brand, nickname, variant).
 String? get value;/// The portion, or the fat quantity. Authoritative; food.amount is ignored.
 BuddyAmount? get amount;/// The subject food when it matches a real food; never an estimate.
 BuddyFoodItem? get food;
/// Create a copy of BuddyMemoryChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyMemoryChangeCopyWith<BuddyMemoryChange> get copyWith => _$BuddyMemoryChangeCopyWithImpl<BuddyMemoryChange>(this as BuddyMemoryChange, _$identity);

  /// Serializes this BuddyMemoryChange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyMemoryChange;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyMemoryChange&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.operation, _this.operation) || other.operation == _this.operation)&&(identical(other.memoryKind, _this.memoryKind) || other.memoryKind == _this.memoryKind)&&(identical(other.subject, _this.subject) || other.subject == _this.subject)&&(identical(other.dimension, _this.dimension) || other.dimension == _this.dimension)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.food, _this.food) || other.food == _this.food));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyMemoryChange;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.operation,_this.memoryKind,_this.subject,_this.dimension,_this.value,_this.amount,_this.food);
}

@override
String toString() {
  final _this = this as BuddyMemoryChange;
  return 'BuddyMemoryChange(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, operation: ${_this.operation}, memoryKind: ${_this.memoryKind}, subject: ${_this.subject}, dimension: ${_this.dimension}, value: ${_this.value}, amount: ${_this.amount}, food: ${_this.food})';
}


}

/// @nodoc
abstract mixin class $BuddyMemoryChangeCopyWith<$Res>  {
  factory $BuddyMemoryChangeCopyWith(BuddyMemoryChange value, $Res Function(BuddyMemoryChange) _then) = _$BuddyMemoryChangeCopyWithImpl;
@useResult
$Res call({
 BuddyMemoryChangeKind kind, String language, String script, BuddyMemoryOperation operation, BuddyMemoryKind memoryKind, String? subject, BuddyMemoryDimension? dimension, String? value, BuddyAmount? amount, BuddyFoodItem? food
});


$BuddyAmountCopyWith<$Res>? get amount;$BuddyFoodItemCopyWith<$Res>? get food;

}
/// @nodoc
class _$BuddyMemoryChangeCopyWithImpl<$Res>
    implements $BuddyMemoryChangeCopyWith<$Res> {
  _$BuddyMemoryChangeCopyWithImpl(this._self, this._then);

  final BuddyMemoryChange _self;
  final $Res Function(BuddyMemoryChange) _then;

/// Create a copy of BuddyMemoryChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? operation = null,Object? memoryKind = null,Object? subject = freezed,Object? dimension = freezed,Object? value = freezed,Object? amount = freezed,Object? food = freezed,}) {
  return _then(BuddyMemoryChange(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyMemoryChangeKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as BuddyMemoryOperation,memoryKind: null == memoryKind ? _self.memoryKind : memoryKind // ignore: cast_nullable_to_non_nullable
as BuddyMemoryKind,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,dimension: freezed == dimension ? _self.dimension : dimension // ignore: cast_nullable_to_non_nullable
as BuddyMemoryDimension?,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BuddyAmount?,food: freezed == food ? _self.food : food // ignore: cast_nullable_to_non_nullable
as BuddyFoodItem?,
  ));
}
/// Create a copy of BuddyMemoryChange
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
}/// Create a copy of BuddyMemoryChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyFoodItemCopyWith<$Res>? get food {
    if (_self.food == null) {
    return null;
  }

  return $BuddyFoodItemCopyWith<$Res>(_self.food!, (value) {
    return _then(_self.copyWith(food: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyMemoryChange].
extension BuddyMemoryChangePatterns on BuddyMemoryChange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyMemoryChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyMemoryChange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyMemoryChange value)  $default,){
final _that = this;
switch (_that) {
case _BuddyMemoryChange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyMemoryChange value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyMemoryChange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyMemoryChangeKind kind,  String language,  String script,  BuddyMemoryOperation operation,  BuddyMemoryKind memoryKind,  String? subject,  BuddyMemoryDimension? dimension,  String? value,  BuddyAmount? amount,  BuddyFoodItem? food)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyMemoryChange() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.operation,_that.memoryKind,_that.subject,_that.dimension,_that.value,_that.amount,_that.food);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyMemoryChangeKind kind,  String language,  String script,  BuddyMemoryOperation operation,  BuddyMemoryKind memoryKind,  String? subject,  BuddyMemoryDimension? dimension,  String? value,  BuddyAmount? amount,  BuddyFoodItem? food)  $default,) {final _that = this;
switch (_that) {
case _BuddyMemoryChange():
return $default(_that.kind,_that.language,_that.script,_that.operation,_that.memoryKind,_that.subject,_that.dimension,_that.value,_that.amount,_that.food);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyMemoryChangeKind kind,  String language,  String script,  BuddyMemoryOperation operation,  BuddyMemoryKind memoryKind,  String? subject,  BuddyMemoryDimension? dimension,  String? value,  BuddyAmount? amount,  BuddyFoodItem? food)?  $default,) {final _that = this;
switch (_that) {
case _BuddyMemoryChange() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.operation,_that.memoryKind,_that.subject,_that.dimension,_that.value,_that.amount,_that.food);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyMemoryChange implements BuddyMemoryChange {
  const _BuddyMemoryChange({required this.kind, required this.language, required this.script, required this.operation, required this.memoryKind, required this.subject, required this.dimension, required this.value, required this.amount, required this.food});
  factory _BuddyMemoryChange.fromJson(Map<String, dynamic> json) => _$BuddyMemoryChangeFromJson(json);

@override final  BuddyMemoryChangeKind kind;
@override final  String language;
@override final  String script;
@override final  BuddyMemoryOperation operation;
@override final  BuddyMemoryKind memoryKind;
/// The food or name the statement is about, as the user said it.
@override final  String? subject;
@override final  BuddyMemoryDimension? dimension;
/// Closed for state (raw, cooked, dry, drained, fried) and fat (none, oil); literal otherwise (alias, brand, nickname, variant).
@override final  String? value;
/// The portion, or the fat quantity. Authoritative; food.amount is ignored.
@override final  BuddyAmount? amount;
/// The subject food when it matches a real food; never an estimate.
@override final  BuddyFoodItem? food;

/// Create a copy of BuddyMemoryChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyMemoryChangeCopyWith<_BuddyMemoryChange> get copyWith => __$BuddyMemoryChangeCopyWithImpl<_BuddyMemoryChange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyMemoryChangeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyMemoryChange&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.memoryKind, memoryKind) || other.memoryKind == memoryKind)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.dimension, dimension) || other.dimension == dimension)&&(identical(other.value, value) || other.value == value)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.food, food) || other.food == food));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,operation,memoryKind,subject,dimension,value,amount,food);
}

@override
String toString() {
    return 'BuddyMemoryChange(kind: $kind, language: $language, script: $script, operation: $operation, memoryKind: $memoryKind, subject: $subject, dimension: $dimension, value: $value, amount: $amount, food: $food)';
}


}

/// @nodoc
abstract mixin class _$BuddyMemoryChangeCopyWith<$Res> implements $BuddyMemoryChangeCopyWith<$Res> {
  factory _$BuddyMemoryChangeCopyWith(_BuddyMemoryChange value, $Res Function(_BuddyMemoryChange) _then) = __$BuddyMemoryChangeCopyWithImpl;
@override @useResult
$Res call({
 BuddyMemoryChangeKind kind, String language, String script, BuddyMemoryOperation operation, BuddyMemoryKind memoryKind, String? subject, BuddyMemoryDimension? dimension, String? value, BuddyAmount? amount, BuddyFoodItem? food
});


@override $BuddyAmountCopyWith<$Res>? get amount;@override $BuddyFoodItemCopyWith<$Res>? get food;

}
/// @nodoc
class __$BuddyMemoryChangeCopyWithImpl<$Res>
    implements _$BuddyMemoryChangeCopyWith<$Res> {
  __$BuddyMemoryChangeCopyWithImpl(this._self, this._then);

  final _BuddyMemoryChange _self;
  final $Res Function(_BuddyMemoryChange) _then;

/// Create a copy of BuddyMemoryChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? operation = null,Object? memoryKind = null,Object? subject = freezed,Object? dimension = freezed,Object? value = freezed,Object? amount = freezed,Object? food = freezed,}) {
  return _then(_BuddyMemoryChange(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyMemoryChangeKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as BuddyMemoryOperation,memoryKind: null == memoryKind ? _self.memoryKind : memoryKind // ignore: cast_nullable_to_non_nullable
as BuddyMemoryKind,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,dimension: freezed == dimension ? _self.dimension : dimension // ignore: cast_nullable_to_non_nullable
as BuddyMemoryDimension?,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BuddyAmount?,food: freezed == food ? _self.food : food // ignore: cast_nullable_to_non_nullable
as BuddyFoodItem?,
  ));
}

/// Create a copy of BuddyMemoryChange
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
}/// Create a copy of BuddyMemoryChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyFoodItemCopyWith<$Res>? get food {
    if (_self.food == null) {
    return null;
  }

  return $BuddyFoodItemCopyWith<$Res>(_self.food!, (value) {
    return _then(_self.copyWith(food: value));
  });
}
}

// dart format on
