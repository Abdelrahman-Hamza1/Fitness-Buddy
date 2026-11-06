// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_turn_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyTurnProfile {

/// Up to 30 memory items (more via readMemory).
 List<BuddyMemory> get memory;/// Confirmed defaults and learned habits (weighing state, cooking fat, variants, portions), the same ones the ProposalEngine uses.
 List<BuddyHabitDefault> get defaults; bool get halal; BuddyUnits get units; BuddyRamadan get ramadan;
/// Create a copy of BuddyTurnProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnProfileCopyWith<BuddyTurnProfile> get copyWith => _$BuddyTurnProfileCopyWithImpl<BuddyTurnProfile>(this as BuddyTurnProfile, _$identity);

  /// Serializes this BuddyTurnProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyTurnProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnProfile&&const DeepCollectionEquality().equals(other.memory, _this.memory)&&const DeepCollectionEquality().equals(other.defaults, _this.defaults)&&(identical(other.halal, _this.halal) || other.halal == _this.halal)&&(identical(other.units, _this.units) || other.units == _this.units)&&(identical(other.ramadan, _this.ramadan) || other.ramadan == _this.ramadan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyTurnProfile;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.memory),const DeepCollectionEquality().hash(_this.defaults),_this.halal,_this.units,_this.ramadan);
}

@override
String toString() {
  final _this = this as BuddyTurnProfile;
  return 'BuddyTurnProfile(memory: ${_this.memory}, defaults: ${_this.defaults}, halal: ${_this.halal}, units: ${_this.units}, ramadan: ${_this.ramadan})';
}


}

/// @nodoc
abstract mixin class $BuddyTurnProfileCopyWith<$Res>  {
  factory $BuddyTurnProfileCopyWith(BuddyTurnProfile value, $Res Function(BuddyTurnProfile) _then) = _$BuddyTurnProfileCopyWithImpl;
@useResult
$Res call({
 List<BuddyMemory> memory, List<BuddyHabitDefault> defaults, bool halal, BuddyUnits units, BuddyRamadan ramadan
});


$BuddyUnitsCopyWith<$Res> get units;$BuddyRamadanCopyWith<$Res> get ramadan;

}
/// @nodoc
class _$BuddyTurnProfileCopyWithImpl<$Res>
    implements $BuddyTurnProfileCopyWith<$Res> {
  _$BuddyTurnProfileCopyWithImpl(this._self, this._then);

  final BuddyTurnProfile _self;
  final $Res Function(BuddyTurnProfile) _then;

/// Create a copy of BuddyTurnProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memory = null,Object? defaults = null,Object? halal = null,Object? units = null,Object? ramadan = null,}) {
  return _then(BuddyTurnProfile(
memory: null == memory ? _self.memory : memory // ignore: cast_nullable_to_non_nullable
as List<BuddyMemory>,defaults: null == defaults ? _self.defaults : defaults // ignore: cast_nullable_to_non_nullable
as List<BuddyHabitDefault>,halal: null == halal ? _self.halal : halal // ignore: cast_nullable_to_non_nullable
as bool,units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as BuddyUnits,ramadan: null == ramadan ? _self.ramadan : ramadan // ignore: cast_nullable_to_non_nullable
as BuddyRamadan,
  ));
}
/// Create a copy of BuddyTurnProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyUnitsCopyWith<$Res> get units {
  
  return $BuddyUnitsCopyWith<$Res>(_self.units, (value) {
    return _then(_self.copyWith(units: value));
  });
}/// Create a copy of BuddyTurnProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyRamadanCopyWith<$Res> get ramadan {
  
  return $BuddyRamadanCopyWith<$Res>(_self.ramadan, (value) {
    return _then(_self.copyWith(ramadan: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyTurnProfile].
extension BuddyTurnProfilePatterns on BuddyTurnProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyTurnProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyTurnProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyTurnProfile value)  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyTurnProfile value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BuddyMemory> memory,  List<BuddyHabitDefault> defaults,  bool halal,  BuddyUnits units,  BuddyRamadan ramadan)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyTurnProfile() when $default != null:
return $default(_that.memory,_that.defaults,_that.halal,_that.units,_that.ramadan);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BuddyMemory> memory,  List<BuddyHabitDefault> defaults,  bool halal,  BuddyUnits units,  BuddyRamadan ramadan)  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnProfile():
return $default(_that.memory,_that.defaults,_that.halal,_that.units,_that.ramadan);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BuddyMemory> memory,  List<BuddyHabitDefault> defaults,  bool halal,  BuddyUnits units,  BuddyRamadan ramadan)?  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnProfile() when $default != null:
return $default(_that.memory,_that.defaults,_that.halal,_that.units,_that.ramadan);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyTurnProfile implements BuddyTurnProfile {
  const _BuddyTurnProfile({required  List<BuddyMemory> memory, required  List<BuddyHabitDefault> defaults, required this.halal, required this.units, required this.ramadan}): _memory = memory,_defaults = defaults;
  factory _BuddyTurnProfile.fromJson(Map<String, dynamic> json) => _$BuddyTurnProfileFromJson(json);

/// Up to 30 memory items (more via readMemory).
 final  List<BuddyMemory> _memory;
/// Up to 30 memory items (more via readMemory).
@override List<BuddyMemory> get memory {
  if (_memory is EqualUnmodifiableListView) return _memory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memory);
}

/// Confirmed defaults and learned habits (weighing state, cooking fat, variants, portions), the same ones the ProposalEngine uses.
 final  List<BuddyHabitDefault> _defaults;
/// Confirmed defaults and learned habits (weighing state, cooking fat, variants, portions), the same ones the ProposalEngine uses.
@override List<BuddyHabitDefault> get defaults {
  if (_defaults is EqualUnmodifiableListView) return _defaults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_defaults);
}

@override final  bool halal;
@override final  BuddyUnits units;
@override final  BuddyRamadan ramadan;

/// Create a copy of BuddyTurnProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyTurnProfileCopyWith<_BuddyTurnProfile> get copyWith => __$BuddyTurnProfileCopyWithImpl<_BuddyTurnProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyTurnProfile&&const DeepCollectionEquality().equals(other.memory, _memory)&&const DeepCollectionEquality().equals(other.defaults, _defaults)&&(identical(other.halal, halal) || other.halal == halal)&&(identical(other.units, units) || other.units == units)&&(identical(other.ramadan, ramadan) || other.ramadan == ramadan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_memory),const DeepCollectionEquality().hash(_defaults),halal,units,ramadan);
}

@override
String toString() {
    return 'BuddyTurnProfile(memory: $memory, defaults: $defaults, halal: $halal, units: $units, ramadan: $ramadan)';
}


}

/// @nodoc
abstract mixin class _$BuddyTurnProfileCopyWith<$Res> implements $BuddyTurnProfileCopyWith<$Res> {
  factory _$BuddyTurnProfileCopyWith(_BuddyTurnProfile value, $Res Function(_BuddyTurnProfile) _then) = __$BuddyTurnProfileCopyWithImpl;
@override @useResult
$Res call({
 List<BuddyMemory> memory, List<BuddyHabitDefault> defaults, bool halal, BuddyUnits units, BuddyRamadan ramadan
});


@override $BuddyUnitsCopyWith<$Res> get units;@override $BuddyRamadanCopyWith<$Res> get ramadan;

}
/// @nodoc
class __$BuddyTurnProfileCopyWithImpl<$Res>
    implements _$BuddyTurnProfileCopyWith<$Res> {
  __$BuddyTurnProfileCopyWithImpl(this._self, this._then);

  final _BuddyTurnProfile _self;
  final $Res Function(_BuddyTurnProfile) _then;

/// Create a copy of BuddyTurnProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? memory = null,Object? defaults = null,Object? halal = null,Object? units = null,Object? ramadan = null,}) {
  return _then(_BuddyTurnProfile(
memory: null == memory ? _self._memory : memory // ignore: cast_nullable_to_non_nullable
as List<BuddyMemory>,defaults: null == defaults ? _self._defaults : defaults // ignore: cast_nullable_to_non_nullable
as List<BuddyHabitDefault>,halal: null == halal ? _self.halal : halal // ignore: cast_nullable_to_non_nullable
as bool,units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as BuddyUnits,ramadan: null == ramadan ? _self.ramadan : ramadan // ignore: cast_nullable_to_non_nullable
as BuddyRamadan,
  ));
}

/// Create a copy of BuddyTurnProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyUnitsCopyWith<$Res> get units {
  
  return $BuddyUnitsCopyWith<$Res>(_self.units, (value) {
    return _then(_self.copyWith(units: value));
  });
}/// Create a copy of BuddyTurnProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyRamadanCopyWith<$Res> get ramadan {
  
  return $BuddyRamadanCopyWith<$Res>(_self.ramadan, (value) {
    return _then(_self.copyWith(ramadan: value));
  });
}
}

// dart format on
