// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_food_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyFoodItem {

 String get mention; BuddyCandidate? get match; List<BuddyCandidate> get alternatives; BuddyAmount get amount; BuddyShare? get share; List<BuddyDimension> get dimensions; BuddyEstimate? get estimate;
/// Create a copy of BuddyFoodItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyFoodItemCopyWith<BuddyFoodItem> get copyWith => _$BuddyFoodItemCopyWithImpl<BuddyFoodItem>(this as BuddyFoodItem, _$identity);

  /// Serializes this BuddyFoodItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyFoodItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyFoodItem&&(identical(other.mention, _this.mention) || other.mention == _this.mention)&&(identical(other.match, _this.match) || other.match == _this.match)&&const DeepCollectionEquality().equals(other.alternatives, _this.alternatives)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.share, _this.share) || other.share == _this.share)&&const DeepCollectionEquality().equals(other.dimensions, _this.dimensions)&&(identical(other.estimate, _this.estimate) || other.estimate == _this.estimate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyFoodItem;
  return Object.hash(runtimeType,_this.mention,_this.match,const DeepCollectionEquality().hash(_this.alternatives),_this.amount,_this.share,const DeepCollectionEquality().hash(_this.dimensions),_this.estimate);
}

@override
String toString() {
  final _this = this as BuddyFoodItem;
  return 'BuddyFoodItem(mention: ${_this.mention}, match: ${_this.match}, alternatives: ${_this.alternatives}, amount: ${_this.amount}, share: ${_this.share}, dimensions: ${_this.dimensions}, estimate: ${_this.estimate})';
}


}

/// @nodoc
abstract mixin class $BuddyFoodItemCopyWith<$Res>  {
  factory $BuddyFoodItemCopyWith(BuddyFoodItem value, $Res Function(BuddyFoodItem) _then) = _$BuddyFoodItemCopyWithImpl;
@useResult
$Res call({
 String mention, BuddyCandidate? match, List<BuddyCandidate> alternatives, BuddyAmount amount, BuddyShare? share, List<BuddyDimension> dimensions, BuddyEstimate? estimate
});


$BuddyCandidateCopyWith<$Res>? get match;$BuddyAmountCopyWith<$Res> get amount;$BuddyShareCopyWith<$Res>? get share;$BuddyEstimateCopyWith<$Res>? get estimate;

}
/// @nodoc
class _$BuddyFoodItemCopyWithImpl<$Res>
    implements $BuddyFoodItemCopyWith<$Res> {
  _$BuddyFoodItemCopyWithImpl(this._self, this._then);

  final BuddyFoodItem _self;
  final $Res Function(BuddyFoodItem) _then;

/// Create a copy of BuddyFoodItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mention = null,Object? match = freezed,Object? alternatives = null,Object? amount = null,Object? share = freezed,Object? dimensions = null,Object? estimate = freezed,}) {
  return _then(BuddyFoodItem(
mention: null == mention ? _self.mention : mention // ignore: cast_nullable_to_non_nullable
as String,match: freezed == match ? _self.match : match // ignore: cast_nullable_to_non_nullable
as BuddyCandidate?,alternatives: null == alternatives ? _self.alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<BuddyCandidate>,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BuddyAmount,share: freezed == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as BuddyShare?,dimensions: null == dimensions ? _self.dimensions : dimensions // ignore: cast_nullable_to_non_nullable
as List<BuddyDimension>,estimate: freezed == estimate ? _self.estimate : estimate // ignore: cast_nullable_to_non_nullable
as BuddyEstimate?,
  ));
}
/// Create a copy of BuddyFoodItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyCandidateCopyWith<$Res>? get match {
    if (_self.match == null) {
    return null;
  }

  return $BuddyCandidateCopyWith<$Res>(_self.match!, (value) {
    return _then(_self.copyWith(match: value));
  });
}/// Create a copy of BuddyFoodItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyAmountCopyWith<$Res> get amount {
  
  return $BuddyAmountCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}/// Create a copy of BuddyFoodItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyShareCopyWith<$Res>? get share {
    if (_self.share == null) {
    return null;
  }

  return $BuddyShareCopyWith<$Res>(_self.share!, (value) {
    return _then(_self.copyWith(share: value));
  });
}/// Create a copy of BuddyFoodItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyEstimateCopyWith<$Res>? get estimate {
    if (_self.estimate == null) {
    return null;
  }

  return $BuddyEstimateCopyWith<$Res>(_self.estimate!, (value) {
    return _then(_self.copyWith(estimate: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyFoodItem].
extension BuddyFoodItemPatterns on BuddyFoodItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyFoodItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyFoodItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyFoodItem value)  $default,){
final _that = this;
switch (_that) {
case _BuddyFoodItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyFoodItem value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyFoodItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mention,  BuddyCandidate? match,  List<BuddyCandidate> alternatives,  BuddyAmount amount,  BuddyShare? share,  List<BuddyDimension> dimensions,  BuddyEstimate? estimate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyFoodItem() when $default != null:
return $default(_that.mention,_that.match,_that.alternatives,_that.amount,_that.share,_that.dimensions,_that.estimate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mention,  BuddyCandidate? match,  List<BuddyCandidate> alternatives,  BuddyAmount amount,  BuddyShare? share,  List<BuddyDimension> dimensions,  BuddyEstimate? estimate)  $default,) {final _that = this;
switch (_that) {
case _BuddyFoodItem():
return $default(_that.mention,_that.match,_that.alternatives,_that.amount,_that.share,_that.dimensions,_that.estimate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mention,  BuddyCandidate? match,  List<BuddyCandidate> alternatives,  BuddyAmount amount,  BuddyShare? share,  List<BuddyDimension> dimensions,  BuddyEstimate? estimate)?  $default,) {final _that = this;
switch (_that) {
case _BuddyFoodItem() when $default != null:
return $default(_that.mention,_that.match,_that.alternatives,_that.amount,_that.share,_that.dimensions,_that.estimate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyFoodItem implements BuddyFoodItem {
  const _BuddyFoodItem({required this.mention, required this.match, required  List<BuddyCandidate> alternatives, required this.amount, required this.share, required  List<BuddyDimension> dimensions, required this.estimate}): _alternatives = alternatives,_dimensions = dimensions;
  factory _BuddyFoodItem.fromJson(Map<String, dynamic> json) => _$BuddyFoodItemFromJson(json);

@override final  String mention;
@override final  BuddyCandidate? match;
 final  List<BuddyCandidate> _alternatives;
@override List<BuddyCandidate> get alternatives {
  if (_alternatives is EqualUnmodifiableListView) return _alternatives;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alternatives);
}

@override final  BuddyAmount amount;
@override final  BuddyShare? share;
 final  List<BuddyDimension> _dimensions;
@override List<BuddyDimension> get dimensions {
  if (_dimensions is EqualUnmodifiableListView) return _dimensions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dimensions);
}

@override final  BuddyEstimate? estimate;

/// Create a copy of BuddyFoodItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyFoodItemCopyWith<_BuddyFoodItem> get copyWith => __$BuddyFoodItemCopyWithImpl<_BuddyFoodItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyFoodItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyFoodItem&&(identical(other.mention, mention) || other.mention == mention)&&(identical(other.match, match) || other.match == match)&&const DeepCollectionEquality().equals(other.alternatives, _alternatives)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.share, share) || other.share == share)&&const DeepCollectionEquality().equals(other.dimensions, _dimensions)&&(identical(other.estimate, estimate) || other.estimate == estimate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,mention,match,const DeepCollectionEquality().hash(_alternatives),amount,share,const DeepCollectionEquality().hash(_dimensions),estimate);
}

@override
String toString() {
    return 'BuddyFoodItem(mention: $mention, match: $match, alternatives: $alternatives, amount: $amount, share: $share, dimensions: $dimensions, estimate: $estimate)';
}


}

/// @nodoc
abstract mixin class _$BuddyFoodItemCopyWith<$Res> implements $BuddyFoodItemCopyWith<$Res> {
  factory _$BuddyFoodItemCopyWith(_BuddyFoodItem value, $Res Function(_BuddyFoodItem) _then) = __$BuddyFoodItemCopyWithImpl;
@override @useResult
$Res call({
 String mention, BuddyCandidate? match, List<BuddyCandidate> alternatives, BuddyAmount amount, BuddyShare? share, List<BuddyDimension> dimensions, BuddyEstimate? estimate
});


@override $BuddyCandidateCopyWith<$Res>? get match;@override $BuddyAmountCopyWith<$Res> get amount;@override $BuddyShareCopyWith<$Res>? get share;@override $BuddyEstimateCopyWith<$Res>? get estimate;

}
/// @nodoc
class __$BuddyFoodItemCopyWithImpl<$Res>
    implements _$BuddyFoodItemCopyWith<$Res> {
  __$BuddyFoodItemCopyWithImpl(this._self, this._then);

  final _BuddyFoodItem _self;
  final $Res Function(_BuddyFoodItem) _then;

/// Create a copy of BuddyFoodItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mention = null,Object? match = freezed,Object? alternatives = null,Object? amount = null,Object? share = freezed,Object? dimensions = null,Object? estimate = freezed,}) {
  return _then(_BuddyFoodItem(
mention: null == mention ? _self.mention : mention // ignore: cast_nullable_to_non_nullable
as String,match: freezed == match ? _self.match : match // ignore: cast_nullable_to_non_nullable
as BuddyCandidate?,alternatives: null == alternatives ? _self._alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<BuddyCandidate>,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BuddyAmount,share: freezed == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as BuddyShare?,dimensions: null == dimensions ? _self._dimensions : dimensions // ignore: cast_nullable_to_non_nullable
as List<BuddyDimension>,estimate: freezed == estimate ? _self.estimate : estimate // ignore: cast_nullable_to_non_nullable
as BuddyEstimate?,
  ));
}

/// Create a copy of BuddyFoodItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyCandidateCopyWith<$Res>? get match {
    if (_self.match == null) {
    return null;
  }

  return $BuddyCandidateCopyWith<$Res>(_self.match!, (value) {
    return _then(_self.copyWith(match: value));
  });
}/// Create a copy of BuddyFoodItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyAmountCopyWith<$Res> get amount {
  
  return $BuddyAmountCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}/// Create a copy of BuddyFoodItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyShareCopyWith<$Res>? get share {
    if (_self.share == null) {
    return null;
  }

  return $BuddyShareCopyWith<$Res>(_self.share!, (value) {
    return _then(_self.copyWith(share: value));
  });
}/// Create a copy of BuddyFoodItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyEstimateCopyWith<$Res>? get estimate {
    if (_self.estimate == null) {
    return null;
  }

  return $BuddyEstimateCopyWith<$Res>(_self.estimate!, (value) {
    return _then(_self.copyWith(estimate: value));
  });
}
}

// dart format on
