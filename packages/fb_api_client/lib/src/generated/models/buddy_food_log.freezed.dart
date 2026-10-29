// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_food_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyFoodLog {

 BuddyFoodLogKind get kind; String get language; String get script;/// Literal time phrase as the user said it (B08); the app resolves it.
 String? get timeHint;/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
 String? get slotHint;/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
 String? get dateHint; String? get dishGroup; List<BuddyFoodItem> get items;
/// Create a copy of BuddyFoodLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyFoodLogCopyWith<BuddyFoodLog> get copyWith => _$BuddyFoodLogCopyWithImpl<BuddyFoodLog>(this as BuddyFoodLog, _$identity);

  /// Serializes this BuddyFoodLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyFoodLog;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyFoodLog&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.timeHint, _this.timeHint) || other.timeHint == _this.timeHint)&&(identical(other.slotHint, _this.slotHint) || other.slotHint == _this.slotHint)&&(identical(other.dateHint, _this.dateHint) || other.dateHint == _this.dateHint)&&(identical(other.dishGroup, _this.dishGroup) || other.dishGroup == _this.dishGroup)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyFoodLog;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.timeHint,_this.slotHint,_this.dateHint,_this.dishGroup,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as BuddyFoodLog;
  return 'BuddyFoodLog(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, timeHint: ${_this.timeHint}, slotHint: ${_this.slotHint}, dateHint: ${_this.dateHint}, dishGroup: ${_this.dishGroup}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $BuddyFoodLogCopyWith<$Res>  {
  factory $BuddyFoodLogCopyWith(BuddyFoodLog value, $Res Function(BuddyFoodLog) _then) = _$BuddyFoodLogCopyWithImpl;
@useResult
$Res call({
 BuddyFoodLogKind kind, String language, String script, String? timeHint, String? slotHint, String? dateHint, String? dishGroup, List<BuddyFoodItem> items
});




}
/// @nodoc
class _$BuddyFoodLogCopyWithImpl<$Res>
    implements $BuddyFoodLogCopyWith<$Res> {
  _$BuddyFoodLogCopyWithImpl(this._self, this._then);

  final BuddyFoodLog _self;
  final $Res Function(BuddyFoodLog) _then;

/// Create a copy of BuddyFoodLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? timeHint = freezed,Object? slotHint = freezed,Object? dateHint = freezed,Object? dishGroup = freezed,Object? items = null,}) {
  return _then(BuddyFoodLog(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyFoodLogKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,dishGroup: freezed == dishGroup ? _self.dishGroup : dishGroup // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<BuddyFoodItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyFoodLog].
extension BuddyFoodLogPatterns on BuddyFoodLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyFoodLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyFoodLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyFoodLog value)  $default,){
final _that = this;
switch (_that) {
case _BuddyFoodLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyFoodLog value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyFoodLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyFoodLogKind kind,  String language,  String script,  String? timeHint,  String? slotHint,  String? dateHint,  String? dishGroup,  List<BuddyFoodItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyFoodLog() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.timeHint,_that.slotHint,_that.dateHint,_that.dishGroup,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyFoodLogKind kind,  String language,  String script,  String? timeHint,  String? slotHint,  String? dateHint,  String? dishGroup,  List<BuddyFoodItem> items)  $default,) {final _that = this;
switch (_that) {
case _BuddyFoodLog():
return $default(_that.kind,_that.language,_that.script,_that.timeHint,_that.slotHint,_that.dateHint,_that.dishGroup,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyFoodLogKind kind,  String language,  String script,  String? timeHint,  String? slotHint,  String? dateHint,  String? dishGroup,  List<BuddyFoodItem> items)?  $default,) {final _that = this;
switch (_that) {
case _BuddyFoodLog() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.timeHint,_that.slotHint,_that.dateHint,_that.dishGroup,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyFoodLog implements BuddyFoodLog {
  const _BuddyFoodLog({required this.kind, required this.language, required this.script, required this.timeHint, required this.slotHint, required this.dateHint, required this.dishGroup, required  List<BuddyFoodItem> items}): _items = items;
  factory _BuddyFoodLog.fromJson(Map<String, dynamic> json) => _$BuddyFoodLogFromJson(json);

@override final  BuddyFoodLogKind kind;
@override final  String language;
@override final  String script;
/// Literal time phrase as the user said it (B08); the app resolves it.
@override final  String? timeHint;
/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
@override final  String? slotHint;
/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
@override final  String? dateHint;
@override final  String? dishGroup;
 final  List<BuddyFoodItem> _items;
@override List<BuddyFoodItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of BuddyFoodLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyFoodLogCopyWith<_BuddyFoodLog> get copyWith => __$BuddyFoodLogCopyWithImpl<_BuddyFoodLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyFoodLogToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyFoodLog&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint)&&(identical(other.slotHint, slotHint) || other.slotHint == slotHint)&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint)&&(identical(other.dishGroup, dishGroup) || other.dishGroup == dishGroup)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,timeHint,slotHint,dateHint,dishGroup,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'BuddyFoodLog(kind: $kind, language: $language, script: $script, timeHint: $timeHint, slotHint: $slotHint, dateHint: $dateHint, dishGroup: $dishGroup, items: $items)';
}


}

/// @nodoc
abstract mixin class _$BuddyFoodLogCopyWith<$Res> implements $BuddyFoodLogCopyWith<$Res> {
  factory _$BuddyFoodLogCopyWith(_BuddyFoodLog value, $Res Function(_BuddyFoodLog) _then) = __$BuddyFoodLogCopyWithImpl;
@override @useResult
$Res call({
 BuddyFoodLogKind kind, String language, String script, String? timeHint, String? slotHint, String? dateHint, String? dishGroup, List<BuddyFoodItem> items
});




}
/// @nodoc
class __$BuddyFoodLogCopyWithImpl<$Res>
    implements _$BuddyFoodLogCopyWith<$Res> {
  __$BuddyFoodLogCopyWithImpl(this._self, this._then);

  final _BuddyFoodLog _self;
  final $Res Function(_BuddyFoodLog) _then;

/// Create a copy of BuddyFoodLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? timeHint = freezed,Object? slotHint = freezed,Object? dateHint = freezed,Object? dishGroup = freezed,Object? items = null,}) {
  return _then(_BuddyFoodLog(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyFoodLogKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,dishGroup: freezed == dishGroup ? _self.dishGroup : dishGroup // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BuddyFoodItem>,
  ));
}


}

// dart format on
