// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_personal_food_create.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyPersonalFoodCreate {

 BuddyPersonalFoodCreateKind get kind; String get language; String get script; String get name; List<String> get aliases;/// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
 List<BuddyFoodItem> get components; BuddyStatedNutrients? get stated;
/// Create a copy of BuddyPersonalFoodCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPersonalFoodCreateCopyWith<BuddyPersonalFoodCreate> get copyWith => _$BuddyPersonalFoodCreateCopyWithImpl<BuddyPersonalFoodCreate>(this as BuddyPersonalFoodCreate, _$identity);

  /// Serializes this BuddyPersonalFoodCreate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyPersonalFoodCreate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPersonalFoodCreate&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.aliases, _this.aliases)&&const DeepCollectionEquality().equals(other.components, _this.components)&&(identical(other.stated, _this.stated) || other.stated == _this.stated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyPersonalFoodCreate;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.name,const DeepCollectionEquality().hash(_this.aliases),const DeepCollectionEquality().hash(_this.components),_this.stated);
}

@override
String toString() {
  final _this = this as BuddyPersonalFoodCreate;
  return 'BuddyPersonalFoodCreate(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, name: ${_this.name}, aliases: ${_this.aliases}, components: ${_this.components}, stated: ${_this.stated})';
}


}

/// @nodoc
abstract mixin class $BuddyPersonalFoodCreateCopyWith<$Res>  {
  factory $BuddyPersonalFoodCreateCopyWith(BuddyPersonalFoodCreate value, $Res Function(BuddyPersonalFoodCreate) _then) = _$BuddyPersonalFoodCreateCopyWithImpl;
@useResult
$Res call({
 BuddyPersonalFoodCreateKind kind, String language, String script, String name, List<String> aliases, List<BuddyFoodItem> components, BuddyStatedNutrients? stated
});


$BuddyStatedNutrientsCopyWith<$Res>? get stated;

}
/// @nodoc
class _$BuddyPersonalFoodCreateCopyWithImpl<$Res>
    implements $BuddyPersonalFoodCreateCopyWith<$Res> {
  _$BuddyPersonalFoodCreateCopyWithImpl(this._self, this._then);

  final BuddyPersonalFoodCreate _self;
  final $Res Function(BuddyPersonalFoodCreate) _then;

/// Create a copy of BuddyPersonalFoodCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? name = null,Object? aliases = null,Object? components = null,Object? stated = freezed,}) {
  return _then(BuddyPersonalFoodCreate(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyPersonalFoodCreateKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,aliases: null == aliases ? _self.aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,components: null == components ? _self.components : components // ignore: cast_nullable_to_non_nullable
as List<BuddyFoodItem>,stated: freezed == stated ? _self.stated : stated // ignore: cast_nullable_to_non_nullable
as BuddyStatedNutrients?,
  ));
}
/// Create a copy of BuddyPersonalFoodCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyStatedNutrientsCopyWith<$Res>? get stated {
    if (_self.stated == null) {
    return null;
  }

  return $BuddyStatedNutrientsCopyWith<$Res>(_self.stated!, (value) {
    return _then(_self.copyWith(stated: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyPersonalFoodCreate].
extension BuddyPersonalFoodCreatePatterns on BuddyPersonalFoodCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyPersonalFoodCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyPersonalFoodCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyPersonalFoodCreate value)  $default,){
final _that = this;
switch (_that) {
case _BuddyPersonalFoodCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyPersonalFoodCreate value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyPersonalFoodCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyPersonalFoodCreateKind kind,  String language,  String script,  String name,  List<String> aliases,  List<BuddyFoodItem> components,  BuddyStatedNutrients? stated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyPersonalFoodCreate() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.name,_that.aliases,_that.components,_that.stated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyPersonalFoodCreateKind kind,  String language,  String script,  String name,  List<String> aliases,  List<BuddyFoodItem> components,  BuddyStatedNutrients? stated)  $default,) {final _that = this;
switch (_that) {
case _BuddyPersonalFoodCreate():
return $default(_that.kind,_that.language,_that.script,_that.name,_that.aliases,_that.components,_that.stated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyPersonalFoodCreateKind kind,  String language,  String script,  String name,  List<String> aliases,  List<BuddyFoodItem> components,  BuddyStatedNutrients? stated)?  $default,) {final _that = this;
switch (_that) {
case _BuddyPersonalFoodCreate() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.name,_that.aliases,_that.components,_that.stated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyPersonalFoodCreate implements BuddyPersonalFoodCreate {
  const _BuddyPersonalFoodCreate({required this.kind, required this.language, required this.script, required this.name, required  List<String> aliases, required  List<BuddyFoodItem> components, required this.stated}): _aliases = aliases,_components = components;
  factory _BuddyPersonalFoodCreate.fromJson(Map<String, dynamic> json) => _$BuddyPersonalFoodCreateFromJson(json);

@override final  BuddyPersonalFoodCreateKind kind;
@override final  String language;
@override final  String script;
@override final  String name;
 final  List<String> _aliases;
@override List<String> get aliases {
  if (_aliases is EqualUnmodifiableListView) return _aliases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_aliases);
}

/// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
 final  List<BuddyFoodItem> _components;
/// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
@override List<BuddyFoodItem> get components {
  if (_components is EqualUnmodifiableListView) return _components;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_components);
}

@override final  BuddyStatedNutrients? stated;

/// Create a copy of BuddyPersonalFoodCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyPersonalFoodCreateCopyWith<_BuddyPersonalFoodCreate> get copyWith => __$BuddyPersonalFoodCreateCopyWithImpl<_BuddyPersonalFoodCreate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPersonalFoodCreateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyPersonalFoodCreate&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.aliases, _aliases)&&const DeepCollectionEquality().equals(other.components, _components)&&(identical(other.stated, stated) || other.stated == stated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,name,const DeepCollectionEquality().hash(_aliases),const DeepCollectionEquality().hash(_components),stated);
}

@override
String toString() {
    return 'BuddyPersonalFoodCreate(kind: $kind, language: $language, script: $script, name: $name, aliases: $aliases, components: $components, stated: $stated)';
}


}

/// @nodoc
abstract mixin class _$BuddyPersonalFoodCreateCopyWith<$Res> implements $BuddyPersonalFoodCreateCopyWith<$Res> {
  factory _$BuddyPersonalFoodCreateCopyWith(_BuddyPersonalFoodCreate value, $Res Function(_BuddyPersonalFoodCreate) _then) = __$BuddyPersonalFoodCreateCopyWithImpl;
@override @useResult
$Res call({
 BuddyPersonalFoodCreateKind kind, String language, String script, String name, List<String> aliases, List<BuddyFoodItem> components, BuddyStatedNutrients? stated
});


@override $BuddyStatedNutrientsCopyWith<$Res>? get stated;

}
/// @nodoc
class __$BuddyPersonalFoodCreateCopyWithImpl<$Res>
    implements _$BuddyPersonalFoodCreateCopyWith<$Res> {
  __$BuddyPersonalFoodCreateCopyWithImpl(this._self, this._then);

  final _BuddyPersonalFoodCreate _self;
  final $Res Function(_BuddyPersonalFoodCreate) _then;

/// Create a copy of BuddyPersonalFoodCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? name = null,Object? aliases = null,Object? components = null,Object? stated = freezed,}) {
  return _then(_BuddyPersonalFoodCreate(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyPersonalFoodCreateKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,aliases: null == aliases ? _self._aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,components: null == components ? _self._components : components // ignore: cast_nullable_to_non_nullable
as List<BuddyFoodItem>,stated: freezed == stated ? _self.stated : stated // ignore: cast_nullable_to_non_nullable
as BuddyStatedNutrients?,
  ));
}

/// Create a copy of BuddyPersonalFoodCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyStatedNutrientsCopyWith<$Res>? get stated {
    if (_self.stated == null) {
    return null;
  }

  return $BuddyStatedNutrientsCopyWith<$Res>(_self.stated!, (value) {
    return _then(_self.copyWith(stated: value));
  });
}
}

// dart format on
