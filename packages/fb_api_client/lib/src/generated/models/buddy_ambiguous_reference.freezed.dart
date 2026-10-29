// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_ambiguous_reference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyAmbiguousReference {

 BuddyAmbiguousReferenceKind get kind; String get language; String get script; BuddyReferenceOperation get operation;/// Request recentEntries IDs the message could mean; the app asks which (AI-091).
 List<String> get candidates; BuddyEntryReference get reference;/// The edit to apply to the chosen entry; null for delete.
 BuddyDiaryPatch? get patch;
/// Create a copy of BuddyAmbiguousReference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyAmbiguousReferenceCopyWith<BuddyAmbiguousReference> get copyWith => _$BuddyAmbiguousReferenceCopyWithImpl<BuddyAmbiguousReference>(this as BuddyAmbiguousReference, _$identity);

  /// Serializes this BuddyAmbiguousReference to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyAmbiguousReference;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyAmbiguousReference&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.operation, _this.operation) || other.operation == _this.operation)&&const DeepCollectionEquality().equals(other.candidates, _this.candidates)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.patch, _this.patch) || other.patch == _this.patch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyAmbiguousReference;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.operation,const DeepCollectionEquality().hash(_this.candidates),_this.reference,_this.patch);
}

@override
String toString() {
  final _this = this as BuddyAmbiguousReference;
  return 'BuddyAmbiguousReference(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, operation: ${_this.operation}, candidates: ${_this.candidates}, reference: ${_this.reference}, patch: ${_this.patch})';
}


}

/// @nodoc
abstract mixin class $BuddyAmbiguousReferenceCopyWith<$Res>  {
  factory $BuddyAmbiguousReferenceCopyWith(BuddyAmbiguousReference value, $Res Function(BuddyAmbiguousReference) _then) = _$BuddyAmbiguousReferenceCopyWithImpl;
@useResult
$Res call({
 BuddyAmbiguousReferenceKind kind, String language, String script, BuddyReferenceOperation operation, List<String> candidates, BuddyEntryReference reference, BuddyDiaryPatch? patch
});


$BuddyEntryReferenceCopyWith<$Res> get reference;$BuddyDiaryPatchCopyWith<$Res>? get patch;

}
/// @nodoc
class _$BuddyAmbiguousReferenceCopyWithImpl<$Res>
    implements $BuddyAmbiguousReferenceCopyWith<$Res> {
  _$BuddyAmbiguousReferenceCopyWithImpl(this._self, this._then);

  final BuddyAmbiguousReference _self;
  final $Res Function(BuddyAmbiguousReference) _then;

/// Create a copy of BuddyAmbiguousReference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? operation = null,Object? candidates = null,Object? reference = null,Object? patch = freezed,}) {
  return _then(BuddyAmbiguousReference(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyAmbiguousReferenceKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as BuddyReferenceOperation,candidates: null == candidates ? _self.candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<String>,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as BuddyEntryReference,patch: freezed == patch ? _self.patch : patch // ignore: cast_nullable_to_non_nullable
as BuddyDiaryPatch?,
  ));
}
/// Create a copy of BuddyAmbiguousReference
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyEntryReferenceCopyWith<$Res> get reference {
  
  return $BuddyEntryReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of BuddyAmbiguousReference
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDiaryPatchCopyWith<$Res>? get patch {
    if (_self.patch == null) {
    return null;
  }

  return $BuddyDiaryPatchCopyWith<$Res>(_self.patch!, (value) {
    return _then(_self.copyWith(patch: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyAmbiguousReference].
extension BuddyAmbiguousReferencePatterns on BuddyAmbiguousReference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyAmbiguousReference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyAmbiguousReference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyAmbiguousReference value)  $default,){
final _that = this;
switch (_that) {
case _BuddyAmbiguousReference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyAmbiguousReference value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyAmbiguousReference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyAmbiguousReferenceKind kind,  String language,  String script,  BuddyReferenceOperation operation,  List<String> candidates,  BuddyEntryReference reference,  BuddyDiaryPatch? patch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyAmbiguousReference() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.operation,_that.candidates,_that.reference,_that.patch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyAmbiguousReferenceKind kind,  String language,  String script,  BuddyReferenceOperation operation,  List<String> candidates,  BuddyEntryReference reference,  BuddyDiaryPatch? patch)  $default,) {final _that = this;
switch (_that) {
case _BuddyAmbiguousReference():
return $default(_that.kind,_that.language,_that.script,_that.operation,_that.candidates,_that.reference,_that.patch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyAmbiguousReferenceKind kind,  String language,  String script,  BuddyReferenceOperation operation,  List<String> candidates,  BuddyEntryReference reference,  BuddyDiaryPatch? patch)?  $default,) {final _that = this;
switch (_that) {
case _BuddyAmbiguousReference() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.operation,_that.candidates,_that.reference,_that.patch);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyAmbiguousReference implements BuddyAmbiguousReference {
  const _BuddyAmbiguousReference({required this.kind, required this.language, required this.script, required this.operation, required  List<String> candidates, required this.reference, required this.patch}): _candidates = candidates;
  factory _BuddyAmbiguousReference.fromJson(Map<String, dynamic> json) => _$BuddyAmbiguousReferenceFromJson(json);

@override final  BuddyAmbiguousReferenceKind kind;
@override final  String language;
@override final  String script;
@override final  BuddyReferenceOperation operation;
/// Request recentEntries IDs the message could mean; the app asks which (AI-091).
 final  List<String> _candidates;
/// Request recentEntries IDs the message could mean; the app asks which (AI-091).
@override List<String> get candidates {
  if (_candidates is EqualUnmodifiableListView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candidates);
}

@override final  BuddyEntryReference reference;
/// The edit to apply to the chosen entry; null for delete.
@override final  BuddyDiaryPatch? patch;

/// Create a copy of BuddyAmbiguousReference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyAmbiguousReferenceCopyWith<_BuddyAmbiguousReference> get copyWith => __$BuddyAmbiguousReferenceCopyWithImpl<_BuddyAmbiguousReference>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyAmbiguousReferenceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyAmbiguousReference&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.operation, operation) || other.operation == operation)&&const DeepCollectionEquality().equals(other.candidates, _candidates)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.patch, patch) || other.patch == patch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,operation,const DeepCollectionEquality().hash(_candidates),reference,patch);
}

@override
String toString() {
    return 'BuddyAmbiguousReference(kind: $kind, language: $language, script: $script, operation: $operation, candidates: $candidates, reference: $reference, patch: $patch)';
}


}

/// @nodoc
abstract mixin class _$BuddyAmbiguousReferenceCopyWith<$Res> implements $BuddyAmbiguousReferenceCopyWith<$Res> {
  factory _$BuddyAmbiguousReferenceCopyWith(_BuddyAmbiguousReference value, $Res Function(_BuddyAmbiguousReference) _then) = __$BuddyAmbiguousReferenceCopyWithImpl;
@override @useResult
$Res call({
 BuddyAmbiguousReferenceKind kind, String language, String script, BuddyReferenceOperation operation, List<String> candidates, BuddyEntryReference reference, BuddyDiaryPatch? patch
});


@override $BuddyEntryReferenceCopyWith<$Res> get reference;@override $BuddyDiaryPatchCopyWith<$Res>? get patch;

}
/// @nodoc
class __$BuddyAmbiguousReferenceCopyWithImpl<$Res>
    implements _$BuddyAmbiguousReferenceCopyWith<$Res> {
  __$BuddyAmbiguousReferenceCopyWithImpl(this._self, this._then);

  final _BuddyAmbiguousReference _self;
  final $Res Function(_BuddyAmbiguousReference) _then;

/// Create a copy of BuddyAmbiguousReference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? operation = null,Object? candidates = null,Object? reference = null,Object? patch = freezed,}) {
  return _then(_BuddyAmbiguousReference(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyAmbiguousReferenceKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as BuddyReferenceOperation,candidates: null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<String>,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as BuddyEntryReference,patch: freezed == patch ? _self.patch : patch // ignore: cast_nullable_to_non_nullable
as BuddyDiaryPatch?,
  ));
}

/// Create a copy of BuddyAmbiguousReference
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyEntryReferenceCopyWith<$Res> get reference {
  
  return $BuddyEntryReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of BuddyAmbiguousReference
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDiaryPatchCopyWith<$Res>? get patch {
    if (_self.patch == null) {
    return null;
  }

  return $BuddyDiaryPatchCopyWith<$Res>(_self.patch!, (value) {
    return _then(_self.copyWith(patch: value));
  });
}
}

// dart format on
