// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_diary_delete.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyDiaryDelete {

 BuddyDiaryDeleteKind get kind; String get language; String get script;/// Request recentEntries IDs to delete. Empty: the app looks the entries up from reference's day/slot hints and asks.
 List<String> get targets; BuddyEntryReference get reference;
/// Create a copy of BuddyDiaryDelete
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyDiaryDeleteCopyWith<BuddyDiaryDelete> get copyWith => _$BuddyDiaryDeleteCopyWithImpl<BuddyDiaryDelete>(this as BuddyDiaryDelete, _$identity);

  /// Serializes this BuddyDiaryDelete to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyDiaryDelete;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyDiaryDelete&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&const DeepCollectionEquality().equals(other.targets, _this.targets)&&(identical(other.reference, _this.reference) || other.reference == _this.reference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyDiaryDelete;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,const DeepCollectionEquality().hash(_this.targets),_this.reference);
}

@override
String toString() {
  final _this = this as BuddyDiaryDelete;
  return 'BuddyDiaryDelete(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, targets: ${_this.targets}, reference: ${_this.reference})';
}


}

/// @nodoc
abstract mixin class $BuddyDiaryDeleteCopyWith<$Res>  {
  factory $BuddyDiaryDeleteCopyWith(BuddyDiaryDelete value, $Res Function(BuddyDiaryDelete) _then) = _$BuddyDiaryDeleteCopyWithImpl;
@useResult
$Res call({
 BuddyDiaryDeleteKind kind, String language, String script, List<String> targets, BuddyEntryReference reference
});


$BuddyEntryReferenceCopyWith<$Res> get reference;

}
/// @nodoc
class _$BuddyDiaryDeleteCopyWithImpl<$Res>
    implements $BuddyDiaryDeleteCopyWith<$Res> {
  _$BuddyDiaryDeleteCopyWithImpl(this._self, this._then);

  final BuddyDiaryDelete _self;
  final $Res Function(BuddyDiaryDelete) _then;

/// Create a copy of BuddyDiaryDelete
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? targets = null,Object? reference = null,}) {
  return _then(BuddyDiaryDelete(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyDiaryDeleteKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as List<String>,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as BuddyEntryReference,
  ));
}
/// Create a copy of BuddyDiaryDelete
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyEntryReferenceCopyWith<$Res> get reference {
  
  return $BuddyEntryReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyDiaryDelete].
extension BuddyDiaryDeletePatterns on BuddyDiaryDelete {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyDiaryDelete value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyDiaryDelete() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyDiaryDelete value)  $default,){
final _that = this;
switch (_that) {
case _BuddyDiaryDelete():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyDiaryDelete value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyDiaryDelete() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyDiaryDeleteKind kind,  String language,  String script,  List<String> targets,  BuddyEntryReference reference)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyDiaryDelete() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.targets,_that.reference);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyDiaryDeleteKind kind,  String language,  String script,  List<String> targets,  BuddyEntryReference reference)  $default,) {final _that = this;
switch (_that) {
case _BuddyDiaryDelete():
return $default(_that.kind,_that.language,_that.script,_that.targets,_that.reference);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyDiaryDeleteKind kind,  String language,  String script,  List<String> targets,  BuddyEntryReference reference)?  $default,) {final _that = this;
switch (_that) {
case _BuddyDiaryDelete() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.targets,_that.reference);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyDiaryDelete implements BuddyDiaryDelete {
  const _BuddyDiaryDelete({required this.kind, required this.language, required this.script, required  List<String> targets, required this.reference}): _targets = targets;
  factory _BuddyDiaryDelete.fromJson(Map<String, dynamic> json) => _$BuddyDiaryDeleteFromJson(json);

@override final  BuddyDiaryDeleteKind kind;
@override final  String language;
@override final  String script;
/// Request recentEntries IDs to delete. Empty: the app looks the entries up from reference's day/slot hints and asks.
 final  List<String> _targets;
/// Request recentEntries IDs to delete. Empty: the app looks the entries up from reference's day/slot hints and asks.
@override List<String> get targets {
  if (_targets is EqualUnmodifiableListView) return _targets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targets);
}

@override final  BuddyEntryReference reference;

/// Create a copy of BuddyDiaryDelete
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyDiaryDeleteCopyWith<_BuddyDiaryDelete> get copyWith => __$BuddyDiaryDeleteCopyWithImpl<_BuddyDiaryDelete>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyDiaryDeleteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyDiaryDelete&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&const DeepCollectionEquality().equals(other.targets, _targets)&&(identical(other.reference, reference) || other.reference == reference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,const DeepCollectionEquality().hash(_targets),reference);
}

@override
String toString() {
    return 'BuddyDiaryDelete(kind: $kind, language: $language, script: $script, targets: $targets, reference: $reference)';
}


}

/// @nodoc
abstract mixin class _$BuddyDiaryDeleteCopyWith<$Res> implements $BuddyDiaryDeleteCopyWith<$Res> {
  factory _$BuddyDiaryDeleteCopyWith(_BuddyDiaryDelete value, $Res Function(_BuddyDiaryDelete) _then) = __$BuddyDiaryDeleteCopyWithImpl;
@override @useResult
$Res call({
 BuddyDiaryDeleteKind kind, String language, String script, List<String> targets, BuddyEntryReference reference
});


@override $BuddyEntryReferenceCopyWith<$Res> get reference;

}
/// @nodoc
class __$BuddyDiaryDeleteCopyWithImpl<$Res>
    implements _$BuddyDiaryDeleteCopyWith<$Res> {
  __$BuddyDiaryDeleteCopyWithImpl(this._self, this._then);

  final _BuddyDiaryDelete _self;
  final $Res Function(_BuddyDiaryDelete) _then;

/// Create a copy of BuddyDiaryDelete
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? targets = null,Object? reference = null,}) {
  return _then(_BuddyDiaryDelete(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyDiaryDeleteKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,targets: null == targets ? _self._targets : targets // ignore: cast_nullable_to_non_nullable
as List<String>,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as BuddyEntryReference,
  ));
}

/// Create a copy of BuddyDiaryDelete
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyEntryReferenceCopyWith<$Res> get reference {
  
  return $BuddyEntryReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}

// dart format on
