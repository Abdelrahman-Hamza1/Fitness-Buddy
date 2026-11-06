// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_history_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyHistoryEntry {

 String get messageId; BuddyHistoryRole get role;/// The message or reply text as shown (≤ 1000 characters; the phone truncates longer ones).
 String get text; List<BuddyOutcome> get outcomes;
/// Create a copy of BuddyHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyHistoryEntryCopyWith<BuddyHistoryEntry> get copyWith => _$BuddyHistoryEntryCopyWithImpl<BuddyHistoryEntry>(this as BuddyHistoryEntry, _$identity);

  /// Serializes this BuddyHistoryEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyHistoryEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyHistoryEntry&&(identical(other.messageId, _this.messageId) || other.messageId == _this.messageId)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.text, _this.text) || other.text == _this.text)&&const DeepCollectionEquality().equals(other.outcomes, _this.outcomes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyHistoryEntry;
  return Object.hash(runtimeType,_this.messageId,_this.role,_this.text,const DeepCollectionEquality().hash(_this.outcomes));
}

@override
String toString() {
  final _this = this as BuddyHistoryEntry;
  return 'BuddyHistoryEntry(messageId: ${_this.messageId}, role: ${_this.role}, text: ${_this.text}, outcomes: ${_this.outcomes})';
}


}

/// @nodoc
abstract mixin class $BuddyHistoryEntryCopyWith<$Res>  {
  factory $BuddyHistoryEntryCopyWith(BuddyHistoryEntry value, $Res Function(BuddyHistoryEntry) _then) = _$BuddyHistoryEntryCopyWithImpl;
@useResult
$Res call({
 String messageId, BuddyHistoryRole role, String text, List<BuddyOutcome> outcomes
});




}
/// @nodoc
class _$BuddyHistoryEntryCopyWithImpl<$Res>
    implements $BuddyHistoryEntryCopyWith<$Res> {
  _$BuddyHistoryEntryCopyWithImpl(this._self, this._then);

  final BuddyHistoryEntry _self;
  final $Res Function(BuddyHistoryEntry) _then;

/// Create a copy of BuddyHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? role = null,Object? text = null,Object? outcomes = null,}) {
  return _then(BuddyHistoryEntry(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as BuddyHistoryRole,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,outcomes: null == outcomes ? _self.outcomes : outcomes // ignore: cast_nullable_to_non_nullable
as List<BuddyOutcome>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyHistoryEntry].
extension BuddyHistoryEntryPatterns on BuddyHistoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyHistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyHistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _BuddyHistoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyHistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  BuddyHistoryRole role,  String text,  List<BuddyOutcome> outcomes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyHistoryEntry() when $default != null:
return $default(_that.messageId,_that.role,_that.text,_that.outcomes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  BuddyHistoryRole role,  String text,  List<BuddyOutcome> outcomes)  $default,) {final _that = this;
switch (_that) {
case _BuddyHistoryEntry():
return $default(_that.messageId,_that.role,_that.text,_that.outcomes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  BuddyHistoryRole role,  String text,  List<BuddyOutcome> outcomes)?  $default,) {final _that = this;
switch (_that) {
case _BuddyHistoryEntry() when $default != null:
return $default(_that.messageId,_that.role,_that.text,_that.outcomes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyHistoryEntry implements BuddyHistoryEntry {
  const _BuddyHistoryEntry({required this.messageId, required this.role, required this.text, required  List<BuddyOutcome> outcomes}): _outcomes = outcomes;
  factory _BuddyHistoryEntry.fromJson(Map<String, dynamic> json) => _$BuddyHistoryEntryFromJson(json);

@override final  String messageId;
@override final  BuddyHistoryRole role;
/// The message or reply text as shown (≤ 1000 characters; the phone truncates longer ones).
@override final  String text;
 final  List<BuddyOutcome> _outcomes;
@override List<BuddyOutcome> get outcomes {
  if (_outcomes is EqualUnmodifiableListView) return _outcomes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outcomes);
}


/// Create a copy of BuddyHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyHistoryEntryCopyWith<_BuddyHistoryEntry> get copyWith => __$BuddyHistoryEntryCopyWithImpl<_BuddyHistoryEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyHistoryEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyHistoryEntry&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.role, role) || other.role == role)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.outcomes, _outcomes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,messageId,role,text,const DeepCollectionEquality().hash(_outcomes));
}

@override
String toString() {
    return 'BuddyHistoryEntry(messageId: $messageId, role: $role, text: $text, outcomes: $outcomes)';
}


}

/// @nodoc
abstract mixin class _$BuddyHistoryEntryCopyWith<$Res> implements $BuddyHistoryEntryCopyWith<$Res> {
  factory _$BuddyHistoryEntryCopyWith(_BuddyHistoryEntry value, $Res Function(_BuddyHistoryEntry) _then) = __$BuddyHistoryEntryCopyWithImpl;
@override @useResult
$Res call({
 String messageId, BuddyHistoryRole role, String text, List<BuddyOutcome> outcomes
});




}
/// @nodoc
class __$BuddyHistoryEntryCopyWithImpl<$Res>
    implements _$BuddyHistoryEntryCopyWith<$Res> {
  __$BuddyHistoryEntryCopyWithImpl(this._self, this._then);

  final _BuddyHistoryEntry _self;
  final $Res Function(_BuddyHistoryEntry) _then;

/// Create a copy of BuddyHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? role = null,Object? text = null,Object? outcomes = null,}) {
  return _then(_BuddyHistoryEntry(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as BuddyHistoryRole,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,outcomes: null == outcomes ? _self._outcomes : outcomes // ignore: cast_nullable_to_non_nullable
as List<BuddyOutcome>,
  ));
}


}

// dart format on
