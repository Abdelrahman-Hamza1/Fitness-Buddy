// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_batch_portion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyBatchPortion {

 BuddyBatchPortionKind get kind; String get language; String get script;/// A request openBatches ID.
 String get batchId;/// The portion eaten; null when rest is true.
 BuddyPortion? get portion;/// The user ate the rest of the batch.
 bool get rest;/// Literal time phrase as the user said it (B08); the app resolves it.
 String? get timeHint;/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
 String? get slotHint;/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
 String? get dateHint;
/// Create a copy of BuddyBatchPortion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyBatchPortionCopyWith<BuddyBatchPortion> get copyWith => _$BuddyBatchPortionCopyWithImpl<BuddyBatchPortion>(this as BuddyBatchPortion, _$identity);

  /// Serializes this BuddyBatchPortion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyBatchPortion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyBatchPortion&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.batchId, _this.batchId) || other.batchId == _this.batchId)&&(identical(other.portion, _this.portion) || other.portion == _this.portion)&&(identical(other.rest, _this.rest) || other.rest == _this.rest)&&(identical(other.timeHint, _this.timeHint) || other.timeHint == _this.timeHint)&&(identical(other.slotHint, _this.slotHint) || other.slotHint == _this.slotHint)&&(identical(other.dateHint, _this.dateHint) || other.dateHint == _this.dateHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyBatchPortion;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.batchId,_this.portion,_this.rest,_this.timeHint,_this.slotHint,_this.dateHint);
}

@override
String toString() {
  final _this = this as BuddyBatchPortion;
  return 'BuddyBatchPortion(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, batchId: ${_this.batchId}, portion: ${_this.portion}, rest: ${_this.rest}, timeHint: ${_this.timeHint}, slotHint: ${_this.slotHint}, dateHint: ${_this.dateHint})';
}


}

/// @nodoc
abstract mixin class $BuddyBatchPortionCopyWith<$Res>  {
  factory $BuddyBatchPortionCopyWith(BuddyBatchPortion value, $Res Function(BuddyBatchPortion) _then) = _$BuddyBatchPortionCopyWithImpl;
@useResult
$Res call({
 BuddyBatchPortionKind kind, String language, String script, String batchId, BuddyPortion? portion, bool rest, String? timeHint, String? slotHint, String? dateHint
});


$BuddyPortionCopyWith<$Res>? get portion;

}
/// @nodoc
class _$BuddyBatchPortionCopyWithImpl<$Res>
    implements $BuddyBatchPortionCopyWith<$Res> {
  _$BuddyBatchPortionCopyWithImpl(this._self, this._then);

  final BuddyBatchPortion _self;
  final $Res Function(BuddyBatchPortion) _then;

/// Create a copy of BuddyBatchPortion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? batchId = null,Object? portion = freezed,Object? rest = null,Object? timeHint = freezed,Object? slotHint = freezed,Object? dateHint = freezed,}) {
  return _then(BuddyBatchPortion(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyBatchPortionKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,portion: freezed == portion ? _self.portion : portion // ignore: cast_nullable_to_non_nullable
as BuddyPortion?,rest: null == rest ? _self.rest : rest // ignore: cast_nullable_to_non_nullable
as bool,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BuddyBatchPortion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyPortionCopyWith<$Res>? get portion {
    if (_self.portion == null) {
    return null;
  }

  return $BuddyPortionCopyWith<$Res>(_self.portion!, (value) {
    return _then(_self.copyWith(portion: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyBatchPortion].
extension BuddyBatchPortionPatterns on BuddyBatchPortion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyBatchPortion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyBatchPortion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyBatchPortion value)  $default,){
final _that = this;
switch (_that) {
case _BuddyBatchPortion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyBatchPortion value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyBatchPortion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyBatchPortionKind kind,  String language,  String script,  String batchId,  BuddyPortion? portion,  bool rest,  String? timeHint,  String? slotHint,  String? dateHint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyBatchPortion() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.batchId,_that.portion,_that.rest,_that.timeHint,_that.slotHint,_that.dateHint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyBatchPortionKind kind,  String language,  String script,  String batchId,  BuddyPortion? portion,  bool rest,  String? timeHint,  String? slotHint,  String? dateHint)  $default,) {final _that = this;
switch (_that) {
case _BuddyBatchPortion():
return $default(_that.kind,_that.language,_that.script,_that.batchId,_that.portion,_that.rest,_that.timeHint,_that.slotHint,_that.dateHint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyBatchPortionKind kind,  String language,  String script,  String batchId,  BuddyPortion? portion,  bool rest,  String? timeHint,  String? slotHint,  String? dateHint)?  $default,) {final _that = this;
switch (_that) {
case _BuddyBatchPortion() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.batchId,_that.portion,_that.rest,_that.timeHint,_that.slotHint,_that.dateHint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyBatchPortion implements BuddyBatchPortion {
  const _BuddyBatchPortion({required this.kind, required this.language, required this.script, required this.batchId, required this.portion, required this.rest, required this.timeHint, required this.slotHint, required this.dateHint});
  factory _BuddyBatchPortion.fromJson(Map<String, dynamic> json) => _$BuddyBatchPortionFromJson(json);

@override final  BuddyBatchPortionKind kind;
@override final  String language;
@override final  String script;
/// A request openBatches ID.
@override final  String batchId;
/// The portion eaten; null when rest is true.
@override final  BuddyPortion? portion;
/// The user ate the rest of the batch.
@override final  bool rest;
/// Literal time phrase as the user said it (B08); the app resolves it.
@override final  String? timeHint;
/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
@override final  String? slotHint;
/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
@override final  String? dateHint;

/// Create a copy of BuddyBatchPortion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyBatchPortionCopyWith<_BuddyBatchPortion> get copyWith => __$BuddyBatchPortionCopyWithImpl<_BuddyBatchPortion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyBatchPortionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyBatchPortion&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.portion, portion) || other.portion == portion)&&(identical(other.rest, rest) || other.rest == rest)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint)&&(identical(other.slotHint, slotHint) || other.slotHint == slotHint)&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,batchId,portion,rest,timeHint,slotHint,dateHint);
}

@override
String toString() {
    return 'BuddyBatchPortion(kind: $kind, language: $language, script: $script, batchId: $batchId, portion: $portion, rest: $rest, timeHint: $timeHint, slotHint: $slotHint, dateHint: $dateHint)';
}


}

/// @nodoc
abstract mixin class _$BuddyBatchPortionCopyWith<$Res> implements $BuddyBatchPortionCopyWith<$Res> {
  factory _$BuddyBatchPortionCopyWith(_BuddyBatchPortion value, $Res Function(_BuddyBatchPortion) _then) = __$BuddyBatchPortionCopyWithImpl;
@override @useResult
$Res call({
 BuddyBatchPortionKind kind, String language, String script, String batchId, BuddyPortion? portion, bool rest, String? timeHint, String? slotHint, String? dateHint
});


@override $BuddyPortionCopyWith<$Res>? get portion;

}
/// @nodoc
class __$BuddyBatchPortionCopyWithImpl<$Res>
    implements _$BuddyBatchPortionCopyWith<$Res> {
  __$BuddyBatchPortionCopyWithImpl(this._self, this._then);

  final _BuddyBatchPortion _self;
  final $Res Function(_BuddyBatchPortion) _then;

/// Create a copy of BuddyBatchPortion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? batchId = null,Object? portion = freezed,Object? rest = null,Object? timeHint = freezed,Object? slotHint = freezed,Object? dateHint = freezed,}) {
  return _then(_BuddyBatchPortion(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyBatchPortionKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,portion: freezed == portion ? _self.portion : portion // ignore: cast_nullable_to_non_nullable
as BuddyPortion?,rest: null == rest ? _self.rest : rest // ignore: cast_nullable_to_non_nullable
as bool,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BuddyBatchPortion
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyPortionCopyWith<$Res>? get portion {
    if (_self.portion == null) {
    return null;
  }

  return $BuddyPortionCopyWith<$Res>(_self.portion!, (value) {
    return _then(_self.copyWith(portion: value));
  });
}
}

// dart format on
