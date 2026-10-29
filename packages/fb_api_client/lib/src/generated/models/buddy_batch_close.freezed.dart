// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_batch_close.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyBatchClose {

 BuddyBatchCloseKind get kind; String get language; String get script;/// A request openBatches ID.
 String get batchId;
/// Create a copy of BuddyBatchClose
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyBatchCloseCopyWith<BuddyBatchClose> get copyWith => _$BuddyBatchCloseCopyWithImpl<BuddyBatchClose>(this as BuddyBatchClose, _$identity);

  /// Serializes this BuddyBatchClose to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyBatchClose;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyBatchClose&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.batchId, _this.batchId) || other.batchId == _this.batchId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyBatchClose;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.batchId);
}

@override
String toString() {
  final _this = this as BuddyBatchClose;
  return 'BuddyBatchClose(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, batchId: ${_this.batchId})';
}


}

/// @nodoc
abstract mixin class $BuddyBatchCloseCopyWith<$Res>  {
  factory $BuddyBatchCloseCopyWith(BuddyBatchClose value, $Res Function(BuddyBatchClose) _then) = _$BuddyBatchCloseCopyWithImpl;
@useResult
$Res call({
 BuddyBatchCloseKind kind, String language, String script, String batchId
});




}
/// @nodoc
class _$BuddyBatchCloseCopyWithImpl<$Res>
    implements $BuddyBatchCloseCopyWith<$Res> {
  _$BuddyBatchCloseCopyWithImpl(this._self, this._then);

  final BuddyBatchClose _self;
  final $Res Function(BuddyBatchClose) _then;

/// Create a copy of BuddyBatchClose
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? batchId = null,}) {
  return _then(BuddyBatchClose(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyBatchCloseKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyBatchClose].
extension BuddyBatchClosePatterns on BuddyBatchClose {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyBatchClose value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyBatchClose() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyBatchClose value)  $default,){
final _that = this;
switch (_that) {
case _BuddyBatchClose():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyBatchClose value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyBatchClose() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyBatchCloseKind kind,  String language,  String script,  String batchId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyBatchClose() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.batchId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyBatchCloseKind kind,  String language,  String script,  String batchId)  $default,) {final _that = this;
switch (_that) {
case _BuddyBatchClose():
return $default(_that.kind,_that.language,_that.script,_that.batchId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyBatchCloseKind kind,  String language,  String script,  String batchId)?  $default,) {final _that = this;
switch (_that) {
case _BuddyBatchClose() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.batchId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyBatchClose implements BuddyBatchClose {
  const _BuddyBatchClose({required this.kind, required this.language, required this.script, required this.batchId});
  factory _BuddyBatchClose.fromJson(Map<String, dynamic> json) => _$BuddyBatchCloseFromJson(json);

@override final  BuddyBatchCloseKind kind;
@override final  String language;
@override final  String script;
/// A request openBatches ID.
@override final  String batchId;

/// Create a copy of BuddyBatchClose
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyBatchCloseCopyWith<_BuddyBatchClose> get copyWith => __$BuddyBatchCloseCopyWithImpl<_BuddyBatchClose>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyBatchCloseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyBatchClose&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.batchId, batchId) || other.batchId == batchId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,batchId);
}

@override
String toString() {
    return 'BuddyBatchClose(kind: $kind, language: $language, script: $script, batchId: $batchId)';
}


}

/// @nodoc
abstract mixin class _$BuddyBatchCloseCopyWith<$Res> implements $BuddyBatchCloseCopyWith<$Res> {
  factory _$BuddyBatchCloseCopyWith(_BuddyBatchClose value, $Res Function(_BuddyBatchClose) _then) = __$BuddyBatchCloseCopyWithImpl;
@override @useResult
$Res call({
 BuddyBatchCloseKind kind, String language, String script, String batchId
});




}
/// @nodoc
class __$BuddyBatchCloseCopyWithImpl<$Res>
    implements _$BuddyBatchCloseCopyWith<$Res> {
  __$BuddyBatchCloseCopyWithImpl(this._self, this._then);

  final _BuddyBatchClose _self;
  final $Res Function(_BuddyBatchClose) _then;

/// Create a copy of BuddyBatchClose
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? batchId = null,}) {
  return _then(_BuddyBatchClose(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyBatchCloseKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
