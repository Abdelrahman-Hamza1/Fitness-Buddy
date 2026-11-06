// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_diary_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyDiaryRow {

 String get name; String get id; String get date; String get slot; double? get grams; double? get kcal;
/// Create a copy of BuddyDiaryRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyDiaryRowCopyWith<BuddyDiaryRow> get copyWith => _$BuddyDiaryRowCopyWithImpl<BuddyDiaryRow>(this as BuddyDiaryRow, _$identity);

  /// Serializes this BuddyDiaryRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyDiaryRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyDiaryRow&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.slot, _this.slot) || other.slot == _this.slot)&&(identical(other.grams, _this.grams) || other.grams == _this.grams)&&(identical(other.kcal, _this.kcal) || other.kcal == _this.kcal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyDiaryRow;
  return Object.hash(runtimeType,_this.name,_this.id,_this.date,_this.slot,_this.grams,_this.kcal);
}

@override
String toString() {
  final _this = this as BuddyDiaryRow;
  return 'BuddyDiaryRow(name: ${_this.name}, id: ${_this.id}, date: ${_this.date}, slot: ${_this.slot}, grams: ${_this.grams}, kcal: ${_this.kcal})';
}


}

/// @nodoc
abstract mixin class $BuddyDiaryRowCopyWith<$Res>  {
  factory $BuddyDiaryRowCopyWith(BuddyDiaryRow value, $Res Function(BuddyDiaryRow) _then) = _$BuddyDiaryRowCopyWithImpl;
@useResult
$Res call({
 String name, String id, String date, String slot, double? grams, double? kcal
});




}
/// @nodoc
class _$BuddyDiaryRowCopyWithImpl<$Res>
    implements $BuddyDiaryRowCopyWith<$Res> {
  _$BuddyDiaryRowCopyWithImpl(this._self, this._then);

  final BuddyDiaryRow _self;
  final $Res Function(BuddyDiaryRow) _then;

/// Create a copy of BuddyDiaryRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? id = null,Object? date = null,Object? slot = null,Object? grams = freezed,Object? kcal = freezed,}) {
  return _then(BuddyDiaryRow(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String,grams: freezed == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as double?,kcal: freezed == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyDiaryRow].
extension BuddyDiaryRowPatterns on BuddyDiaryRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyDiaryRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyDiaryRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyDiaryRow value)  $default,){
final _that = this;
switch (_that) {
case _BuddyDiaryRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyDiaryRow value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyDiaryRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String id,  String date,  String slot,  double? grams,  double? kcal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyDiaryRow() when $default != null:
return $default(_that.name,_that.id,_that.date,_that.slot,_that.grams,_that.kcal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String id,  String date,  String slot,  double? grams,  double? kcal)  $default,) {final _that = this;
switch (_that) {
case _BuddyDiaryRow():
return $default(_that.name,_that.id,_that.date,_that.slot,_that.grams,_that.kcal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String id,  String date,  String slot,  double? grams,  double? kcal)?  $default,) {final _that = this;
switch (_that) {
case _BuddyDiaryRow() when $default != null:
return $default(_that.name,_that.id,_that.date,_that.slot,_that.grams,_that.kcal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyDiaryRow implements BuddyDiaryRow {
  const _BuddyDiaryRow({required this.name, required this.id, required this.date, required this.slot, required this.grams, required this.kcal});
  factory _BuddyDiaryRow.fromJson(Map<String, dynamic> json) => _$BuddyDiaryRowFromJson(json);

@override final  String name;
@override final  String id;
@override final  String date;
@override final  String slot;
@override final  double? grams;
@override final  double? kcal;

/// Create a copy of BuddyDiaryRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyDiaryRowCopyWith<_BuddyDiaryRow> get copyWith => __$BuddyDiaryRowCopyWithImpl<_BuddyDiaryRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyDiaryRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyDiaryRow&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.grams, grams) || other.grams == grams)&&(identical(other.kcal, kcal) || other.kcal == kcal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,id,date,slot,grams,kcal);
}

@override
String toString() {
    return 'BuddyDiaryRow(name: $name, id: $id, date: $date, slot: $slot, grams: $grams, kcal: $kcal)';
}


}

/// @nodoc
abstract mixin class _$BuddyDiaryRowCopyWith<$Res> implements $BuddyDiaryRowCopyWith<$Res> {
  factory _$BuddyDiaryRowCopyWith(_BuddyDiaryRow value, $Res Function(_BuddyDiaryRow) _then) = __$BuddyDiaryRowCopyWithImpl;
@override @useResult
$Res call({
 String name, String id, String date, String slot, double? grams, double? kcal
});




}
/// @nodoc
class __$BuddyDiaryRowCopyWithImpl<$Res>
    implements _$BuddyDiaryRowCopyWith<$Res> {
  __$BuddyDiaryRowCopyWithImpl(this._self, this._then);

  final _BuddyDiaryRow _self;
  final $Res Function(_BuddyDiaryRow) _then;

/// Create a copy of BuddyDiaryRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? id = null,Object? date = null,Object? slot = null,Object? grams = freezed,Object? kcal = freezed,}) {
  return _then(_BuddyDiaryRow(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String,grams: freezed == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as double?,kcal: freezed == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
