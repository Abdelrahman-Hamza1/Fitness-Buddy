// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_clarify.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyClarify {

 BuddyClarifyKind get kind; String get language; String get script; String get reason;
/// Create a copy of BuddyClarify
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyClarifyCopyWith<BuddyClarify> get copyWith => _$BuddyClarifyCopyWithImpl<BuddyClarify>(this as BuddyClarify, _$identity);

  /// Serializes this BuddyClarify to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyClarify;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyClarify&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyClarify;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.reason);
}

@override
String toString() {
  final _this = this as BuddyClarify;
  return 'BuddyClarify(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $BuddyClarifyCopyWith<$Res>  {
  factory $BuddyClarifyCopyWith(BuddyClarify value, $Res Function(BuddyClarify) _then) = _$BuddyClarifyCopyWithImpl;
@useResult
$Res call({
 BuddyClarifyKind kind, String language, String script, String reason
});




}
/// @nodoc
class _$BuddyClarifyCopyWithImpl<$Res>
    implements $BuddyClarifyCopyWith<$Res> {
  _$BuddyClarifyCopyWithImpl(this._self, this._then);

  final BuddyClarify _self;
  final $Res Function(BuddyClarify) _then;

/// Create a copy of BuddyClarify
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? reason = null,}) {
  return _then(BuddyClarify(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyClarifyKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyClarify].
extension BuddyClarifyPatterns on BuddyClarify {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyClarify value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyClarify() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyClarify value)  $default,){
final _that = this;
switch (_that) {
case _BuddyClarify():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyClarify value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyClarify() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyClarifyKind kind,  String language,  String script,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyClarify() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyClarifyKind kind,  String language,  String script,  String reason)  $default,) {final _that = this;
switch (_that) {
case _BuddyClarify():
return $default(_that.kind,_that.language,_that.script,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyClarifyKind kind,  String language,  String script,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _BuddyClarify() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyClarify implements BuddyClarify {
  const _BuddyClarify({required this.kind, required this.language, required this.script, required this.reason});
  factory _BuddyClarify.fromJson(Map<String, dynamic> json) => _$BuddyClarifyFromJson(json);

@override final  BuddyClarifyKind kind;
@override final  String language;
@override final  String script;
@override final  String reason;

/// Create a copy of BuddyClarify
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyClarifyCopyWith<_BuddyClarify> get copyWith => __$BuddyClarifyCopyWithImpl<_BuddyClarify>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyClarifyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyClarify&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,reason);
}

@override
String toString() {
    return 'BuddyClarify(kind: $kind, language: $language, script: $script, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$BuddyClarifyCopyWith<$Res> implements $BuddyClarifyCopyWith<$Res> {
  factory _$BuddyClarifyCopyWith(_BuddyClarify value, $Res Function(_BuddyClarify) _then) = __$BuddyClarifyCopyWithImpl;
@override @useResult
$Res call({
 BuddyClarifyKind kind, String language, String script, String reason
});




}
/// @nodoc
class __$BuddyClarifyCopyWithImpl<$Res>
    implements _$BuddyClarifyCopyWith<$Res> {
  __$BuddyClarifyCopyWithImpl(this._self, this._then);

  final _BuddyClarify _self;
  final $Res Function(_BuddyClarify) _then;

/// Create a copy of BuddyClarify
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? reason = null,}) {
  return _then(_BuddyClarify(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyClarifyKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
