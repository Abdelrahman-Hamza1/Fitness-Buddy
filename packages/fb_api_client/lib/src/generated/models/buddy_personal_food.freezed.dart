// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_personal_food.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyPersonalFood {

 String get id; List<String> get names; List<String> get aliases; String get state; BuddyNutrients get nutrients; List<BuddyServing> get servings;
/// Create a copy of BuddyPersonalFood
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPersonalFoodCopyWith<BuddyPersonalFood> get copyWith => _$BuddyPersonalFoodCopyWithImpl<BuddyPersonalFood>(this as BuddyPersonalFood, _$identity);

  /// Serializes this BuddyPersonalFood to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyPersonalFood;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPersonalFood&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.names, _this.names)&&const DeepCollectionEquality().equals(other.aliases, _this.aliases)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.nutrients, _this.nutrients) || other.nutrients == _this.nutrients)&&const DeepCollectionEquality().equals(other.servings, _this.servings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyPersonalFood;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.names),const DeepCollectionEquality().hash(_this.aliases),_this.state,_this.nutrients,const DeepCollectionEquality().hash(_this.servings));
}

@override
String toString() {
  final _this = this as BuddyPersonalFood;
  return 'BuddyPersonalFood(id: ${_this.id}, names: ${_this.names}, aliases: ${_this.aliases}, state: ${_this.state}, nutrients: ${_this.nutrients}, servings: ${_this.servings})';
}


}

/// @nodoc
abstract mixin class $BuddyPersonalFoodCopyWith<$Res>  {
  factory $BuddyPersonalFoodCopyWith(BuddyPersonalFood value, $Res Function(BuddyPersonalFood) _then) = _$BuddyPersonalFoodCopyWithImpl;
@useResult
$Res call({
 String id, List<String> names, List<String> aliases, String state, BuddyNutrients nutrients, List<BuddyServing> servings
});


$BuddyNutrientsCopyWith<$Res> get nutrients;

}
/// @nodoc
class _$BuddyPersonalFoodCopyWithImpl<$Res>
    implements $BuddyPersonalFoodCopyWith<$Res> {
  _$BuddyPersonalFoodCopyWithImpl(this._self, this._then);

  final BuddyPersonalFood _self;
  final $Res Function(BuddyPersonalFood) _then;

/// Create a copy of BuddyPersonalFood
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? names = null,Object? aliases = null,Object? state = null,Object? nutrients = null,Object? servings = null,}) {
  return _then(BuddyPersonalFood(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,names: null == names ? _self.names : names // ignore: cast_nullable_to_non_nullable
as List<String>,aliases: null == aliases ? _self.aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,nutrients: null == nutrients ? _self.nutrients : nutrients // ignore: cast_nullable_to_non_nullable
as BuddyNutrients,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as List<BuddyServing>,
  ));
}
/// Create a copy of BuddyPersonalFood
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyNutrientsCopyWith<$Res> get nutrients {
  
  return $BuddyNutrientsCopyWith<$Res>(_self.nutrients, (value) {
    return _then(_self.copyWith(nutrients: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyPersonalFood].
extension BuddyPersonalFoodPatterns on BuddyPersonalFood {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyPersonalFood value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyPersonalFood() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyPersonalFood value)  $default,){
final _that = this;
switch (_that) {
case _BuddyPersonalFood():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyPersonalFood value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyPersonalFood() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  List<String> names,  List<String> aliases,  String state,  BuddyNutrients nutrients,  List<BuddyServing> servings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyPersonalFood() when $default != null:
return $default(_that.id,_that.names,_that.aliases,_that.state,_that.nutrients,_that.servings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  List<String> names,  List<String> aliases,  String state,  BuddyNutrients nutrients,  List<BuddyServing> servings)  $default,) {final _that = this;
switch (_that) {
case _BuddyPersonalFood():
return $default(_that.id,_that.names,_that.aliases,_that.state,_that.nutrients,_that.servings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  List<String> names,  List<String> aliases,  String state,  BuddyNutrients nutrients,  List<BuddyServing> servings)?  $default,) {final _that = this;
switch (_that) {
case _BuddyPersonalFood() when $default != null:
return $default(_that.id,_that.names,_that.aliases,_that.state,_that.nutrients,_that.servings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyPersonalFood implements BuddyPersonalFood {
  const _BuddyPersonalFood({required this.id, required  List<String> names, required  List<String> aliases, required this.state, required this.nutrients, required  List<BuddyServing> servings}): _names = names,_aliases = aliases,_servings = servings;
  factory _BuddyPersonalFood.fromJson(Map<String, dynamic> json) => _$BuddyPersonalFoodFromJson(json);

@override final  String id;
 final  List<String> _names;
@override List<String> get names {
  if (_names is EqualUnmodifiableListView) return _names;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_names);
}

 final  List<String> _aliases;
@override List<String> get aliases {
  if (_aliases is EqualUnmodifiableListView) return _aliases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_aliases);
}

@override final  String state;
@override final  BuddyNutrients nutrients;
 final  List<BuddyServing> _servings;
@override List<BuddyServing> get servings {
  if (_servings is EqualUnmodifiableListView) return _servings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_servings);
}


/// Create a copy of BuddyPersonalFood
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyPersonalFoodCopyWith<_BuddyPersonalFood> get copyWith => __$BuddyPersonalFoodCopyWithImpl<_BuddyPersonalFood>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPersonalFoodToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyPersonalFood&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.names, _names)&&const DeepCollectionEquality().equals(other.aliases, _aliases)&&(identical(other.state, state) || other.state == state)&&(identical(other.nutrients, nutrients) || other.nutrients == nutrients)&&const DeepCollectionEquality().equals(other.servings, _servings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_names),const DeepCollectionEquality().hash(_aliases),state,nutrients,const DeepCollectionEquality().hash(_servings));
}

@override
String toString() {
    return 'BuddyPersonalFood(id: $id, names: $names, aliases: $aliases, state: $state, nutrients: $nutrients, servings: $servings)';
}


}

/// @nodoc
abstract mixin class _$BuddyPersonalFoodCopyWith<$Res> implements $BuddyPersonalFoodCopyWith<$Res> {
  factory _$BuddyPersonalFoodCopyWith(_BuddyPersonalFood value, $Res Function(_BuddyPersonalFood) _then) = __$BuddyPersonalFoodCopyWithImpl;
@override @useResult
$Res call({
 String id, List<String> names, List<String> aliases, String state, BuddyNutrients nutrients, List<BuddyServing> servings
});


@override $BuddyNutrientsCopyWith<$Res> get nutrients;

}
/// @nodoc
class __$BuddyPersonalFoodCopyWithImpl<$Res>
    implements _$BuddyPersonalFoodCopyWith<$Res> {
  __$BuddyPersonalFoodCopyWithImpl(this._self, this._then);

  final _BuddyPersonalFood _self;
  final $Res Function(_BuddyPersonalFood) _then;

/// Create a copy of BuddyPersonalFood
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? names = null,Object? aliases = null,Object? state = null,Object? nutrients = null,Object? servings = null,}) {
  return _then(_BuddyPersonalFood(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,names: null == names ? _self._names : names // ignore: cast_nullable_to_non_nullable
as List<String>,aliases: null == aliases ? _self._aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,nutrients: null == nutrients ? _self.nutrients : nutrients // ignore: cast_nullable_to_non_nullable
as BuddyNutrients,servings: null == servings ? _self._servings : servings // ignore: cast_nullable_to_non_nullable
as List<BuddyServing>,
  ));
}

/// Create a copy of BuddyPersonalFood
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyNutrientsCopyWith<$Res> get nutrients {
  
  return $BuddyNutrientsCopyWith<$Res>(_self.nutrients, (value) {
    return _then(_self.copyWith(nutrients: value));
  });
}
}

// dart format on
