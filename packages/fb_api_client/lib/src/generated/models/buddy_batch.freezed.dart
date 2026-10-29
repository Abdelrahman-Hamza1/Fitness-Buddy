// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_batch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyBatch {

 BuddyBatchKind get kind; String get language; String get script; String? get name;/// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
 List<BuddyFoodItem> get ingredients;/// The cooked weight the user stated.
 BuddyAmount? get cookedWeight; BuddyBatchPath? get path;/// The portion eaten now (AI-101).
 BuddyPortion? get eatenNow;/// Literal time phrase as the user said it (B08); the app resolves it.
 String? get timeHint;/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
 String? get slotHint;/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
 String? get dateHint;
/// Create a copy of BuddyBatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyBatchCopyWith<BuddyBatch> get copyWith => _$BuddyBatchCopyWithImpl<BuddyBatch>(this as BuddyBatch, _$identity);

  /// Serializes this BuddyBatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyBatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyBatch&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.ingredients, _this.ingredients)&&(identical(other.cookedWeight, _this.cookedWeight) || other.cookedWeight == _this.cookedWeight)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.eatenNow, _this.eatenNow) || other.eatenNow == _this.eatenNow)&&(identical(other.timeHint, _this.timeHint) || other.timeHint == _this.timeHint)&&(identical(other.slotHint, _this.slotHint) || other.slotHint == _this.slotHint)&&(identical(other.dateHint, _this.dateHint) || other.dateHint == _this.dateHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyBatch;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.name,const DeepCollectionEquality().hash(_this.ingredients),_this.cookedWeight,_this.path,_this.eatenNow,_this.timeHint,_this.slotHint,_this.dateHint);
}

@override
String toString() {
  final _this = this as BuddyBatch;
  return 'BuddyBatch(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, name: ${_this.name}, ingredients: ${_this.ingredients}, cookedWeight: ${_this.cookedWeight}, path: ${_this.path}, eatenNow: ${_this.eatenNow}, timeHint: ${_this.timeHint}, slotHint: ${_this.slotHint}, dateHint: ${_this.dateHint})';
}


}

/// @nodoc
abstract mixin class $BuddyBatchCopyWith<$Res>  {
  factory $BuddyBatchCopyWith(BuddyBatch value, $Res Function(BuddyBatch) _then) = _$BuddyBatchCopyWithImpl;
@useResult
$Res call({
 BuddyBatchKind kind, String language, String script, String? name, List<BuddyFoodItem> ingredients, BuddyAmount? cookedWeight, BuddyBatchPath? path, BuddyPortion? eatenNow, String? timeHint, String? slotHint, String? dateHint
});


$BuddyAmountCopyWith<$Res>? get cookedWeight;$BuddyPortionCopyWith<$Res>? get eatenNow;

}
/// @nodoc
class _$BuddyBatchCopyWithImpl<$Res>
    implements $BuddyBatchCopyWith<$Res> {
  _$BuddyBatchCopyWithImpl(this._self, this._then);

  final BuddyBatch _self;
  final $Res Function(BuddyBatch) _then;

/// Create a copy of BuddyBatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? name = freezed,Object? ingredients = null,Object? cookedWeight = freezed,Object? path = freezed,Object? eatenNow = freezed,Object? timeHint = freezed,Object? slotHint = freezed,Object? dateHint = freezed,}) {
  return _then(BuddyBatch(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyBatchKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,ingredients: null == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<BuddyFoodItem>,cookedWeight: freezed == cookedWeight ? _self.cookedWeight : cookedWeight // ignore: cast_nullable_to_non_nullable
as BuddyAmount?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as BuddyBatchPath?,eatenNow: freezed == eatenNow ? _self.eatenNow : eatenNow // ignore: cast_nullable_to_non_nullable
as BuddyPortion?,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BuddyBatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyAmountCopyWith<$Res>? get cookedWeight {
    if (_self.cookedWeight == null) {
    return null;
  }

  return $BuddyAmountCopyWith<$Res>(_self.cookedWeight!, (value) {
    return _then(_self.copyWith(cookedWeight: value));
  });
}/// Create a copy of BuddyBatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyPortionCopyWith<$Res>? get eatenNow {
    if (_self.eatenNow == null) {
    return null;
  }

  return $BuddyPortionCopyWith<$Res>(_self.eatenNow!, (value) {
    return _then(_self.copyWith(eatenNow: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyBatch].
extension BuddyBatchPatterns on BuddyBatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyBatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyBatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyBatch value)  $default,){
final _that = this;
switch (_that) {
case _BuddyBatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyBatch value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyBatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyBatchKind kind,  String language,  String script,  String? name,  List<BuddyFoodItem> ingredients,  BuddyAmount? cookedWeight,  BuddyBatchPath? path,  BuddyPortion? eatenNow,  String? timeHint,  String? slotHint,  String? dateHint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyBatch() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.name,_that.ingredients,_that.cookedWeight,_that.path,_that.eatenNow,_that.timeHint,_that.slotHint,_that.dateHint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyBatchKind kind,  String language,  String script,  String? name,  List<BuddyFoodItem> ingredients,  BuddyAmount? cookedWeight,  BuddyBatchPath? path,  BuddyPortion? eatenNow,  String? timeHint,  String? slotHint,  String? dateHint)  $default,) {final _that = this;
switch (_that) {
case _BuddyBatch():
return $default(_that.kind,_that.language,_that.script,_that.name,_that.ingredients,_that.cookedWeight,_that.path,_that.eatenNow,_that.timeHint,_that.slotHint,_that.dateHint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyBatchKind kind,  String language,  String script,  String? name,  List<BuddyFoodItem> ingredients,  BuddyAmount? cookedWeight,  BuddyBatchPath? path,  BuddyPortion? eatenNow,  String? timeHint,  String? slotHint,  String? dateHint)?  $default,) {final _that = this;
switch (_that) {
case _BuddyBatch() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.name,_that.ingredients,_that.cookedWeight,_that.path,_that.eatenNow,_that.timeHint,_that.slotHint,_that.dateHint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyBatch implements BuddyBatch {
  const _BuddyBatch({required this.kind, required this.language, required this.script, required this.name, required  List<BuddyFoodItem> ingredients, required this.cookedWeight, required this.path, required this.eatenNow, required this.timeHint, required this.slotHint, required this.dateHint}): _ingredients = ingredients;
  factory _BuddyBatch.fromJson(Map<String, dynamic> json) => _$BuddyBatchFromJson(json);

@override final  BuddyBatchKind kind;
@override final  String language;
@override final  String script;
@override final  String? name;
/// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
 final  List<BuddyFoodItem> _ingredients;
/// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
@override List<BuddyFoodItem> get ingredients {
  if (_ingredients is EqualUnmodifiableListView) return _ingredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredients);
}

/// The cooked weight the user stated.
@override final  BuddyAmount? cookedWeight;
@override final  BuddyBatchPath? path;
/// The portion eaten now (AI-101).
@override final  BuddyPortion? eatenNow;
/// Literal time phrase as the user said it (B08); the app resolves it.
@override final  String? timeHint;
/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
@override final  String? slotHint;
/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
@override final  String? dateHint;

/// Create a copy of BuddyBatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyBatchCopyWith<_BuddyBatch> get copyWith => __$BuddyBatchCopyWithImpl<_BuddyBatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyBatchToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyBatch&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.ingredients, _ingredients)&&(identical(other.cookedWeight, cookedWeight) || other.cookedWeight == cookedWeight)&&(identical(other.path, path) || other.path == path)&&(identical(other.eatenNow, eatenNow) || other.eatenNow == eatenNow)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint)&&(identical(other.slotHint, slotHint) || other.slotHint == slotHint)&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,name,const DeepCollectionEquality().hash(_ingredients),cookedWeight,path,eatenNow,timeHint,slotHint,dateHint);
}

@override
String toString() {
    return 'BuddyBatch(kind: $kind, language: $language, script: $script, name: $name, ingredients: $ingredients, cookedWeight: $cookedWeight, path: $path, eatenNow: $eatenNow, timeHint: $timeHint, slotHint: $slotHint, dateHint: $dateHint)';
}


}

/// @nodoc
abstract mixin class _$BuddyBatchCopyWith<$Res> implements $BuddyBatchCopyWith<$Res> {
  factory _$BuddyBatchCopyWith(_BuddyBatch value, $Res Function(_BuddyBatch) _then) = __$BuddyBatchCopyWithImpl;
@override @useResult
$Res call({
 BuddyBatchKind kind, String language, String script, String? name, List<BuddyFoodItem> ingredients, BuddyAmount? cookedWeight, BuddyBatchPath? path, BuddyPortion? eatenNow, String? timeHint, String? slotHint, String? dateHint
});


@override $BuddyAmountCopyWith<$Res>? get cookedWeight;@override $BuddyPortionCopyWith<$Res>? get eatenNow;

}
/// @nodoc
class __$BuddyBatchCopyWithImpl<$Res>
    implements _$BuddyBatchCopyWith<$Res> {
  __$BuddyBatchCopyWithImpl(this._self, this._then);

  final _BuddyBatch _self;
  final $Res Function(_BuddyBatch) _then;

/// Create a copy of BuddyBatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? name = freezed,Object? ingredients = null,Object? cookedWeight = freezed,Object? path = freezed,Object? eatenNow = freezed,Object? timeHint = freezed,Object? slotHint = freezed,Object? dateHint = freezed,}) {
  return _then(_BuddyBatch(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyBatchKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,ingredients: null == ingredients ? _self._ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<BuddyFoodItem>,cookedWeight: freezed == cookedWeight ? _self.cookedWeight : cookedWeight // ignore: cast_nullable_to_non_nullable
as BuddyAmount?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as BuddyBatchPath?,eatenNow: freezed == eatenNow ? _self.eatenNow : eatenNow // ignore: cast_nullable_to_non_nullable
as BuddyPortion?,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BuddyBatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyAmountCopyWith<$Res>? get cookedWeight {
    if (_self.cookedWeight == null) {
    return null;
  }

  return $BuddyAmountCopyWith<$Res>(_self.cookedWeight!, (value) {
    return _then(_self.copyWith(cookedWeight: value));
  });
}/// Create a copy of BuddyBatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyPortionCopyWith<$Res>? get eatenNow {
    if (_self.eatenNow == null) {
    return null;
  }

  return $BuddyPortionCopyWith<$Res>(_self.eatenNow!, (value) {
    return _then(_self.copyWith(eatenNow: value));
  });
}
}

// dart format on
