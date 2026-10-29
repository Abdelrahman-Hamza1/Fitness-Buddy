// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_diary_copy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyDiaryCopy {

 BuddyDiaryCopyKind get kind; String get language; String get script;/// Where to copy from.
 BuddyDayHint get source;/// Where to copy to.
 BuddyDayHint get target;
/// Create a copy of BuddyDiaryCopy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyDiaryCopyCopyWith<BuddyDiaryCopy> get copyWith => _$BuddyDiaryCopyCopyWithImpl<BuddyDiaryCopy>(this as BuddyDiaryCopy, _$identity);

  /// Serializes this BuddyDiaryCopy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyDiaryCopy;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyDiaryCopy&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.target, _this.target) || other.target == _this.target));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyDiaryCopy;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.source,_this.target);
}

@override
String toString() {
  final _this = this as BuddyDiaryCopy;
  return 'BuddyDiaryCopy(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, source: ${_this.source}, target: ${_this.target})';
}


}

/// @nodoc
abstract mixin class $BuddyDiaryCopyCopyWith<$Res>  {
  factory $BuddyDiaryCopyCopyWith(BuddyDiaryCopy value, $Res Function(BuddyDiaryCopy) _then) = _$BuddyDiaryCopyCopyWithImpl;
@useResult
$Res call({
 BuddyDiaryCopyKind kind, String language, String script, BuddyDayHint source, BuddyDayHint target
});


$BuddyDayHintCopyWith<$Res> get source;$BuddyDayHintCopyWith<$Res> get target;

}
/// @nodoc
class _$BuddyDiaryCopyCopyWithImpl<$Res>
    implements $BuddyDiaryCopyCopyWith<$Res> {
  _$BuddyDiaryCopyCopyWithImpl(this._self, this._then);

  final BuddyDiaryCopy _self;
  final $Res Function(BuddyDiaryCopy) _then;

/// Create a copy of BuddyDiaryCopy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? source = null,Object? target = null,}) {
  return _then(BuddyDiaryCopy(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyDiaryCopyKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BuddyDayHint,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as BuddyDayHint,
  ));
}
/// Create a copy of BuddyDiaryCopy
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayHintCopyWith<$Res> get source {
  
  return $BuddyDayHintCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of BuddyDiaryCopy
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayHintCopyWith<$Res> get target {
  
  return $BuddyDayHintCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyDiaryCopy].
extension BuddyDiaryCopyPatterns on BuddyDiaryCopy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyDiaryCopy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyDiaryCopy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyDiaryCopy value)  $default,){
final _that = this;
switch (_that) {
case _BuddyDiaryCopy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyDiaryCopy value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyDiaryCopy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyDiaryCopyKind kind,  String language,  String script,  BuddyDayHint source,  BuddyDayHint target)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyDiaryCopy() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.source,_that.target);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyDiaryCopyKind kind,  String language,  String script,  BuddyDayHint source,  BuddyDayHint target)  $default,) {final _that = this;
switch (_that) {
case _BuddyDiaryCopy():
return $default(_that.kind,_that.language,_that.script,_that.source,_that.target);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyDiaryCopyKind kind,  String language,  String script,  BuddyDayHint source,  BuddyDayHint target)?  $default,) {final _that = this;
switch (_that) {
case _BuddyDiaryCopy() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.source,_that.target);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyDiaryCopy implements BuddyDiaryCopy {
  const _BuddyDiaryCopy({required this.kind, required this.language, required this.script, required this.source, required this.target});
  factory _BuddyDiaryCopy.fromJson(Map<String, dynamic> json) => _$BuddyDiaryCopyFromJson(json);

@override final  BuddyDiaryCopyKind kind;
@override final  String language;
@override final  String script;
/// Where to copy from.
@override final  BuddyDayHint source;
/// Where to copy to.
@override final  BuddyDayHint target;

/// Create a copy of BuddyDiaryCopy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyDiaryCopyCopyWith<_BuddyDiaryCopy> get copyWith => __$BuddyDiaryCopyCopyWithImpl<_BuddyDiaryCopy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyDiaryCopyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyDiaryCopy&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,source,target);
}

@override
String toString() {
    return 'BuddyDiaryCopy(kind: $kind, language: $language, script: $script, source: $source, target: $target)';
}


}

/// @nodoc
abstract mixin class _$BuddyDiaryCopyCopyWith<$Res> implements $BuddyDiaryCopyCopyWith<$Res> {
  factory _$BuddyDiaryCopyCopyWith(_BuddyDiaryCopy value, $Res Function(_BuddyDiaryCopy) _then) = __$BuddyDiaryCopyCopyWithImpl;
@override @useResult
$Res call({
 BuddyDiaryCopyKind kind, String language, String script, BuddyDayHint source, BuddyDayHint target
});


@override $BuddyDayHintCopyWith<$Res> get source;@override $BuddyDayHintCopyWith<$Res> get target;

}
/// @nodoc
class __$BuddyDiaryCopyCopyWithImpl<$Res>
    implements _$BuddyDiaryCopyCopyWith<$Res> {
  __$BuddyDiaryCopyCopyWithImpl(this._self, this._then);

  final _BuddyDiaryCopy _self;
  final $Res Function(_BuddyDiaryCopy) _then;

/// Create a copy of BuddyDiaryCopy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? source = null,Object? target = null,}) {
  return _then(_BuddyDiaryCopy(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyDiaryCopyKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BuddyDayHint,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as BuddyDayHint,
  ));
}

/// Create a copy of BuddyDiaryCopy
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayHintCopyWith<$Res> get source {
  
  return $BuddyDayHintCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of BuddyDiaryCopy
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayHintCopyWith<$Res> get target {
  
  return $BuddyDayHintCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

// dart format on
