// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_out_of_scope.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyOutOfScope {

 BuddyOutOfScopeKind get kind; String get language; String get script; String get reason;
/// Create a copy of BuddyOutOfScope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyOutOfScopeCopyWith<BuddyOutOfScope> get copyWith => _$BuddyOutOfScopeCopyWithImpl<BuddyOutOfScope>(this as BuddyOutOfScope, _$identity);

  /// Serializes this BuddyOutOfScope to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyOutOfScope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyOutOfScope&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyOutOfScope;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.reason);
}

@override
String toString() {
  final _this = this as BuddyOutOfScope;
  return 'BuddyOutOfScope(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $BuddyOutOfScopeCopyWith<$Res>  {
  factory $BuddyOutOfScopeCopyWith(BuddyOutOfScope value, $Res Function(BuddyOutOfScope) _then) = _$BuddyOutOfScopeCopyWithImpl;
@useResult
$Res call({
 BuddyOutOfScopeKind kind, String language, String script, String reason
});




}
/// @nodoc
class _$BuddyOutOfScopeCopyWithImpl<$Res>
    implements $BuddyOutOfScopeCopyWith<$Res> {
  _$BuddyOutOfScopeCopyWithImpl(this._self, this._then);

  final BuddyOutOfScope _self;
  final $Res Function(BuddyOutOfScope) _then;

/// Create a copy of BuddyOutOfScope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? reason = null,}) {
  return _then(BuddyOutOfScope(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyOutOfScopeKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyOutOfScope].
extension BuddyOutOfScopePatterns on BuddyOutOfScope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyOutOfScope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyOutOfScope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyOutOfScope value)  $default,){
final _that = this;
switch (_that) {
case _BuddyOutOfScope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyOutOfScope value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyOutOfScope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyOutOfScopeKind kind,  String language,  String script,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyOutOfScope() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyOutOfScopeKind kind,  String language,  String script,  String reason)  $default,) {final _that = this;
switch (_that) {
case _BuddyOutOfScope():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyOutOfScopeKind kind,  String language,  String script,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _BuddyOutOfScope() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyOutOfScope implements BuddyOutOfScope {
  const _BuddyOutOfScope({required this.kind, required this.language, required this.script, required this.reason});
  factory _BuddyOutOfScope.fromJson(Map<String, dynamic> json) => _$BuddyOutOfScopeFromJson(json);

@override final  BuddyOutOfScopeKind kind;
@override final  String language;
@override final  String script;
@override final  String reason;

/// Create a copy of BuddyOutOfScope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyOutOfScopeCopyWith<_BuddyOutOfScope> get copyWith => __$BuddyOutOfScopeCopyWithImpl<_BuddyOutOfScope>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyOutOfScopeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyOutOfScope&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,reason);
}

@override
String toString() {
    return 'BuddyOutOfScope(kind: $kind, language: $language, script: $script, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$BuddyOutOfScopeCopyWith<$Res> implements $BuddyOutOfScopeCopyWith<$Res> {
  factory _$BuddyOutOfScopeCopyWith(_BuddyOutOfScope value, $Res Function(_BuddyOutOfScope) _then) = __$BuddyOutOfScopeCopyWithImpl;
@override @useResult
$Res call({
 BuddyOutOfScopeKind kind, String language, String script, String reason
});




}
/// @nodoc
class __$BuddyOutOfScopeCopyWithImpl<$Res>
    implements _$BuddyOutOfScopeCopyWith<$Res> {
  __$BuddyOutOfScopeCopyWithImpl(this._self, this._then);

  final _BuddyOutOfScope _self;
  final $Res Function(_BuddyOutOfScope) _then;

/// Create a copy of BuddyOutOfScope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? reason = null,}) {
  return _then(_BuddyOutOfScope(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyOutOfScopeKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
