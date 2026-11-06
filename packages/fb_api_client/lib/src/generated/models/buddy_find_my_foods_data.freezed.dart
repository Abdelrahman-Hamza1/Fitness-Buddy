// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_find_my_foods_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyFindMyFoodsData {

 List<BuddyPersonalItem> get items;
/// Create a copy of BuddyFindMyFoodsData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyFindMyFoodsDataCopyWith<BuddyFindMyFoodsData> get copyWith => _$BuddyFindMyFoodsDataCopyWithImpl<BuddyFindMyFoodsData>(this as BuddyFindMyFoodsData, _$identity);

  /// Serializes this BuddyFindMyFoodsData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyFindMyFoodsData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyFindMyFoodsData&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyFindMyFoodsData;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as BuddyFindMyFoodsData;
  return 'BuddyFindMyFoodsData(items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $BuddyFindMyFoodsDataCopyWith<$Res>  {
  factory $BuddyFindMyFoodsDataCopyWith(BuddyFindMyFoodsData value, $Res Function(BuddyFindMyFoodsData) _then) = _$BuddyFindMyFoodsDataCopyWithImpl;
@useResult
$Res call({
 List<BuddyPersonalItem> items
});




}
/// @nodoc
class _$BuddyFindMyFoodsDataCopyWithImpl<$Res>
    implements $BuddyFindMyFoodsDataCopyWith<$Res> {
  _$BuddyFindMyFoodsDataCopyWithImpl(this._self, this._then);

  final BuddyFindMyFoodsData _self;
  final $Res Function(BuddyFindMyFoodsData) _then;

/// Create a copy of BuddyFindMyFoodsData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(BuddyFindMyFoodsData(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<BuddyPersonalItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyFindMyFoodsData].
extension BuddyFindMyFoodsDataPatterns on BuddyFindMyFoodsData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyFindMyFoodsData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyFindMyFoodsData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyFindMyFoodsData value)  $default,){
final _that = this;
switch (_that) {
case _BuddyFindMyFoodsData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyFindMyFoodsData value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyFindMyFoodsData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BuddyPersonalItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyFindMyFoodsData() when $default != null:
return $default(_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BuddyPersonalItem> items)  $default,) {final _that = this;
switch (_that) {
case _BuddyFindMyFoodsData():
return $default(_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BuddyPersonalItem> items)?  $default,) {final _that = this;
switch (_that) {
case _BuddyFindMyFoodsData() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyFindMyFoodsData implements BuddyFindMyFoodsData {
  const _BuddyFindMyFoodsData({required  List<BuddyPersonalItem> items}): _items = items;
  factory _BuddyFindMyFoodsData.fromJson(Map<String, dynamic> json) => _$BuddyFindMyFoodsDataFromJson(json);

 final  List<BuddyPersonalItem> _items;
@override List<BuddyPersonalItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of BuddyFindMyFoodsData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyFindMyFoodsDataCopyWith<_BuddyFindMyFoodsData> get copyWith => __$BuddyFindMyFoodsDataCopyWithImpl<_BuddyFindMyFoodsData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyFindMyFoodsDataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyFindMyFoodsData&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'BuddyFindMyFoodsData(items: $items)';
}


}

/// @nodoc
abstract mixin class _$BuddyFindMyFoodsDataCopyWith<$Res> implements $BuddyFindMyFoodsDataCopyWith<$Res> {
  factory _$BuddyFindMyFoodsDataCopyWith(_BuddyFindMyFoodsData value, $Res Function(_BuddyFindMyFoodsData) _then) = __$BuddyFindMyFoodsDataCopyWithImpl;
@override @useResult
$Res call({
 List<BuddyPersonalItem> items
});




}
/// @nodoc
class __$BuddyFindMyFoodsDataCopyWithImpl<$Res>
    implements _$BuddyFindMyFoodsDataCopyWith<$Res> {
  __$BuddyFindMyFoodsDataCopyWithImpl(this._self, this._then);

  final _BuddyFindMyFoodsData _self;
  final $Res Function(_BuddyFindMyFoodsData) _then;

/// Create a copy of BuddyFindMyFoodsData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_BuddyFindMyFoodsData(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BuddyPersonalItem>,
  ));
}


}

// dart format on
