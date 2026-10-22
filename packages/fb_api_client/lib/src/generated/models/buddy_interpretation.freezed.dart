// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_interpretation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyInterpretation {

 String get promptVersion; String get model; List<BuddyIntent> get intents;
/// Create a copy of BuddyInterpretation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyInterpretationCopyWith<BuddyInterpretation> get copyWith => _$BuddyInterpretationCopyWithImpl<BuddyInterpretation>(this as BuddyInterpretation, _$identity);

  /// Serializes this BuddyInterpretation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyInterpretation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyInterpretation&&(identical(other.promptVersion, _this.promptVersion) || other.promptVersion == _this.promptVersion)&&(identical(other.model, _this.model) || other.model == _this.model)&&const DeepCollectionEquality().equals(other.intents, _this.intents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyInterpretation;
  return Object.hash(runtimeType,_this.promptVersion,_this.model,const DeepCollectionEquality().hash(_this.intents));
}

@override
String toString() {
  final _this = this as BuddyInterpretation;
  return 'BuddyInterpretation(promptVersion: ${_this.promptVersion}, model: ${_this.model}, intents: ${_this.intents})';
}


}

/// @nodoc
abstract mixin class $BuddyInterpretationCopyWith<$Res>  {
  factory $BuddyInterpretationCopyWith(BuddyInterpretation value, $Res Function(BuddyInterpretation) _then) = _$BuddyInterpretationCopyWithImpl;
@useResult
$Res call({
 String promptVersion, String model, List<BuddyIntent> intents
});




}
/// @nodoc
class _$BuddyInterpretationCopyWithImpl<$Res>
    implements $BuddyInterpretationCopyWith<$Res> {
  _$BuddyInterpretationCopyWithImpl(this._self, this._then);

  final BuddyInterpretation _self;
  final $Res Function(BuddyInterpretation) _then;

/// Create a copy of BuddyInterpretation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? promptVersion = null,Object? model = null,Object? intents = null,}) {
  return _then(BuddyInterpretation(
promptVersion: null == promptVersion ? _self.promptVersion : promptVersion // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,intents: null == intents ? _self.intents : intents // ignore: cast_nullable_to_non_nullable
as List<BuddyIntent>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyInterpretation].
extension BuddyInterpretationPatterns on BuddyInterpretation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyInterpretation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyInterpretation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyInterpretation value)  $default,){
final _that = this;
switch (_that) {
case _BuddyInterpretation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyInterpretation value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyInterpretation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String promptVersion,  String model,  List<BuddyIntent> intents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyInterpretation() when $default != null:
return $default(_that.promptVersion,_that.model,_that.intents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String promptVersion,  String model,  List<BuddyIntent> intents)  $default,) {final _that = this;
switch (_that) {
case _BuddyInterpretation():
return $default(_that.promptVersion,_that.model,_that.intents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String promptVersion,  String model,  List<BuddyIntent> intents)?  $default,) {final _that = this;
switch (_that) {
case _BuddyInterpretation() when $default != null:
return $default(_that.promptVersion,_that.model,_that.intents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyInterpretation implements BuddyInterpretation {
  const _BuddyInterpretation({required this.promptVersion, required this.model, required  List<BuddyIntent> intents}): _intents = intents;
  factory _BuddyInterpretation.fromJson(Map<String, dynamic> json) => _$BuddyInterpretationFromJson(json);

@override final  String promptVersion;
@override final  String model;
 final  List<BuddyIntent> _intents;
@override List<BuddyIntent> get intents {
  if (_intents is EqualUnmodifiableListView) return _intents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_intents);
}


/// Create a copy of BuddyInterpretation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyInterpretationCopyWith<_BuddyInterpretation> get copyWith => __$BuddyInterpretationCopyWithImpl<_BuddyInterpretation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyInterpretationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyInterpretation&&(identical(other.promptVersion, promptVersion) || other.promptVersion == promptVersion)&&(identical(other.model, model) || other.model == model)&&const DeepCollectionEquality().equals(other.intents, _intents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,promptVersion,model,const DeepCollectionEquality().hash(_intents));
}

@override
String toString() {
    return 'BuddyInterpretation(promptVersion: $promptVersion, model: $model, intents: $intents)';
}


}

/// @nodoc
abstract mixin class _$BuddyInterpretationCopyWith<$Res> implements $BuddyInterpretationCopyWith<$Res> {
  factory _$BuddyInterpretationCopyWith(_BuddyInterpretation value, $Res Function(_BuddyInterpretation) _then) = __$BuddyInterpretationCopyWithImpl;
@override @useResult
$Res call({
 String promptVersion, String model, List<BuddyIntent> intents
});




}
/// @nodoc
class __$BuddyInterpretationCopyWithImpl<$Res>
    implements _$BuddyInterpretationCopyWith<$Res> {
  __$BuddyInterpretationCopyWithImpl(this._self, this._then);

  final _BuddyInterpretation _self;
  final $Res Function(_BuddyInterpretation) _then;

/// Create a copy of BuddyInterpretation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? promptVersion = null,Object? model = null,Object? intents = null,}) {
  return _then(_BuddyInterpretation(
promptVersion: null == promptVersion ? _self.promptVersion : promptVersion // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,intents: null == intents ? _self._intents : intents // ignore: cast_nullable_to_non_nullable
as List<BuddyIntent>,
  ));
}


}

// dart format on
