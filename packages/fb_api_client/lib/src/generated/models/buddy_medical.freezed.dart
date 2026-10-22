// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_medical.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyMedical {

 BuddyMedicalKind get kind; String get language; String get script;
/// Create a copy of BuddyMedical
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyMedicalCopyWith<BuddyMedical> get copyWith => _$BuddyMedicalCopyWithImpl<BuddyMedical>(this as BuddyMedical, _$identity);

  /// Serializes this BuddyMedical to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyMedical;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyMedical&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyMedical;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script);
}

@override
String toString() {
  final _this = this as BuddyMedical;
  return 'BuddyMedical(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script})';
}


}

/// @nodoc
abstract mixin class $BuddyMedicalCopyWith<$Res>  {
  factory $BuddyMedicalCopyWith(BuddyMedical value, $Res Function(BuddyMedical) _then) = _$BuddyMedicalCopyWithImpl;
@useResult
$Res call({
 BuddyMedicalKind kind, String language, String script
});




}
/// @nodoc
class _$BuddyMedicalCopyWithImpl<$Res>
    implements $BuddyMedicalCopyWith<$Res> {
  _$BuddyMedicalCopyWithImpl(this._self, this._then);

  final BuddyMedical _self;
  final $Res Function(BuddyMedical) _then;

/// Create a copy of BuddyMedical
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,}) {
  return _then(BuddyMedical(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyMedicalKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyMedical].
extension BuddyMedicalPatterns on BuddyMedical {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyMedical value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyMedical() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyMedical value)  $default,){
final _that = this;
switch (_that) {
case _BuddyMedical():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyMedical value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyMedical() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyMedicalKind kind,  String language,  String script)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyMedical() when $default != null:
return $default(_that.kind,_that.language,_that.script);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyMedicalKind kind,  String language,  String script)  $default,) {final _that = this;
switch (_that) {
case _BuddyMedical():
return $default(_that.kind,_that.language,_that.script);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyMedicalKind kind,  String language,  String script)?  $default,) {final _that = this;
switch (_that) {
case _BuddyMedical() when $default != null:
return $default(_that.kind,_that.language,_that.script);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyMedical implements BuddyMedical {
  const _BuddyMedical({required this.kind, required this.language, required this.script});
  factory _BuddyMedical.fromJson(Map<String, dynamic> json) => _$BuddyMedicalFromJson(json);

@override final  BuddyMedicalKind kind;
@override final  String language;
@override final  String script;

/// Create a copy of BuddyMedical
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyMedicalCopyWith<_BuddyMedical> get copyWith => __$BuddyMedicalCopyWithImpl<_BuddyMedical>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyMedicalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyMedical&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script);
}

@override
String toString() {
    return 'BuddyMedical(kind: $kind, language: $language, script: $script)';
}


}

/// @nodoc
abstract mixin class _$BuddyMedicalCopyWith<$Res> implements $BuddyMedicalCopyWith<$Res> {
  factory _$BuddyMedicalCopyWith(_BuddyMedical value, $Res Function(_BuddyMedical) _then) = __$BuddyMedicalCopyWithImpl;
@override @useResult
$Res call({
 BuddyMedicalKind kind, String language, String script
});




}
/// @nodoc
class __$BuddyMedicalCopyWithImpl<$Res>
    implements _$BuddyMedicalCopyWith<$Res> {
  __$BuddyMedicalCopyWithImpl(this._self, this._then);

  final _BuddyMedical _self;
  final $Res Function(_BuddyMedical) _then;

/// Create a copy of BuddyMedical
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,}) {
  return _then(_BuddyMedical(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyMedicalKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
