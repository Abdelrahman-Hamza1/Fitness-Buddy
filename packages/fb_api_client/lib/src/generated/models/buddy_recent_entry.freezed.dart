// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_recent_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyRecentEntry {

 String get id; String get date; String get slot; String get name; double? get grams;
/// Create a copy of BuddyRecentEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyRecentEntryCopyWith<BuddyRecentEntry> get copyWith => _$BuddyRecentEntryCopyWithImpl<BuddyRecentEntry>(this as BuddyRecentEntry, _$identity);

  /// Serializes this BuddyRecentEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyRecentEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyRecentEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.slot, _this.slot) || other.slot == _this.slot)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.grams, _this.grams) || other.grams == _this.grams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyRecentEntry;
  return Object.hash(runtimeType,_this.id,_this.date,_this.slot,_this.name,_this.grams);
}

@override
String toString() {
  final _this = this as BuddyRecentEntry;
  return 'BuddyRecentEntry(id: ${_this.id}, date: ${_this.date}, slot: ${_this.slot}, name: ${_this.name}, grams: ${_this.grams})';
}


}

/// @nodoc
abstract mixin class $BuddyRecentEntryCopyWith<$Res>  {
  factory $BuddyRecentEntryCopyWith(BuddyRecentEntry value, $Res Function(BuddyRecentEntry) _then) = _$BuddyRecentEntryCopyWithImpl;
@useResult
$Res call({
 String id, String date, String slot, String name, double? grams
});




}
/// @nodoc
class _$BuddyRecentEntryCopyWithImpl<$Res>
    implements $BuddyRecentEntryCopyWith<$Res> {
  _$BuddyRecentEntryCopyWithImpl(this._self, this._then);

  final BuddyRecentEntry _self;
  final $Res Function(BuddyRecentEntry) _then;

/// Create a copy of BuddyRecentEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? slot = null,Object? name = null,Object? grams = freezed,}) {
  return _then(BuddyRecentEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,grams: freezed == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyRecentEntry].
extension BuddyRecentEntryPatterns on BuddyRecentEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyRecentEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyRecentEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyRecentEntry value)  $default,){
final _that = this;
switch (_that) {
case _BuddyRecentEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyRecentEntry value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyRecentEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String date,  String slot,  String name,  double? grams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyRecentEntry() when $default != null:
return $default(_that.id,_that.date,_that.slot,_that.name,_that.grams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String date,  String slot,  String name,  double? grams)  $default,) {final _that = this;
switch (_that) {
case _BuddyRecentEntry():
return $default(_that.id,_that.date,_that.slot,_that.name,_that.grams);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String date,  String slot,  String name,  double? grams)?  $default,) {final _that = this;
switch (_that) {
case _BuddyRecentEntry() when $default != null:
return $default(_that.id,_that.date,_that.slot,_that.name,_that.grams);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyRecentEntry implements BuddyRecentEntry {
  const _BuddyRecentEntry({required this.id, required this.date, required this.slot, required this.name, required this.grams});
  factory _BuddyRecentEntry.fromJson(Map<String, dynamic> json) => _$BuddyRecentEntryFromJson(json);

@override final  String id;
@override final  String date;
@override final  String slot;
@override final  String name;
@override final  double? grams;

/// Create a copy of BuddyRecentEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyRecentEntryCopyWith<_BuddyRecentEntry> get copyWith => __$BuddyRecentEntryCopyWithImpl<_BuddyRecentEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyRecentEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyRecentEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.name, name) || other.name == name)&&(identical(other.grams, grams) || other.grams == grams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,date,slot,name,grams);
}

@override
String toString() {
    return 'BuddyRecentEntry(id: $id, date: $date, slot: $slot, name: $name, grams: $grams)';
}


}

/// @nodoc
abstract mixin class _$BuddyRecentEntryCopyWith<$Res> implements $BuddyRecentEntryCopyWith<$Res> {
  factory _$BuddyRecentEntryCopyWith(_BuddyRecentEntry value, $Res Function(_BuddyRecentEntry) _then) = __$BuddyRecentEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String date, String slot, String name, double? grams
});




}
/// @nodoc
class __$BuddyRecentEntryCopyWithImpl<$Res>
    implements _$BuddyRecentEntryCopyWith<$Res> {
  __$BuddyRecentEntryCopyWithImpl(this._self, this._then);

  final _BuddyRecentEntry _self;
  final $Res Function(_BuddyRecentEntry) _then;

/// Create a copy of BuddyRecentEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? slot = null,Object? name = null,Object? grams = freezed,}) {
  return _then(_BuddyRecentEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,grams: freezed == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
