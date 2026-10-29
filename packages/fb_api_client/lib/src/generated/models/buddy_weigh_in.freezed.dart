// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_weigh_in.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyWeighIn {

 BuddyWeighInKind get kind; String get language; String get script; double get value; String get unit;/// Literal time phrase as the user said it (B08); the app resolves it.
 String? get timeHint;/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
 String? get dateHint;
/// Create a copy of BuddyWeighIn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyWeighInCopyWith<BuddyWeighIn> get copyWith => _$BuddyWeighInCopyWithImpl<BuddyWeighIn>(this as BuddyWeighIn, _$identity);

  /// Serializes this BuddyWeighIn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyWeighIn;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyWeighIn&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.timeHint, _this.timeHint) || other.timeHint == _this.timeHint)&&(identical(other.dateHint, _this.dateHint) || other.dateHint == _this.dateHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyWeighIn;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.value,_this.unit,_this.timeHint,_this.dateHint);
}

@override
String toString() {
  final _this = this as BuddyWeighIn;
  return 'BuddyWeighIn(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, value: ${_this.value}, unit: ${_this.unit}, timeHint: ${_this.timeHint}, dateHint: ${_this.dateHint})';
}


}

/// @nodoc
abstract mixin class $BuddyWeighInCopyWith<$Res>  {
  factory $BuddyWeighInCopyWith(BuddyWeighIn value, $Res Function(BuddyWeighIn) _then) = _$BuddyWeighInCopyWithImpl;
@useResult
$Res call({
 BuddyWeighInKind kind, String language, String script, double value, String unit, String? timeHint, String? dateHint
});




}
/// @nodoc
class _$BuddyWeighInCopyWithImpl<$Res>
    implements $BuddyWeighInCopyWith<$Res> {
  _$BuddyWeighInCopyWithImpl(this._self, this._then);

  final BuddyWeighIn _self;
  final $Res Function(BuddyWeighIn) _then;

/// Create a copy of BuddyWeighIn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? value = null,Object? unit = null,Object? timeHint = freezed,Object? dateHint = freezed,}) {
  return _then(BuddyWeighIn(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyWeighInKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyWeighIn].
extension BuddyWeighInPatterns on BuddyWeighIn {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyWeighIn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyWeighIn() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyWeighIn value)  $default,){
final _that = this;
switch (_that) {
case _BuddyWeighIn():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyWeighIn value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyWeighIn() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyWeighInKind kind,  String language,  String script,  double value,  String unit,  String? timeHint,  String? dateHint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyWeighIn() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.value,_that.unit,_that.timeHint,_that.dateHint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyWeighInKind kind,  String language,  String script,  double value,  String unit,  String? timeHint,  String? dateHint)  $default,) {final _that = this;
switch (_that) {
case _BuddyWeighIn():
return $default(_that.kind,_that.language,_that.script,_that.value,_that.unit,_that.timeHint,_that.dateHint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyWeighInKind kind,  String language,  String script,  double value,  String unit,  String? timeHint,  String? dateHint)?  $default,) {final _that = this;
switch (_that) {
case _BuddyWeighIn() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.value,_that.unit,_that.timeHint,_that.dateHint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyWeighIn implements BuddyWeighIn {
  const _BuddyWeighIn({required this.kind, required this.language, required this.script, required this.value, required this.unit, required this.timeHint, required this.dateHint});
  factory _BuddyWeighIn.fromJson(Map<String, dynamic> json) => _$BuddyWeighInFromJson(json);

@override final  BuddyWeighInKind kind;
@override final  String language;
@override final  String script;
@override final  double value;
@override final  String unit;
/// Literal time phrase as the user said it (B08); the app resolves it.
@override final  String? timeHint;
/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
@override final  String? dateHint;

/// Create a copy of BuddyWeighIn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyWeighInCopyWith<_BuddyWeighIn> get copyWith => __$BuddyWeighInCopyWithImpl<_BuddyWeighIn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyWeighInToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyWeighIn&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint)&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,value,unit,timeHint,dateHint);
}

@override
String toString() {
    return 'BuddyWeighIn(kind: $kind, language: $language, script: $script, value: $value, unit: $unit, timeHint: $timeHint, dateHint: $dateHint)';
}


}

/// @nodoc
abstract mixin class _$BuddyWeighInCopyWith<$Res> implements $BuddyWeighInCopyWith<$Res> {
  factory _$BuddyWeighInCopyWith(_BuddyWeighIn value, $Res Function(_BuddyWeighIn) _then) = __$BuddyWeighInCopyWithImpl;
@override @useResult
$Res call({
 BuddyWeighInKind kind, String language, String script, double value, String unit, String? timeHint, String? dateHint
});




}
/// @nodoc
class __$BuddyWeighInCopyWithImpl<$Res>
    implements _$BuddyWeighInCopyWith<$Res> {
  __$BuddyWeighInCopyWithImpl(this._self, this._then);

  final _BuddyWeighIn _self;
  final $Res Function(_BuddyWeighIn) _then;

/// Create a copy of BuddyWeighIn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? value = null,Object? unit = null,Object? timeHint = freezed,Object? dateHint = freezed,}) {
  return _then(_BuddyWeighIn(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyWeighInKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
