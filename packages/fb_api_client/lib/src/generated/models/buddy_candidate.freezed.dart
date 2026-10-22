// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_candidate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyCandidate {

 String get key; String get nameEn; String? get nameAr; String get state; String get source; BuddyNutrients get nutrients; BuddyRange? get ranges; List<BuddyServing> get servings; double? get densityGPerMl; String? get yieldGroup;
/// Create a copy of BuddyCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyCandidateCopyWith<BuddyCandidate> get copyWith => _$BuddyCandidateCopyWithImpl<BuddyCandidate>(this as BuddyCandidate, _$identity);

  /// Serializes this BuddyCandidate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyCandidate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyCandidate&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.nameEn, _this.nameEn) || other.nameEn == _this.nameEn)&&(identical(other.nameAr, _this.nameAr) || other.nameAr == _this.nameAr)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.nutrients, _this.nutrients) || other.nutrients == _this.nutrients)&&(identical(other.ranges, _this.ranges) || other.ranges == _this.ranges)&&const DeepCollectionEquality().equals(other.servings, _this.servings)&&(identical(other.densityGPerMl, _this.densityGPerMl) || other.densityGPerMl == _this.densityGPerMl)&&(identical(other.yieldGroup, _this.yieldGroup) || other.yieldGroup == _this.yieldGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyCandidate;
  return Object.hash(runtimeType,_this.key,_this.nameEn,_this.nameAr,_this.state,_this.source,_this.nutrients,_this.ranges,const DeepCollectionEquality().hash(_this.servings),_this.densityGPerMl,_this.yieldGroup);
}

@override
String toString() {
  final _this = this as BuddyCandidate;
  return 'BuddyCandidate(key: ${_this.key}, nameEn: ${_this.nameEn}, nameAr: ${_this.nameAr}, state: ${_this.state}, source: ${_this.source}, nutrients: ${_this.nutrients}, ranges: ${_this.ranges}, servings: ${_this.servings}, densityGPerMl: ${_this.densityGPerMl}, yieldGroup: ${_this.yieldGroup})';
}


}

/// @nodoc
abstract mixin class $BuddyCandidateCopyWith<$Res>  {
  factory $BuddyCandidateCopyWith(BuddyCandidate value, $Res Function(BuddyCandidate) _then) = _$BuddyCandidateCopyWithImpl;
@useResult
$Res call({
 String key, String nameEn, String? nameAr, String state, String source, BuddyNutrients nutrients, BuddyRange? ranges, List<BuddyServing> servings, double? densityGPerMl, String? yieldGroup
});


$BuddyNutrientsCopyWith<$Res> get nutrients;$BuddyRangeCopyWith<$Res>? get ranges;

}
/// @nodoc
class _$BuddyCandidateCopyWithImpl<$Res>
    implements $BuddyCandidateCopyWith<$Res> {
  _$BuddyCandidateCopyWithImpl(this._self, this._then);

  final BuddyCandidate _self;
  final $Res Function(BuddyCandidate) _then;

/// Create a copy of BuddyCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? nameEn = null,Object? nameAr = freezed,Object? state = null,Object? source = null,Object? nutrients = null,Object? ranges = freezed,Object? servings = null,Object? densityGPerMl = freezed,Object? yieldGroup = freezed,}) {
  return _then(BuddyCandidate(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,nameAr: freezed == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,nutrients: null == nutrients ? _self.nutrients : nutrients // ignore: cast_nullable_to_non_nullable
as BuddyNutrients,ranges: freezed == ranges ? _self.ranges : ranges // ignore: cast_nullable_to_non_nullable
as BuddyRange?,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as List<BuddyServing>,densityGPerMl: freezed == densityGPerMl ? _self.densityGPerMl : densityGPerMl // ignore: cast_nullable_to_non_nullable
as double?,yieldGroup: freezed == yieldGroup ? _self.yieldGroup : yieldGroup // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BuddyCandidate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyNutrientsCopyWith<$Res> get nutrients {
  
  return $BuddyNutrientsCopyWith<$Res>(_self.nutrients, (value) {
    return _then(_self.copyWith(nutrients: value));
  });
}/// Create a copy of BuddyCandidate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyRangeCopyWith<$Res>? get ranges {
    if (_self.ranges == null) {
    return null;
  }

  return $BuddyRangeCopyWith<$Res>(_self.ranges!, (value) {
    return _then(_self.copyWith(ranges: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyCandidate].
extension BuddyCandidatePatterns on BuddyCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyCandidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyCandidate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyCandidate value)  $default,){
final _that = this;
switch (_that) {
case _BuddyCandidate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyCandidate value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyCandidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String nameEn,  String? nameAr,  String state,  String source,  BuddyNutrients nutrients,  BuddyRange? ranges,  List<BuddyServing> servings,  double? densityGPerMl,  String? yieldGroup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyCandidate() when $default != null:
return $default(_that.key,_that.nameEn,_that.nameAr,_that.state,_that.source,_that.nutrients,_that.ranges,_that.servings,_that.densityGPerMl,_that.yieldGroup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String nameEn,  String? nameAr,  String state,  String source,  BuddyNutrients nutrients,  BuddyRange? ranges,  List<BuddyServing> servings,  double? densityGPerMl,  String? yieldGroup)  $default,) {final _that = this;
switch (_that) {
case _BuddyCandidate():
return $default(_that.key,_that.nameEn,_that.nameAr,_that.state,_that.source,_that.nutrients,_that.ranges,_that.servings,_that.densityGPerMl,_that.yieldGroup);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String nameEn,  String? nameAr,  String state,  String source,  BuddyNutrients nutrients,  BuddyRange? ranges,  List<BuddyServing> servings,  double? densityGPerMl,  String? yieldGroup)?  $default,) {final _that = this;
switch (_that) {
case _BuddyCandidate() when $default != null:
return $default(_that.key,_that.nameEn,_that.nameAr,_that.state,_that.source,_that.nutrients,_that.ranges,_that.servings,_that.densityGPerMl,_that.yieldGroup);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyCandidate implements BuddyCandidate {
  const _BuddyCandidate({required this.key, required this.nameEn, required this.nameAr, required this.state, required this.source, required this.nutrients, required this.ranges, required  List<BuddyServing> servings, required this.densityGPerMl, required this.yieldGroup}): _servings = servings;
  factory _BuddyCandidate.fromJson(Map<String, dynamic> json) => _$BuddyCandidateFromJson(json);

@override final  String key;
@override final  String nameEn;
@override final  String? nameAr;
@override final  String state;
@override final  String source;
@override final  BuddyNutrients nutrients;
@override final  BuddyRange? ranges;
 final  List<BuddyServing> _servings;
@override List<BuddyServing> get servings {
  if (_servings is EqualUnmodifiableListView) return _servings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_servings);
}

@override final  double? densityGPerMl;
@override final  String? yieldGroup;

/// Create a copy of BuddyCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyCandidateCopyWith<_BuddyCandidate> get copyWith => __$BuddyCandidateCopyWithImpl<_BuddyCandidate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyCandidateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyCandidate&&(identical(other.key, key) || other.key == key)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.state, state) || other.state == state)&&(identical(other.source, source) || other.source == source)&&(identical(other.nutrients, nutrients) || other.nutrients == nutrients)&&(identical(other.ranges, ranges) || other.ranges == ranges)&&const DeepCollectionEquality().equals(other.servings, _servings)&&(identical(other.densityGPerMl, densityGPerMl) || other.densityGPerMl == densityGPerMl)&&(identical(other.yieldGroup, yieldGroup) || other.yieldGroup == yieldGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,key,nameEn,nameAr,state,source,nutrients,ranges,const DeepCollectionEquality().hash(_servings),densityGPerMl,yieldGroup);
}

@override
String toString() {
    return 'BuddyCandidate(key: $key, nameEn: $nameEn, nameAr: $nameAr, state: $state, source: $source, nutrients: $nutrients, ranges: $ranges, servings: $servings, densityGPerMl: $densityGPerMl, yieldGroup: $yieldGroup)';
}


}

/// @nodoc
abstract mixin class _$BuddyCandidateCopyWith<$Res> implements $BuddyCandidateCopyWith<$Res> {
  factory _$BuddyCandidateCopyWith(_BuddyCandidate value, $Res Function(_BuddyCandidate) _then) = __$BuddyCandidateCopyWithImpl;
@override @useResult
$Res call({
 String key, String nameEn, String? nameAr, String state, String source, BuddyNutrients nutrients, BuddyRange? ranges, List<BuddyServing> servings, double? densityGPerMl, String? yieldGroup
});


@override $BuddyNutrientsCopyWith<$Res> get nutrients;@override $BuddyRangeCopyWith<$Res>? get ranges;

}
/// @nodoc
class __$BuddyCandidateCopyWithImpl<$Res>
    implements _$BuddyCandidateCopyWith<$Res> {
  __$BuddyCandidateCopyWithImpl(this._self, this._then);

  final _BuddyCandidate _self;
  final $Res Function(_BuddyCandidate) _then;

/// Create a copy of BuddyCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? nameEn = null,Object? nameAr = freezed,Object? state = null,Object? source = null,Object? nutrients = null,Object? ranges = freezed,Object? servings = null,Object? densityGPerMl = freezed,Object? yieldGroup = freezed,}) {
  return _then(_BuddyCandidate(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,nameAr: freezed == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,nutrients: null == nutrients ? _self.nutrients : nutrients // ignore: cast_nullable_to_non_nullable
as BuddyNutrients,ranges: freezed == ranges ? _self.ranges : ranges // ignore: cast_nullable_to_non_nullable
as BuddyRange?,servings: null == servings ? _self._servings : servings // ignore: cast_nullable_to_non_nullable
as List<BuddyServing>,densityGPerMl: freezed == densityGPerMl ? _self.densityGPerMl : densityGPerMl // ignore: cast_nullable_to_non_nullable
as double?,yieldGroup: freezed == yieldGroup ? _self.yieldGroup : yieldGroup // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BuddyCandidate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyNutrientsCopyWith<$Res> get nutrients {
  
  return $BuddyNutrientsCopyWith<$Res>(_self.nutrients, (value) {
    return _then(_self.copyWith(nutrients: value));
  });
}/// Create a copy of BuddyCandidate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyRangeCopyWith<$Res>? get ranges {
    if (_self.ranges == null) {
    return null;
  }

  return $BuddyRangeCopyWith<$Res>(_self.ranges!, (value) {
    return _then(_self.copyWith(ranges: value));
  });
}
}

// dart format on
