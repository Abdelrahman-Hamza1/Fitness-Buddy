// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_import_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyImportRow {

 String? get date; double? get value;/// The unit as written, or null ("110k" keeps "k").
 String? get unit; String get original;
/// Create a copy of BuddyImportRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyImportRowCopyWith<BuddyImportRow> get copyWith => _$BuddyImportRowCopyWithImpl<BuddyImportRow>(this as BuddyImportRow, _$identity);

  /// Serializes this BuddyImportRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyImportRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyImportRow&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.original, _this.original) || other.original == _this.original));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyImportRow;
  return Object.hash(runtimeType,_this.date,_this.value,_this.unit,_this.original);
}

@override
String toString() {
  final _this = this as BuddyImportRow;
  return 'BuddyImportRow(date: ${_this.date}, value: ${_this.value}, unit: ${_this.unit}, original: ${_this.original})';
}


}

/// @nodoc
abstract mixin class $BuddyImportRowCopyWith<$Res>  {
  factory $BuddyImportRowCopyWith(BuddyImportRow value, $Res Function(BuddyImportRow) _then) = _$BuddyImportRowCopyWithImpl;
@useResult
$Res call({
 String? date, double? value, String? unit, String original
});




}
/// @nodoc
class _$BuddyImportRowCopyWithImpl<$Res>
    implements $BuddyImportRowCopyWith<$Res> {
  _$BuddyImportRowCopyWithImpl(this._self, this._then);

  final BuddyImportRow _self;
  final $Res Function(BuddyImportRow) _then;

/// Create a copy of BuddyImportRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = freezed,Object? value = freezed,Object? unit = freezed,Object? original = null,}) {
  return _then(BuddyImportRow(
date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyImportRow].
extension BuddyImportRowPatterns on BuddyImportRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyImportRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyImportRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyImportRow value)  $default,){
final _that = this;
switch (_that) {
case _BuddyImportRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyImportRow value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyImportRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? date,  double? value,  String? unit,  String original)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyImportRow() when $default != null:
return $default(_that.date,_that.value,_that.unit,_that.original);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? date,  double? value,  String? unit,  String original)  $default,) {final _that = this;
switch (_that) {
case _BuddyImportRow():
return $default(_that.date,_that.value,_that.unit,_that.original);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? date,  double? value,  String? unit,  String original)?  $default,) {final _that = this;
switch (_that) {
case _BuddyImportRow() when $default != null:
return $default(_that.date,_that.value,_that.unit,_that.original);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyImportRow implements BuddyImportRow {
  const _BuddyImportRow({required this.date, required this.value, required this.unit, required this.original});
  factory _BuddyImportRow.fromJson(Map<String, dynamic> json) => _$BuddyImportRowFromJson(json);

@override final  String? date;
@override final  double? value;
/// The unit as written, or null ("110k" keeps "k").
@override final  String? unit;
@override final  String original;

/// Create a copy of BuddyImportRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyImportRowCopyWith<_BuddyImportRow> get copyWith => __$BuddyImportRowCopyWithImpl<_BuddyImportRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyImportRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyImportRow&&(identical(other.date, date) || other.date == date)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.original, original) || other.original == original));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,value,unit,original);
}

@override
String toString() {
    return 'BuddyImportRow(date: $date, value: $value, unit: $unit, original: $original)';
}


}

/// @nodoc
abstract mixin class _$BuddyImportRowCopyWith<$Res> implements $BuddyImportRowCopyWith<$Res> {
  factory _$BuddyImportRowCopyWith(_BuddyImportRow value, $Res Function(_BuddyImportRow) _then) = __$BuddyImportRowCopyWithImpl;
@override @useResult
$Res call({
 String? date, double? value, String? unit, String original
});




}
/// @nodoc
class __$BuddyImportRowCopyWithImpl<$Res>
    implements _$BuddyImportRowCopyWith<$Res> {
  __$BuddyImportRowCopyWithImpl(this._self, this._then);

  final _BuddyImportRow _self;
  final $Res Function(_BuddyImportRow) _then;

/// Create a copy of BuddyImportRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = freezed,Object? value = freezed,Object? unit = freezed,Object? original = null,}) {
  return _then(_BuddyImportRow(
date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
