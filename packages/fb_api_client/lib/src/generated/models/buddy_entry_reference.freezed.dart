// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_entry_reference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyEntryReference {

/// The user's words for the entry.
 String get mention;/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
 String? get dateHint;/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
 String? get slotHint; BuddyReferenceScope get scope;
/// Create a copy of BuddyEntryReference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyEntryReferenceCopyWith<BuddyEntryReference> get copyWith => _$BuddyEntryReferenceCopyWithImpl<BuddyEntryReference>(this as BuddyEntryReference, _$identity);

  /// Serializes this BuddyEntryReference to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyEntryReference;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyEntryReference&&(identical(other.mention, _this.mention) || other.mention == _this.mention)&&(identical(other.dateHint, _this.dateHint) || other.dateHint == _this.dateHint)&&(identical(other.slotHint, _this.slotHint) || other.slotHint == _this.slotHint)&&(identical(other.scope, _this.scope) || other.scope == _this.scope));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyEntryReference;
  return Object.hash(runtimeType,_this.mention,_this.dateHint,_this.slotHint,_this.scope);
}

@override
String toString() {
  final _this = this as BuddyEntryReference;
  return 'BuddyEntryReference(mention: ${_this.mention}, dateHint: ${_this.dateHint}, slotHint: ${_this.slotHint}, scope: ${_this.scope})';
}


}

/// @nodoc
abstract mixin class $BuddyEntryReferenceCopyWith<$Res>  {
  factory $BuddyEntryReferenceCopyWith(BuddyEntryReference value, $Res Function(BuddyEntryReference) _then) = _$BuddyEntryReferenceCopyWithImpl;
@useResult
$Res call({
 String mention, String? dateHint, String? slotHint, BuddyReferenceScope scope
});




}
/// @nodoc
class _$BuddyEntryReferenceCopyWithImpl<$Res>
    implements $BuddyEntryReferenceCopyWith<$Res> {
  _$BuddyEntryReferenceCopyWithImpl(this._self, this._then);

  final BuddyEntryReference _self;
  final $Res Function(BuddyEntryReference) _then;

/// Create a copy of BuddyEntryReference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mention = null,Object? dateHint = freezed,Object? slotHint = freezed,Object? scope = null,}) {
  return _then(BuddyEntryReference(
mention: null == mention ? _self.mention : mention // ignore: cast_nullable_to_non_nullable
as String,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as BuddyReferenceScope,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyEntryReference].
extension BuddyEntryReferencePatterns on BuddyEntryReference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyEntryReference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyEntryReference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyEntryReference value)  $default,){
final _that = this;
switch (_that) {
case _BuddyEntryReference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyEntryReference value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyEntryReference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mention,  String? dateHint,  String? slotHint,  BuddyReferenceScope scope)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyEntryReference() when $default != null:
return $default(_that.mention,_that.dateHint,_that.slotHint,_that.scope);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mention,  String? dateHint,  String? slotHint,  BuddyReferenceScope scope)  $default,) {final _that = this;
switch (_that) {
case _BuddyEntryReference():
return $default(_that.mention,_that.dateHint,_that.slotHint,_that.scope);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mention,  String? dateHint,  String? slotHint,  BuddyReferenceScope scope)?  $default,) {final _that = this;
switch (_that) {
case _BuddyEntryReference() when $default != null:
return $default(_that.mention,_that.dateHint,_that.slotHint,_that.scope);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyEntryReference implements BuddyEntryReference {
  const _BuddyEntryReference({required this.mention, required this.dateHint, required this.slotHint, required this.scope});
  factory _BuddyEntryReference.fromJson(Map<String, dynamic> json) => _$BuddyEntryReferenceFromJson(json);

/// The user's words for the entry.
@override final  String mention;
/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
@override final  String? dateHint;
/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
@override final  String? slotHint;
@override final  BuddyReferenceScope scope;

/// Create a copy of BuddyEntryReference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyEntryReferenceCopyWith<_BuddyEntryReference> get copyWith => __$BuddyEntryReferenceCopyWithImpl<_BuddyEntryReference>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyEntryReferenceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyEntryReference&&(identical(other.mention, mention) || other.mention == mention)&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint)&&(identical(other.slotHint, slotHint) || other.slotHint == slotHint)&&(identical(other.scope, scope) || other.scope == scope));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,mention,dateHint,slotHint,scope);
}

@override
String toString() {
    return 'BuddyEntryReference(mention: $mention, dateHint: $dateHint, slotHint: $slotHint, scope: $scope)';
}


}

/// @nodoc
abstract mixin class _$BuddyEntryReferenceCopyWith<$Res> implements $BuddyEntryReferenceCopyWith<$Res> {
  factory _$BuddyEntryReferenceCopyWith(_BuddyEntryReference value, $Res Function(_BuddyEntryReference) _then) = __$BuddyEntryReferenceCopyWithImpl;
@override @useResult
$Res call({
 String mention, String? dateHint, String? slotHint, BuddyReferenceScope scope
});




}
/// @nodoc
class __$BuddyEntryReferenceCopyWithImpl<$Res>
    implements _$BuddyEntryReferenceCopyWith<$Res> {
  __$BuddyEntryReferenceCopyWithImpl(this._self, this._then);

  final _BuddyEntryReference _self;
  final $Res Function(_BuddyEntryReference) _then;

/// Create a copy of BuddyEntryReference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mention = null,Object? dateHint = freezed,Object? slotHint = freezed,Object? scope = null,}) {
  return _then(_BuddyEntryReference(
mention: null == mention ? _self.mention : mention // ignore: cast_nullable_to_non_nullable
as String,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as BuddyReferenceScope,
  ));
}


}

// dart format on
