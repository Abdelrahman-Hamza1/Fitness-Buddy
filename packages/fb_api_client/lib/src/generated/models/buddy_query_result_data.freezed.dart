// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_query_result_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyQueryResultData {

 List<BuddyClaimValue> get claims; BuddyCoverage get coverage; BuddyQueryLink? get link;
/// Create a copy of BuddyQueryResultData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyQueryResultDataCopyWith<BuddyQueryResultData> get copyWith => _$BuddyQueryResultDataCopyWithImpl<BuddyQueryResultData>(this as BuddyQueryResultData, _$identity);

  /// Serializes this BuddyQueryResultData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyQueryResultData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyQueryResultData&&const DeepCollectionEquality().equals(other.claims, _this.claims)&&(identical(other.coverage, _this.coverage) || other.coverage == _this.coverage)&&(identical(other.link, _this.link) || other.link == _this.link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyQueryResultData;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.claims),_this.coverage,_this.link);
}

@override
String toString() {
  final _this = this as BuddyQueryResultData;
  return 'BuddyQueryResultData(claims: ${_this.claims}, coverage: ${_this.coverage}, link: ${_this.link})';
}


}

/// @nodoc
abstract mixin class $BuddyQueryResultDataCopyWith<$Res>  {
  factory $BuddyQueryResultDataCopyWith(BuddyQueryResultData value, $Res Function(BuddyQueryResultData) _then) = _$BuddyQueryResultDataCopyWithImpl;
@useResult
$Res call({
 List<BuddyClaimValue> claims, BuddyCoverage coverage, BuddyQueryLink? link
});


$BuddyCoverageCopyWith<$Res> get coverage;$BuddyQueryLinkCopyWith<$Res>? get link;

}
/// @nodoc
class _$BuddyQueryResultDataCopyWithImpl<$Res>
    implements $BuddyQueryResultDataCopyWith<$Res> {
  _$BuddyQueryResultDataCopyWithImpl(this._self, this._then);

  final BuddyQueryResultData _self;
  final $Res Function(BuddyQueryResultData) _then;

/// Create a copy of BuddyQueryResultData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? claims = null,Object? coverage = null,Object? link = freezed,}) {
  return _then(BuddyQueryResultData(
claims: null == claims ? _self.claims : claims // ignore: cast_nullable_to_non_nullable
as List<BuddyClaimValue>,coverage: null == coverage ? _self.coverage : coverage // ignore: cast_nullable_to_non_nullable
as BuddyCoverage,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as BuddyQueryLink?,
  ));
}
/// Create a copy of BuddyQueryResultData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyCoverageCopyWith<$Res> get coverage {
  
  return $BuddyCoverageCopyWith<$Res>(_self.coverage, (value) {
    return _then(_self.copyWith(coverage: value));
  });
}/// Create a copy of BuddyQueryResultData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyQueryLinkCopyWith<$Res>? get link {
    if (_self.link == null) {
    return null;
  }

  return $BuddyQueryLinkCopyWith<$Res>(_self.link!, (value) {
    return _then(_self.copyWith(link: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyQueryResultData].
extension BuddyQueryResultDataPatterns on BuddyQueryResultData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyQueryResultData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyQueryResultData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyQueryResultData value)  $default,){
final _that = this;
switch (_that) {
case _BuddyQueryResultData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyQueryResultData value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyQueryResultData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BuddyClaimValue> claims,  BuddyCoverage coverage,  BuddyQueryLink? link)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyQueryResultData() when $default != null:
return $default(_that.claims,_that.coverage,_that.link);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BuddyClaimValue> claims,  BuddyCoverage coverage,  BuddyQueryLink? link)  $default,) {final _that = this;
switch (_that) {
case _BuddyQueryResultData():
return $default(_that.claims,_that.coverage,_that.link);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BuddyClaimValue> claims,  BuddyCoverage coverage,  BuddyQueryLink? link)?  $default,) {final _that = this;
switch (_that) {
case _BuddyQueryResultData() when $default != null:
return $default(_that.claims,_that.coverage,_that.link);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyQueryResultData implements BuddyQueryResultData {
  const _BuddyQueryResultData({required  List<BuddyClaimValue> claims, required this.coverage, required this.link}): _claims = claims;
  factory _BuddyQueryResultData.fromJson(Map<String, dynamic> json) => _$BuddyQueryResultDataFromJson(json);

 final  List<BuddyClaimValue> _claims;
@override List<BuddyClaimValue> get claims {
  if (_claims is EqualUnmodifiableListView) return _claims;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_claims);
}

@override final  BuddyCoverage coverage;
@override final  BuddyQueryLink? link;

/// Create a copy of BuddyQueryResultData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyQueryResultDataCopyWith<_BuddyQueryResultData> get copyWith => __$BuddyQueryResultDataCopyWithImpl<_BuddyQueryResultData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyQueryResultDataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyQueryResultData&&const DeepCollectionEquality().equals(other.claims, _claims)&&(identical(other.coverage, coverage) || other.coverage == coverage)&&(identical(other.link, link) || other.link == link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_claims),coverage,link);
}

@override
String toString() {
    return 'BuddyQueryResultData(claims: $claims, coverage: $coverage, link: $link)';
}


}

/// @nodoc
abstract mixin class _$BuddyQueryResultDataCopyWith<$Res> implements $BuddyQueryResultDataCopyWith<$Res> {
  factory _$BuddyQueryResultDataCopyWith(_BuddyQueryResultData value, $Res Function(_BuddyQueryResultData) _then) = __$BuddyQueryResultDataCopyWithImpl;
@override @useResult
$Res call({
 List<BuddyClaimValue> claims, BuddyCoverage coverage, BuddyQueryLink? link
});


@override $BuddyCoverageCopyWith<$Res> get coverage;@override $BuddyQueryLinkCopyWith<$Res>? get link;

}
/// @nodoc
class __$BuddyQueryResultDataCopyWithImpl<$Res>
    implements _$BuddyQueryResultDataCopyWith<$Res> {
  __$BuddyQueryResultDataCopyWithImpl(this._self, this._then);

  final _BuddyQueryResultData _self;
  final $Res Function(_BuddyQueryResultData) _then;

/// Create a copy of BuddyQueryResultData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? claims = null,Object? coverage = null,Object? link = freezed,}) {
  return _then(_BuddyQueryResultData(
claims: null == claims ? _self._claims : claims // ignore: cast_nullable_to_non_nullable
as List<BuddyClaimValue>,coverage: null == coverage ? _self.coverage : coverage // ignore: cast_nullable_to_non_nullable
as BuddyCoverage,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as BuddyQueryLink?,
  ));
}

/// Create a copy of BuddyQueryResultData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyCoverageCopyWith<$Res> get coverage {
  
  return $BuddyCoverageCopyWith<$Res>(_self.coverage, (value) {
    return _then(_self.copyWith(coverage: value));
  });
}/// Create a copy of BuddyQueryResultData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyQueryLinkCopyWith<$Res>? get link {
    if (_self.link == null) {
    return null;
  }

  return $BuddyQueryLinkCopyWith<$Res>(_self.link!, (value) {
    return _then(_self.copyWith(link: value));
  });
}
}

// dart format on
