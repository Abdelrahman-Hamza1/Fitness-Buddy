// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_suggestion_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddySuggestionOption {

 String get label; String? get slotHint; List<BuddyFoodItem> get items;
/// Create a copy of BuddySuggestionOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddySuggestionOptionCopyWith<BuddySuggestionOption> get copyWith => _$BuddySuggestionOptionCopyWithImpl<BuddySuggestionOption>(this as BuddySuggestionOption, _$identity);

  /// Serializes this BuddySuggestionOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddySuggestionOption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddySuggestionOption&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.slotHint, _this.slotHint) || other.slotHint == _this.slotHint)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddySuggestionOption;
  return Object.hash(runtimeType,_this.label,_this.slotHint,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as BuddySuggestionOption;
  return 'BuddySuggestionOption(label: ${_this.label}, slotHint: ${_this.slotHint}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $BuddySuggestionOptionCopyWith<$Res>  {
  factory $BuddySuggestionOptionCopyWith(BuddySuggestionOption value, $Res Function(BuddySuggestionOption) _then) = _$BuddySuggestionOptionCopyWithImpl;
@useResult
$Res call({
 String label, String? slotHint, List<BuddyFoodItem> items
});




}
/// @nodoc
class _$BuddySuggestionOptionCopyWithImpl<$Res>
    implements $BuddySuggestionOptionCopyWith<$Res> {
  _$BuddySuggestionOptionCopyWithImpl(this._self, this._then);

  final BuddySuggestionOption _self;
  final $Res Function(BuddySuggestionOption) _then;

/// Create a copy of BuddySuggestionOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? slotHint = freezed,Object? items = null,}) {
  return _then(BuddySuggestionOption(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<BuddyFoodItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddySuggestionOption].
extension BuddySuggestionOptionPatterns on BuddySuggestionOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddySuggestionOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddySuggestionOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddySuggestionOption value)  $default,){
final _that = this;
switch (_that) {
case _BuddySuggestionOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddySuggestionOption value)?  $default,){
final _that = this;
switch (_that) {
case _BuddySuggestionOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String? slotHint,  List<BuddyFoodItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddySuggestionOption() when $default != null:
return $default(_that.label,_that.slotHint,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String? slotHint,  List<BuddyFoodItem> items)  $default,) {final _that = this;
switch (_that) {
case _BuddySuggestionOption():
return $default(_that.label,_that.slotHint,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String? slotHint,  List<BuddyFoodItem> items)?  $default,) {final _that = this;
switch (_that) {
case _BuddySuggestionOption() when $default != null:
return $default(_that.label,_that.slotHint,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddySuggestionOption implements BuddySuggestionOption {
  const _BuddySuggestionOption({required this.label, required this.slotHint, required  List<BuddyFoodItem> items}): _items = items;
  factory _BuddySuggestionOption.fromJson(Map<String, dynamic> json) => _$BuddySuggestionOptionFromJson(json);

@override final  String label;
@override final  String? slotHint;
 final  List<BuddyFoodItem> _items;
@override List<BuddyFoodItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of BuddySuggestionOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddySuggestionOptionCopyWith<_BuddySuggestionOption> get copyWith => __$BuddySuggestionOptionCopyWithImpl<_BuddySuggestionOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddySuggestionOptionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddySuggestionOption&&(identical(other.label, label) || other.label == label)&&(identical(other.slotHint, slotHint) || other.slotHint == slotHint)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,label,slotHint,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'BuddySuggestionOption(label: $label, slotHint: $slotHint, items: $items)';
}


}

/// @nodoc
abstract mixin class _$BuddySuggestionOptionCopyWith<$Res> implements $BuddySuggestionOptionCopyWith<$Res> {
  factory _$BuddySuggestionOptionCopyWith(_BuddySuggestionOption value, $Res Function(_BuddySuggestionOption) _then) = __$BuddySuggestionOptionCopyWithImpl;
@override @useResult
$Res call({
 String label, String? slotHint, List<BuddyFoodItem> items
});




}
/// @nodoc
class __$BuddySuggestionOptionCopyWithImpl<$Res>
    implements _$BuddySuggestionOptionCopyWith<$Res> {
  __$BuddySuggestionOptionCopyWithImpl(this._self, this._then);

  final _BuddySuggestionOption _self;
  final $Res Function(_BuddySuggestionOption) _then;

/// Create a copy of BuddySuggestionOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? slotHint = freezed,Object? items = null,}) {
  return _then(_BuddySuggestionOption(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BuddyFoodItem>,
  ));
}


}

// dart format on
