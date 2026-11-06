// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_diary_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadDiaryData {

 List<BuddyDiaryRow> get entries;/// True when the scope cut the rows.
 bool get truncated;
/// Create a copy of BuddyReadDiaryData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadDiaryDataCopyWith<BuddyReadDiaryData> get copyWith => _$BuddyReadDiaryDataCopyWithImpl<BuddyReadDiaryData>(this as BuddyReadDiaryData, _$identity);

  /// Serializes this BuddyReadDiaryData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadDiaryData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadDiaryData&&const DeepCollectionEquality().equals(other.entries, _this.entries)&&(identical(other.truncated, _this.truncated) || other.truncated == _this.truncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadDiaryData;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.entries),_this.truncated);
}

@override
String toString() {
  final _this = this as BuddyReadDiaryData;
  return 'BuddyReadDiaryData(entries: ${_this.entries}, truncated: ${_this.truncated})';
}


}

/// @nodoc
abstract mixin class $BuddyReadDiaryDataCopyWith<$Res>  {
  factory $BuddyReadDiaryDataCopyWith(BuddyReadDiaryData value, $Res Function(BuddyReadDiaryData) _then) = _$BuddyReadDiaryDataCopyWithImpl;
@useResult
$Res call({
 List<BuddyDiaryRow> entries, bool truncated
});




}
/// @nodoc
class _$BuddyReadDiaryDataCopyWithImpl<$Res>
    implements $BuddyReadDiaryDataCopyWith<$Res> {
  _$BuddyReadDiaryDataCopyWithImpl(this._self, this._then);

  final BuddyReadDiaryData _self;
  final $Res Function(BuddyReadDiaryData) _then;

/// Create a copy of BuddyReadDiaryData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,Object? truncated = null,}) {
  return _then(BuddyReadDiaryData(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<BuddyDiaryRow>,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyReadDiaryData].
extension BuddyReadDiaryDataPatterns on BuddyReadDiaryData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadDiaryData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadDiaryData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadDiaryData value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadDiaryData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadDiaryData value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadDiaryData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BuddyDiaryRow> entries,  bool truncated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadDiaryData() when $default != null:
return $default(_that.entries,_that.truncated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BuddyDiaryRow> entries,  bool truncated)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadDiaryData():
return $default(_that.entries,_that.truncated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BuddyDiaryRow> entries,  bool truncated)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadDiaryData() when $default != null:
return $default(_that.entries,_that.truncated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadDiaryData implements BuddyReadDiaryData {
  const _BuddyReadDiaryData({required  List<BuddyDiaryRow> entries, required this.truncated}): _entries = entries;
  factory _BuddyReadDiaryData.fromJson(Map<String, dynamic> json) => _$BuddyReadDiaryDataFromJson(json);

 final  List<BuddyDiaryRow> _entries;
@override List<BuddyDiaryRow> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

/// True when the scope cut the rows.
@override final  bool truncated;

/// Create a copy of BuddyReadDiaryData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadDiaryDataCopyWith<_BuddyReadDiaryData> get copyWith => __$BuddyReadDiaryDataCopyWithImpl<_BuddyReadDiaryData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadDiaryDataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadDiaryData&&const DeepCollectionEquality().equals(other.entries, _entries)&&(identical(other.truncated, truncated) || other.truncated == truncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries),truncated);
}

@override
String toString() {
    return 'BuddyReadDiaryData(entries: $entries, truncated: $truncated)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadDiaryDataCopyWith<$Res> implements $BuddyReadDiaryDataCopyWith<$Res> {
  factory _$BuddyReadDiaryDataCopyWith(_BuddyReadDiaryData value, $Res Function(_BuddyReadDiaryData) _then) = __$BuddyReadDiaryDataCopyWithImpl;
@override @useResult
$Res call({
 List<BuddyDiaryRow> entries, bool truncated
});




}
/// @nodoc
class __$BuddyReadDiaryDataCopyWithImpl<$Res>
    implements _$BuddyReadDiaryDataCopyWith<$Res> {
  __$BuddyReadDiaryDataCopyWithImpl(this._self, this._then);

  final _BuddyReadDiaryData _self;
  final $Res Function(_BuddyReadDiaryData) _then;

/// Create a copy of BuddyReadDiaryData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entries = null,Object? truncated = null,}) {
  return _then(_BuddyReadDiaryData(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<BuddyDiaryRow>,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
