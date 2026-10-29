// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_diary_edit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyDiaryEdit {

 BuddyDiaryEditKind get kind; String get language; String get script;/// Request recentEntries IDs to change. Empty: the app looks the entries up from reference's day/slot hints and asks.
 List<String> get targets; BuddyEntryReference get reference; BuddyDiaryPatch get patch;
/// Create a copy of BuddyDiaryEdit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyDiaryEditCopyWith<BuddyDiaryEdit> get copyWith => _$BuddyDiaryEditCopyWithImpl<BuddyDiaryEdit>(this as BuddyDiaryEdit, _$identity);

  /// Serializes this BuddyDiaryEdit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyDiaryEdit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyDiaryEdit&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&const DeepCollectionEquality().equals(other.targets, _this.targets)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.patch, _this.patch) || other.patch == _this.patch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyDiaryEdit;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,const DeepCollectionEquality().hash(_this.targets),_this.reference,_this.patch);
}

@override
String toString() {
  final _this = this as BuddyDiaryEdit;
  return 'BuddyDiaryEdit(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, targets: ${_this.targets}, reference: ${_this.reference}, patch: ${_this.patch})';
}


}

/// @nodoc
abstract mixin class $BuddyDiaryEditCopyWith<$Res>  {
  factory $BuddyDiaryEditCopyWith(BuddyDiaryEdit value, $Res Function(BuddyDiaryEdit) _then) = _$BuddyDiaryEditCopyWithImpl;
@useResult
$Res call({
 BuddyDiaryEditKind kind, String language, String script, List<String> targets, BuddyEntryReference reference, BuddyDiaryPatch patch
});


$BuddyEntryReferenceCopyWith<$Res> get reference;$BuddyDiaryPatchCopyWith<$Res> get patch;

}
/// @nodoc
class _$BuddyDiaryEditCopyWithImpl<$Res>
    implements $BuddyDiaryEditCopyWith<$Res> {
  _$BuddyDiaryEditCopyWithImpl(this._self, this._then);

  final BuddyDiaryEdit _self;
  final $Res Function(BuddyDiaryEdit) _then;

/// Create a copy of BuddyDiaryEdit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? targets = null,Object? reference = null,Object? patch = null,}) {
  return _then(BuddyDiaryEdit(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyDiaryEditKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as List<String>,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as BuddyEntryReference,patch: null == patch ? _self.patch : patch // ignore: cast_nullable_to_non_nullable
as BuddyDiaryPatch,
  ));
}
/// Create a copy of BuddyDiaryEdit
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyEntryReferenceCopyWith<$Res> get reference {
  
  return $BuddyEntryReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of BuddyDiaryEdit
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDiaryPatchCopyWith<$Res> get patch {
  
  return $BuddyDiaryPatchCopyWith<$Res>(_self.patch, (value) {
    return _then(_self.copyWith(patch: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyDiaryEdit].
extension BuddyDiaryEditPatterns on BuddyDiaryEdit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyDiaryEdit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyDiaryEdit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyDiaryEdit value)  $default,){
final _that = this;
switch (_that) {
case _BuddyDiaryEdit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyDiaryEdit value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyDiaryEdit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyDiaryEditKind kind,  String language,  String script,  List<String> targets,  BuddyEntryReference reference,  BuddyDiaryPatch patch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyDiaryEdit() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.targets,_that.reference,_that.patch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyDiaryEditKind kind,  String language,  String script,  List<String> targets,  BuddyEntryReference reference,  BuddyDiaryPatch patch)  $default,) {final _that = this;
switch (_that) {
case _BuddyDiaryEdit():
return $default(_that.kind,_that.language,_that.script,_that.targets,_that.reference,_that.patch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyDiaryEditKind kind,  String language,  String script,  List<String> targets,  BuddyEntryReference reference,  BuddyDiaryPatch patch)?  $default,) {final _that = this;
switch (_that) {
case _BuddyDiaryEdit() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.targets,_that.reference,_that.patch);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyDiaryEdit implements BuddyDiaryEdit {
  const _BuddyDiaryEdit({required this.kind, required this.language, required this.script, required  List<String> targets, required this.reference, required this.patch}): _targets = targets;
  factory _BuddyDiaryEdit.fromJson(Map<String, dynamic> json) => _$BuddyDiaryEditFromJson(json);

@override final  BuddyDiaryEditKind kind;
@override final  String language;
@override final  String script;
/// Request recentEntries IDs to change. Empty: the app looks the entries up from reference's day/slot hints and asks.
 final  List<String> _targets;
/// Request recentEntries IDs to change. Empty: the app looks the entries up from reference's day/slot hints and asks.
@override List<String> get targets {
  if (_targets is EqualUnmodifiableListView) return _targets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targets);
}

@override final  BuddyEntryReference reference;
@override final  BuddyDiaryPatch patch;

/// Create a copy of BuddyDiaryEdit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyDiaryEditCopyWith<_BuddyDiaryEdit> get copyWith => __$BuddyDiaryEditCopyWithImpl<_BuddyDiaryEdit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyDiaryEditToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyDiaryEdit&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&const DeepCollectionEquality().equals(other.targets, _targets)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.patch, patch) || other.patch == patch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,const DeepCollectionEquality().hash(_targets),reference,patch);
}

@override
String toString() {
    return 'BuddyDiaryEdit(kind: $kind, language: $language, script: $script, targets: $targets, reference: $reference, patch: $patch)';
}


}

/// @nodoc
abstract mixin class _$BuddyDiaryEditCopyWith<$Res> implements $BuddyDiaryEditCopyWith<$Res> {
  factory _$BuddyDiaryEditCopyWith(_BuddyDiaryEdit value, $Res Function(_BuddyDiaryEdit) _then) = __$BuddyDiaryEditCopyWithImpl;
@override @useResult
$Res call({
 BuddyDiaryEditKind kind, String language, String script, List<String> targets, BuddyEntryReference reference, BuddyDiaryPatch patch
});


@override $BuddyEntryReferenceCopyWith<$Res> get reference;@override $BuddyDiaryPatchCopyWith<$Res> get patch;

}
/// @nodoc
class __$BuddyDiaryEditCopyWithImpl<$Res>
    implements _$BuddyDiaryEditCopyWith<$Res> {
  __$BuddyDiaryEditCopyWithImpl(this._self, this._then);

  final _BuddyDiaryEdit _self;
  final $Res Function(_BuddyDiaryEdit) _then;

/// Create a copy of BuddyDiaryEdit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? targets = null,Object? reference = null,Object? patch = null,}) {
  return _then(_BuddyDiaryEdit(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyDiaryEditKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,targets: null == targets ? _self._targets : targets // ignore: cast_nullable_to_non_nullable
as List<String>,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as BuddyEntryReference,patch: null == patch ? _self.patch : patch // ignore: cast_nullable_to_non_nullable
as BuddyDiaryPatch,
  ));
}

/// Create a copy of BuddyDiaryEdit
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyEntryReferenceCopyWith<$Res> get reference {
  
  return $BuddyEntryReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of BuddyDiaryEdit
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDiaryPatchCopyWith<$Res> get patch {
  
  return $BuddyDiaryPatchCopyWith<$Res>(_self.patch, (value) {
    return _then(_self.copyWith(patch: value));
  });
}
}

// dart format on
