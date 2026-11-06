// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_personal_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyPersonalItem {

 BuddyPersonalKind get kind;/// The local row ID (a usual meal uses its representative row's ID). Mapped to a handle; never sent to the model.
 String get ref; List<String> get names; List<String> get aliases; String? get state;/// Nutrients per 100 g (personal foods, batches), or null.
 BuddyNutrientsRequest? get per100; List<BuddyServing> get servings;/// Named portions with their nutrients: a saved meal's whole meal, a batch's portion or remaining amount.
 List<BuddyPortionFacts> get portions;
/// Create a copy of BuddyPersonalItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPersonalItemCopyWith<BuddyPersonalItem> get copyWith => _$BuddyPersonalItemCopyWithImpl<BuddyPersonalItem>(this as BuddyPersonalItem, _$identity);

  /// Serializes this BuddyPersonalItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyPersonalItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPersonalItem&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.ref, _this.ref) || other.ref == _this.ref)&&const DeepCollectionEquality().equals(other.names, _this.names)&&const DeepCollectionEquality().equals(other.aliases, _this.aliases)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.per100, _this.per100) || other.per100 == _this.per100)&&const DeepCollectionEquality().equals(other.servings, _this.servings)&&const DeepCollectionEquality().equals(other.portions, _this.portions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyPersonalItem;
  return Object.hash(runtimeType,_this.kind,_this.ref,const DeepCollectionEquality().hash(_this.names),const DeepCollectionEquality().hash(_this.aliases),_this.state,_this.per100,const DeepCollectionEquality().hash(_this.servings),const DeepCollectionEquality().hash(_this.portions));
}

@override
String toString() {
  final _this = this as BuddyPersonalItem;
  return 'BuddyPersonalItem(kind: ${_this.kind}, ref: ${_this.ref}, names: ${_this.names}, aliases: ${_this.aliases}, state: ${_this.state}, per100: ${_this.per100}, servings: ${_this.servings}, portions: ${_this.portions})';
}


}

/// @nodoc
abstract mixin class $BuddyPersonalItemCopyWith<$Res>  {
  factory $BuddyPersonalItemCopyWith(BuddyPersonalItem value, $Res Function(BuddyPersonalItem) _then) = _$BuddyPersonalItemCopyWithImpl;
@useResult
$Res call({
 BuddyPersonalKind kind, String ref, List<String> names, List<String> aliases, String? state, BuddyNutrientsRequest? per100, List<BuddyServing> servings, List<BuddyPortionFacts> portions
});


$BuddyNutrientsRequestCopyWith<$Res>? get per100;

}
/// @nodoc
class _$BuddyPersonalItemCopyWithImpl<$Res>
    implements $BuddyPersonalItemCopyWith<$Res> {
  _$BuddyPersonalItemCopyWithImpl(this._self, this._then);

  final BuddyPersonalItem _self;
  final $Res Function(BuddyPersonalItem) _then;

/// Create a copy of BuddyPersonalItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? ref = null,Object? names = null,Object? aliases = null,Object? state = freezed,Object? per100 = freezed,Object? servings = null,Object? portions = null,}) {
  return _then(BuddyPersonalItem(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyPersonalKind,ref: null == ref ? _self.ref : ref // ignore: cast_nullable_to_non_nullable
as String,names: null == names ? _self.names : names // ignore: cast_nullable_to_non_nullable
as List<String>,aliases: null == aliases ? _self.aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,per100: freezed == per100 ? _self.per100 : per100 // ignore: cast_nullable_to_non_nullable
as BuddyNutrientsRequest?,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as List<BuddyServing>,portions: null == portions ? _self.portions : portions // ignore: cast_nullable_to_non_nullable
as List<BuddyPortionFacts>,
  ));
}
/// Create a copy of BuddyPersonalItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyNutrientsRequestCopyWith<$Res>? get per100 {
    if (_self.per100 == null) {
    return null;
  }

  return $BuddyNutrientsRequestCopyWith<$Res>(_self.per100!, (value) {
    return _then(_self.copyWith(per100: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyPersonalItem].
extension BuddyPersonalItemPatterns on BuddyPersonalItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyPersonalItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyPersonalItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyPersonalItem value)  $default,){
final _that = this;
switch (_that) {
case _BuddyPersonalItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyPersonalItem value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyPersonalItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyPersonalKind kind,  String ref,  List<String> names,  List<String> aliases,  String? state,  BuddyNutrientsRequest? per100,  List<BuddyServing> servings,  List<BuddyPortionFacts> portions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyPersonalItem() when $default != null:
return $default(_that.kind,_that.ref,_that.names,_that.aliases,_that.state,_that.per100,_that.servings,_that.portions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyPersonalKind kind,  String ref,  List<String> names,  List<String> aliases,  String? state,  BuddyNutrientsRequest? per100,  List<BuddyServing> servings,  List<BuddyPortionFacts> portions)  $default,) {final _that = this;
switch (_that) {
case _BuddyPersonalItem():
return $default(_that.kind,_that.ref,_that.names,_that.aliases,_that.state,_that.per100,_that.servings,_that.portions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyPersonalKind kind,  String ref,  List<String> names,  List<String> aliases,  String? state,  BuddyNutrientsRequest? per100,  List<BuddyServing> servings,  List<BuddyPortionFacts> portions)?  $default,) {final _that = this;
switch (_that) {
case _BuddyPersonalItem() when $default != null:
return $default(_that.kind,_that.ref,_that.names,_that.aliases,_that.state,_that.per100,_that.servings,_that.portions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyPersonalItem implements BuddyPersonalItem {
  const _BuddyPersonalItem({required this.kind, required this.ref, required  List<String> names, required  List<String> aliases, required this.state, required this.per100, required  List<BuddyServing> servings, required  List<BuddyPortionFacts> portions}): _names = names,_aliases = aliases,_servings = servings,_portions = portions;
  factory _BuddyPersonalItem.fromJson(Map<String, dynamic> json) => _$BuddyPersonalItemFromJson(json);

@override final  BuddyPersonalKind kind;
/// The local row ID (a usual meal uses its representative row's ID). Mapped to a handle; never sent to the model.
@override final  String ref;
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

@override final  String? state;
/// Nutrients per 100 g (personal foods, batches), or null.
@override final  BuddyNutrientsRequest? per100;
 final  List<BuddyServing> _servings;
@override List<BuddyServing> get servings {
  if (_servings is EqualUnmodifiableListView) return _servings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_servings);
}

/// Named portions with their nutrients: a saved meal's whole meal, a batch's portion or remaining amount.
 final  List<BuddyPortionFacts> _portions;
/// Named portions with their nutrients: a saved meal's whole meal, a batch's portion or remaining amount.
@override List<BuddyPortionFacts> get portions {
  if (_portions is EqualUnmodifiableListView) return _portions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_portions);
}


/// Create a copy of BuddyPersonalItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyPersonalItemCopyWith<_BuddyPersonalItem> get copyWith => __$BuddyPersonalItemCopyWithImpl<_BuddyPersonalItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPersonalItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyPersonalItem&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.ref, ref) || other.ref == ref)&&const DeepCollectionEquality().equals(other.names, _names)&&const DeepCollectionEquality().equals(other.aliases, _aliases)&&(identical(other.state, state) || other.state == state)&&(identical(other.per100, per100) || other.per100 == per100)&&const DeepCollectionEquality().equals(other.servings, _servings)&&const DeepCollectionEquality().equals(other.portions, _portions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,ref,const DeepCollectionEquality().hash(_names),const DeepCollectionEquality().hash(_aliases),state,per100,const DeepCollectionEquality().hash(_servings),const DeepCollectionEquality().hash(_portions));
}

@override
String toString() {
    return 'BuddyPersonalItem(kind: $kind, ref: $ref, names: $names, aliases: $aliases, state: $state, per100: $per100, servings: $servings, portions: $portions)';
}


}

/// @nodoc
abstract mixin class _$BuddyPersonalItemCopyWith<$Res> implements $BuddyPersonalItemCopyWith<$Res> {
  factory _$BuddyPersonalItemCopyWith(_BuddyPersonalItem value, $Res Function(_BuddyPersonalItem) _then) = __$BuddyPersonalItemCopyWithImpl;
@override @useResult
$Res call({
 BuddyPersonalKind kind, String ref, List<String> names, List<String> aliases, String? state, BuddyNutrientsRequest? per100, List<BuddyServing> servings, List<BuddyPortionFacts> portions
});


@override $BuddyNutrientsRequestCopyWith<$Res>? get per100;

}
/// @nodoc
class __$BuddyPersonalItemCopyWithImpl<$Res>
    implements _$BuddyPersonalItemCopyWith<$Res> {
  __$BuddyPersonalItemCopyWithImpl(this._self, this._then);

  final _BuddyPersonalItem _self;
  final $Res Function(_BuddyPersonalItem) _then;

/// Create a copy of BuddyPersonalItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? ref = null,Object? names = null,Object? aliases = null,Object? state = freezed,Object? per100 = freezed,Object? servings = null,Object? portions = null,}) {
  return _then(_BuddyPersonalItem(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyPersonalKind,ref: null == ref ? _self.ref : ref // ignore: cast_nullable_to_non_nullable
as String,names: null == names ? _self._names : names // ignore: cast_nullable_to_non_nullable
as List<String>,aliases: null == aliases ? _self._aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,per100: freezed == per100 ? _self.per100 : per100 // ignore: cast_nullable_to_non_nullable
as BuddyNutrientsRequest?,servings: null == servings ? _self._servings : servings // ignore: cast_nullable_to_non_nullable
as List<BuddyServing>,portions: null == portions ? _self._portions : portions // ignore: cast_nullable_to_non_nullable
as List<BuddyPortionFacts>,
  ));
}

/// Create a copy of BuddyPersonalItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyNutrientsRequestCopyWith<$Res>? get per100 {
    if (_self.per100 == null) {
    return null;
  }

  return $BuddyNutrientsRequestCopyWith<$Res>(_self.per100!, (value) {
    return _then(_self.copyWith(per100: value));
  });
}
}

// dart format on
