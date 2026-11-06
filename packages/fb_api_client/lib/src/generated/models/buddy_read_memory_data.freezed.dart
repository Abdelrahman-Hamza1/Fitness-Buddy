// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_memory_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadMemoryData {

 List<BuddyMemory> get items;
/// Create a copy of BuddyReadMemoryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadMemoryDataCopyWith<BuddyReadMemoryData> get copyWith => _$BuddyReadMemoryDataCopyWithImpl<BuddyReadMemoryData>(this as BuddyReadMemoryData, _$identity);

  /// Serializes this BuddyReadMemoryData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadMemoryData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadMemoryData&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadMemoryData;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as BuddyReadMemoryData;
  return 'BuddyReadMemoryData(items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $BuddyReadMemoryDataCopyWith<$Res>  {
  factory $BuddyReadMemoryDataCopyWith(BuddyReadMemoryData value, $Res Function(BuddyReadMemoryData) _then) = _$BuddyReadMemoryDataCopyWithImpl;
@useResult
$Res call({
 List<BuddyMemory> items
});




}
/// @nodoc
class _$BuddyReadMemoryDataCopyWithImpl<$Res>
    implements $BuddyReadMemoryDataCopyWith<$Res> {
  _$BuddyReadMemoryDataCopyWithImpl(this._self, this._then);

  final BuddyReadMemoryData _self;
  final $Res Function(BuddyReadMemoryData) _then;

/// Create a copy of BuddyReadMemoryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(BuddyReadMemoryData(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<BuddyMemory>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyReadMemoryData].
extension BuddyReadMemoryDataPatterns on BuddyReadMemoryData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadMemoryData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadMemoryData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadMemoryData value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadMemoryData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadMemoryData value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadMemoryData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BuddyMemory> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadMemoryData() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BuddyMemory> items)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadMemoryData():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BuddyMemory> items)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadMemoryData() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadMemoryData implements BuddyReadMemoryData {
  const _BuddyReadMemoryData({required  List<BuddyMemory> items}): _items = items;
  factory _BuddyReadMemoryData.fromJson(Map<String, dynamic> json) => _$BuddyReadMemoryDataFromJson(json);

 final  List<BuddyMemory> _items;
@override List<BuddyMemory> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of BuddyReadMemoryData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadMemoryDataCopyWith<_BuddyReadMemoryData> get copyWith => __$BuddyReadMemoryDataCopyWithImpl<_BuddyReadMemoryData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadMemoryDataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadMemoryData&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'BuddyReadMemoryData(items: $items)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadMemoryDataCopyWith<$Res> implements $BuddyReadMemoryDataCopyWith<$Res> {
  factory _$BuddyReadMemoryDataCopyWith(_BuddyReadMemoryData value, $Res Function(_BuddyReadMemoryData) _then) = __$BuddyReadMemoryDataCopyWithImpl;
@override @useResult
$Res call({
 List<BuddyMemory> items
});




}
/// @nodoc
class __$BuddyReadMemoryDataCopyWithImpl<$Res>
    implements _$BuddyReadMemoryDataCopyWith<$Res> {
  __$BuddyReadMemoryDataCopyWithImpl(this._self, this._then);

  final _BuddyReadMemoryData _self;
  final $Res Function(_BuddyReadMemoryData) _then;

/// Create a copy of BuddyReadMemoryData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_BuddyReadMemoryData(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BuddyMemory>,
  ));
}


}

// dart format on
