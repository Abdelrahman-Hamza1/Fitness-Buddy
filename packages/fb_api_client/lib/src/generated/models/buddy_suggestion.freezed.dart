// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_suggestion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddySuggestion {

 BuddySuggestionKind get kind; String get language; String get script; List<BuddySuggestionOption> get options;
/// Create a copy of BuddySuggestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddySuggestionCopyWith<BuddySuggestion> get copyWith => _$BuddySuggestionCopyWithImpl<BuddySuggestion>(this as BuddySuggestion, _$identity);

  /// Serializes this BuddySuggestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddySuggestion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddySuggestion&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&const DeepCollectionEquality().equals(other.options, _this.options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddySuggestion;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,const DeepCollectionEquality().hash(_this.options));
}

@override
String toString() {
  final _this = this as BuddySuggestion;
  return 'BuddySuggestion(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, options: ${_this.options})';
}


}

/// @nodoc
abstract mixin class $BuddySuggestionCopyWith<$Res>  {
  factory $BuddySuggestionCopyWith(BuddySuggestion value, $Res Function(BuddySuggestion) _then) = _$BuddySuggestionCopyWithImpl;
@useResult
$Res call({
 BuddySuggestionKind kind, String language, String script, List<BuddySuggestionOption> options
});




}
/// @nodoc
class _$BuddySuggestionCopyWithImpl<$Res>
    implements $BuddySuggestionCopyWith<$Res> {
  _$BuddySuggestionCopyWithImpl(this._self, this._then);

  final BuddySuggestion _self;
  final $Res Function(BuddySuggestion) _then;

/// Create a copy of BuddySuggestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? options = null,}) {
  return _then(BuddySuggestion(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddySuggestionKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<BuddySuggestionOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddySuggestion].
extension BuddySuggestionPatterns on BuddySuggestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddySuggestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddySuggestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddySuggestion value)  $default,){
final _that = this;
switch (_that) {
case _BuddySuggestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddySuggestion value)?  $default,){
final _that = this;
switch (_that) {
case _BuddySuggestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddySuggestionKind kind,  String language,  String script,  List<BuddySuggestionOption> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddySuggestion() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddySuggestionKind kind,  String language,  String script,  List<BuddySuggestionOption> options)  $default,) {final _that = this;
switch (_that) {
case _BuddySuggestion():
return $default(_that.kind,_that.language,_that.script,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddySuggestionKind kind,  String language,  String script,  List<BuddySuggestionOption> options)?  $default,) {final _that = this;
switch (_that) {
case _BuddySuggestion() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.options);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddySuggestion implements BuddySuggestion {
  const _BuddySuggestion({required this.kind, required this.language, required this.script, required  List<BuddySuggestionOption> options}): _options = options;
  factory _BuddySuggestion.fromJson(Map<String, dynamic> json) => _$BuddySuggestionFromJson(json);

@override final  BuddySuggestionKind kind;
@override final  String language;
@override final  String script;
 final  List<BuddySuggestionOption> _options;
@override List<BuddySuggestionOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of BuddySuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddySuggestionCopyWith<_BuddySuggestion> get copyWith => __$BuddySuggestionCopyWithImpl<_BuddySuggestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddySuggestionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddySuggestion&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&const DeepCollectionEquality().equals(other.options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,const DeepCollectionEquality().hash(_options));
}

@override
String toString() {
    return 'BuddySuggestion(kind: $kind, language: $language, script: $script, options: $options)';
}


}

/// @nodoc
abstract mixin class _$BuddySuggestionCopyWith<$Res> implements $BuddySuggestionCopyWith<$Res> {
  factory _$BuddySuggestionCopyWith(_BuddySuggestion value, $Res Function(_BuddySuggestion) _then) = __$BuddySuggestionCopyWithImpl;
@override @useResult
$Res call({
 BuddySuggestionKind kind, String language, String script, List<BuddySuggestionOption> options
});




}
/// @nodoc
class __$BuddySuggestionCopyWithImpl<$Res>
    implements _$BuddySuggestionCopyWith<$Res> {
  __$BuddySuggestionCopyWithImpl(this._self, this._then);

  final _BuddySuggestion _self;
  final $Res Function(_BuddySuggestion) _then;

/// Create a copy of BuddySuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? options = null,}) {
  return _then(_BuddySuggestion(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddySuggestionKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<BuddySuggestionOption>,
  ));
}


}

// dart format on
