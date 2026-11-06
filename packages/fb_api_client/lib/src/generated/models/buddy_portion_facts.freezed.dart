// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_portion_facts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyPortionFacts {

 String get label; double? get g; BuddyNutrientsRequest get nutrients;
/// Create a copy of BuddyPortionFacts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPortionFactsCopyWith<BuddyPortionFacts> get copyWith => _$BuddyPortionFactsCopyWithImpl<BuddyPortionFacts>(this as BuddyPortionFacts, _$identity);

  /// Serializes this BuddyPortionFacts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyPortionFacts;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPortionFacts&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.g, _this.g) || other.g == _this.g)&&(identical(other.nutrients, _this.nutrients) || other.nutrients == _this.nutrients));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyPortionFacts;
  return Object.hash(runtimeType,_this.label,_this.g,_this.nutrients);
}

@override
String toString() {
  final _this = this as BuddyPortionFacts;
  return 'BuddyPortionFacts(label: ${_this.label}, g: ${_this.g}, nutrients: ${_this.nutrients})';
}


}

/// @nodoc
abstract mixin class $BuddyPortionFactsCopyWith<$Res>  {
  factory $BuddyPortionFactsCopyWith(BuddyPortionFacts value, $Res Function(BuddyPortionFacts) _then) = _$BuddyPortionFactsCopyWithImpl;
@useResult
$Res call({
 String label, double? g, BuddyNutrientsRequest nutrients
});


$BuddyNutrientsRequestCopyWith<$Res> get nutrients;

}
/// @nodoc
class _$BuddyPortionFactsCopyWithImpl<$Res>
    implements $BuddyPortionFactsCopyWith<$Res> {
  _$BuddyPortionFactsCopyWithImpl(this._self, this._then);

  final BuddyPortionFacts _self;
  final $Res Function(BuddyPortionFacts) _then;

/// Create a copy of BuddyPortionFacts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? g = freezed,Object? nutrients = null,}) {
  return _then(BuddyPortionFacts(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,g: freezed == g ? _self.g : g // ignore: cast_nullable_to_non_nullable
as double?,nutrients: null == nutrients ? _self.nutrients : nutrients // ignore: cast_nullable_to_non_nullable
as BuddyNutrientsRequest,
  ));
}
/// Create a copy of BuddyPortionFacts
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyNutrientsRequestCopyWith<$Res> get nutrients {
  
  return $BuddyNutrientsRequestCopyWith<$Res>(_self.nutrients, (value) {
    return _then(_self.copyWith(nutrients: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyPortionFacts].
extension BuddyPortionFactsPatterns on BuddyPortionFacts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyPortionFacts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyPortionFacts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyPortionFacts value)  $default,){
final _that = this;
switch (_that) {
case _BuddyPortionFacts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyPortionFacts value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyPortionFacts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  double? g,  BuddyNutrientsRequest nutrients)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyPortionFacts() when $default != null:
return $default(_that.label,_that.g,_that.nutrients);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  double? g,  BuddyNutrientsRequest nutrients)  $default,) {final _that = this;
switch (_that) {
case _BuddyPortionFacts():
return $default(_that.label,_that.g,_that.nutrients);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  double? g,  BuddyNutrientsRequest nutrients)?  $default,) {final _that = this;
switch (_that) {
case _BuddyPortionFacts() when $default != null:
return $default(_that.label,_that.g,_that.nutrients);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyPortionFacts implements BuddyPortionFacts {
  const _BuddyPortionFacts({required this.label, required this.g, required this.nutrients});
  factory _BuddyPortionFacts.fromJson(Map<String, dynamic> json) => _$BuddyPortionFactsFromJson(json);

@override final  String label;
@override final  double? g;
@override final  BuddyNutrientsRequest nutrients;

/// Create a copy of BuddyPortionFacts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyPortionFactsCopyWith<_BuddyPortionFacts> get copyWith => __$BuddyPortionFactsCopyWithImpl<_BuddyPortionFacts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPortionFactsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyPortionFacts&&(identical(other.label, label) || other.label == label)&&(identical(other.g, g) || other.g == g)&&(identical(other.nutrients, nutrients) || other.nutrients == nutrients));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,label,g,nutrients);
}

@override
String toString() {
    return 'BuddyPortionFacts(label: $label, g: $g, nutrients: $nutrients)';
}


}

/// @nodoc
abstract mixin class _$BuddyPortionFactsCopyWith<$Res> implements $BuddyPortionFactsCopyWith<$Res> {
  factory _$BuddyPortionFactsCopyWith(_BuddyPortionFacts value, $Res Function(_BuddyPortionFacts) _then) = __$BuddyPortionFactsCopyWithImpl;
@override @useResult
$Res call({
 String label, double? g, BuddyNutrientsRequest nutrients
});


@override $BuddyNutrientsRequestCopyWith<$Res> get nutrients;

}
/// @nodoc
class __$BuddyPortionFactsCopyWithImpl<$Res>
    implements _$BuddyPortionFactsCopyWith<$Res> {
  __$BuddyPortionFactsCopyWithImpl(this._self, this._then);

  final _BuddyPortionFacts _self;
  final $Res Function(_BuddyPortionFacts) _then;

/// Create a copy of BuddyPortionFacts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? g = freezed,Object? nutrients = null,}) {
  return _then(_BuddyPortionFacts(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,g: freezed == g ? _self.g : g // ignore: cast_nullable_to_non_nullable
as double?,nutrients: null == nutrients ? _self.nutrients : nutrients // ignore: cast_nullable_to_non_nullable
as BuddyNutrientsRequest,
  ));
}

/// Create a copy of BuddyPortionFacts
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyNutrientsRequestCopyWith<$Res> get nutrients {
  
  return $BuddyNutrientsRequestCopyWith<$Res>(_self.nutrients, (value) {
    return _then(_self.copyWith(nutrients: value));
  });
}
}

// dart format on
