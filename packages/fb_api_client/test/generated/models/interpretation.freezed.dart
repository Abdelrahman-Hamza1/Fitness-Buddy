// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'interpretation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Interpretation {

 Id get id; List<Intent> get intents;
/// Create a copy of Interpretation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InterpretationCopyWith<Interpretation> get copyWith => _$InterpretationCopyWithImpl<Interpretation>(this as Interpretation, _$identity);

  /// Serializes this Interpretation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Interpretation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Interpretation&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.intents, _this.intents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Interpretation;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.intents));
}

@override
String toString() {
  final _this = this as Interpretation;
  return 'Interpretation(id: ${_this.id}, intents: ${_this.intents})';
}


}

/// @nodoc
abstract mixin class $InterpretationCopyWith<$Res>  {
  factory $InterpretationCopyWith(Interpretation value, $Res Function(Interpretation) _then) = _$InterpretationCopyWithImpl;
@useResult
$Res call({
 Id id, List<Intent> intents
});




}
/// @nodoc
class _$InterpretationCopyWithImpl<$Res>
    implements $InterpretationCopyWith<$Res> {
  _$InterpretationCopyWithImpl(this._self, this._then);

  final Interpretation _self;
  final $Res Function(Interpretation) _then;

/// Create a copy of Interpretation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? intents = null,}) {
  return _then(Interpretation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Id,intents: null == intents ? _self.intents : intents // ignore: cast_nullable_to_non_nullable
as List<Intent>,
  ));
}

}


/// Adds pattern-matching-related methods to [Interpretation].
extension InterpretationPatterns on Interpretation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Interpretation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Interpretation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Interpretation value)  $default,){
final _that = this;
switch (_that) {
case _Interpretation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Interpretation value)?  $default,){
final _that = this;
switch (_that) {
case _Interpretation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Id id,  List<Intent> intents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Interpretation() when $default != null:
return $default(_that.id,_that.intents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Id id,  List<Intent> intents)  $default,) {final _that = this;
switch (_that) {
case _Interpretation():
return $default(_that.id,_that.intents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Id id,  List<Intent> intents)?  $default,) {final _that = this;
switch (_that) {
case _Interpretation() when $default != null:
return $default(_that.id,_that.intents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Interpretation implements Interpretation {
  const _Interpretation({required this.id, required  List<Intent> intents}): _intents = intents;
  factory _Interpretation.fromJson(Map<String, dynamic> json) => _$InterpretationFromJson(json);

@override final  Id id;
 final  List<Intent> _intents;
@override List<Intent> get intents {
  if (_intents is EqualUnmodifiableListView) return _intents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_intents);
}


/// Create a copy of Interpretation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InterpretationCopyWith<_Interpretation> get copyWith => __$InterpretationCopyWithImpl<_Interpretation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InterpretationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Interpretation&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.intents, _intents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_intents));
}

@override
String toString() {
    return 'Interpretation(id: $id, intents: $intents)';
}


}

/// @nodoc
abstract mixin class _$InterpretationCopyWith<$Res> implements $InterpretationCopyWith<$Res> {
  factory _$InterpretationCopyWith(_Interpretation value, $Res Function(_Interpretation) _then) = __$InterpretationCopyWithImpl;
@override @useResult
$Res call({
 Id id, List<Intent> intents
});




}
/// @nodoc
class __$InterpretationCopyWithImpl<$Res>
    implements _$InterpretationCopyWith<$Res> {
  __$InterpretationCopyWithImpl(this._self, this._then);

  final _Interpretation _self;
  final $Res Function(_Interpretation) _then;

/// Create a copy of Interpretation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? intents = null,}) {
  return _then(_Interpretation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Id,intents: null == intents ? _self._intents : intents // ignore: cast_nullable_to_non_nullable
as List<Intent>,
  ));
}


}

// dart format on
