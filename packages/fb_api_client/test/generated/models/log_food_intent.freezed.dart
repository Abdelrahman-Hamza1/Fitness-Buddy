// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'log_food_intent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LogFoodIntent {

 String get kind; List<FoodItem> get items; Instant get eatenAt; LocalDate? get date;
/// Create a copy of LogFoodIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogFoodIntentCopyWith<LogFoodIntent> get copyWith => _$LogFoodIntentCopyWithImpl<LogFoodIntent>(this as LogFoodIntent, _$identity);

  /// Serializes this LogFoodIntent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LogFoodIntent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogFoodIntent&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.eatenAt, _this.eatenAt) || other.eatenAt == _this.eatenAt)&&(identical(other.date, _this.date) || other.date == _this.date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LogFoodIntent;
  return Object.hash(runtimeType,_this.kind,const DeepCollectionEquality().hash(_this.items),_this.eatenAt,_this.date);
}

@override
String toString() {
  final _this = this as LogFoodIntent;
  return 'LogFoodIntent(kind: ${_this.kind}, items: ${_this.items}, eatenAt: ${_this.eatenAt}, date: ${_this.date})';
}


}

/// @nodoc
abstract mixin class $LogFoodIntentCopyWith<$Res>  {
  factory $LogFoodIntentCopyWith(LogFoodIntent value, $Res Function(LogFoodIntent) _then) = _$LogFoodIntentCopyWithImpl;
@useResult
$Res call({
 String kind, List<FoodItem> items, Instant eatenAt, LocalDate? date
});




}
/// @nodoc
class _$LogFoodIntentCopyWithImpl<$Res>
    implements $LogFoodIntentCopyWith<$Res> {
  _$LogFoodIntentCopyWithImpl(this._self, this._then);

  final LogFoodIntent _self;
  final $Res Function(LogFoodIntent) _then;

/// Create a copy of LogFoodIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? items = null,Object? eatenAt = null,Object? date = freezed,}) {
  return _then(LogFoodIntent(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<FoodItem>,eatenAt: null == eatenAt ? _self.eatenAt : eatenAt // ignore: cast_nullable_to_non_nullable
as Instant,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate?,
  ));
}

}


/// Adds pattern-matching-related methods to [LogFoodIntent].
extension LogFoodIntentPatterns on LogFoodIntent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LogFoodIntent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LogFoodIntent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LogFoodIntent value)  $default,){
final _that = this;
switch (_that) {
case _LogFoodIntent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LogFoodIntent value)?  $default,){
final _that = this;
switch (_that) {
case _LogFoodIntent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  List<FoodItem> items,  Instant eatenAt,  LocalDate? date)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LogFoodIntent() when $default != null:
return $default(_that.kind,_that.items,_that.eatenAt,_that.date);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  List<FoodItem> items,  Instant eatenAt,  LocalDate? date)  $default,) {final _that = this;
switch (_that) {
case _LogFoodIntent():
return $default(_that.kind,_that.items,_that.eatenAt,_that.date);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  List<FoodItem> items,  Instant eatenAt,  LocalDate? date)?  $default,) {final _that = this;
switch (_that) {
case _LogFoodIntent() when $default != null:
return $default(_that.kind,_that.items,_that.eatenAt,_that.date);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LogFoodIntent implements LogFoodIntent {
  const _LogFoodIntent({required this.kind, required  List<FoodItem> items, required this.eatenAt, required this.date}): _items = items;
  factory _LogFoodIntent.fromJson(Map<String, dynamic> json) => _$LogFoodIntentFromJson(json);

@override final  String kind;
 final  List<FoodItem> _items;
@override List<FoodItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  Instant eatenAt;
@override final  LocalDate? date;

/// Create a copy of LogFoodIntent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LogFoodIntentCopyWith<_LogFoodIntent> get copyWith => __$LogFoodIntentCopyWithImpl<_LogFoodIntent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LogFoodIntentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LogFoodIntent&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.eatenAt, eatenAt) || other.eatenAt == eatenAt)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(_items),eatenAt,date);
}

@override
String toString() {
    return 'LogFoodIntent(kind: $kind, items: $items, eatenAt: $eatenAt, date: $date)';
}


}

/// @nodoc
abstract mixin class _$LogFoodIntentCopyWith<$Res> implements $LogFoodIntentCopyWith<$Res> {
  factory _$LogFoodIntentCopyWith(_LogFoodIntent value, $Res Function(_LogFoodIntent) _then) = __$LogFoodIntentCopyWithImpl;
@override @useResult
$Res call({
 String kind, List<FoodItem> items, Instant eatenAt, LocalDate? date
});




}
/// @nodoc
class __$LogFoodIntentCopyWithImpl<$Res>
    implements _$LogFoodIntentCopyWith<$Res> {
  __$LogFoodIntentCopyWithImpl(this._self, this._then);

  final _LogFoodIntent _self;
  final $Res Function(_LogFoodIntent) _then;

/// Create a copy of LogFoodIntent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? items = null,Object? eatenAt = null,Object? date = freezed,}) {
  return _then(_LogFoodIntent(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<FoodItem>,eatenAt: null == eatenAt ? _self.eatenAt : eatenAt // ignore: cast_nullable_to_non_nullable
as Instant,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate?,
  ));
}


}

// dart format on
