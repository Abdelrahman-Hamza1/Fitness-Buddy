// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyContext {

 List<BuddyPersonalFood> get personalFoods; List<BuddyNamedReference> get savedMeals; List<BuddyNamedReference> get openBatches; List<BuddyMemory> get memory;/// Ordered newest first; at most 30, about 3 days. Only date, slot and name are forwarded to the model.
 List<BuddyRecentEntry> get recentEntries; List<BuddyNamedReference> get customExercises;/// The open proposal card a follow-up refers to (AI-044). Requires activeProposal (else 400). Optional: older apps omit it; absent and null are the same. Its slot, time and line name/amount/unitCode/state are forwarded to the model.
 BuddyActiveCard? get activeCard;
/// Create a copy of BuddyContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyContextCopyWith<BuddyContext> get copyWith => _$BuddyContextCopyWithImpl<BuddyContext>(this as BuddyContext, _$identity);

  /// Serializes this BuddyContext to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyContext;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyContext&&const DeepCollectionEquality().equals(other.personalFoods, _this.personalFoods)&&const DeepCollectionEquality().equals(other.savedMeals, _this.savedMeals)&&const DeepCollectionEquality().equals(other.openBatches, _this.openBatches)&&const DeepCollectionEquality().equals(other.memory, _this.memory)&&const DeepCollectionEquality().equals(other.recentEntries, _this.recentEntries)&&const DeepCollectionEquality().equals(other.customExercises, _this.customExercises)&&(identical(other.activeCard, _this.activeCard) || other.activeCard == _this.activeCard));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyContext;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.personalFoods),const DeepCollectionEquality().hash(_this.savedMeals),const DeepCollectionEquality().hash(_this.openBatches),const DeepCollectionEquality().hash(_this.memory),const DeepCollectionEquality().hash(_this.recentEntries),const DeepCollectionEquality().hash(_this.customExercises),_this.activeCard);
}

@override
String toString() {
  final _this = this as BuddyContext;
  return 'BuddyContext(personalFoods: ${_this.personalFoods}, savedMeals: ${_this.savedMeals}, openBatches: ${_this.openBatches}, memory: ${_this.memory}, recentEntries: ${_this.recentEntries}, customExercises: ${_this.customExercises}, activeCard: ${_this.activeCard})';
}


}

/// @nodoc
abstract mixin class $BuddyContextCopyWith<$Res>  {
  factory $BuddyContextCopyWith(BuddyContext value, $Res Function(BuddyContext) _then) = _$BuddyContextCopyWithImpl;
@useResult
$Res call({
 List<BuddyPersonalFood> personalFoods, List<BuddyNamedReference> savedMeals, List<BuddyNamedReference> openBatches, List<BuddyMemory> memory, List<BuddyRecentEntry> recentEntries, List<BuddyNamedReference> customExercises, BuddyActiveCard? activeCard
});


$BuddyActiveCardCopyWith<$Res>? get activeCard;

}
/// @nodoc
class _$BuddyContextCopyWithImpl<$Res>
    implements $BuddyContextCopyWith<$Res> {
  _$BuddyContextCopyWithImpl(this._self, this._then);

  final BuddyContext _self;
  final $Res Function(BuddyContext) _then;

/// Create a copy of BuddyContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? personalFoods = null,Object? savedMeals = null,Object? openBatches = null,Object? memory = null,Object? recentEntries = null,Object? customExercises = null,Object? activeCard = freezed,}) {
  return _then(BuddyContext(
personalFoods: null == personalFoods ? _self.personalFoods : personalFoods // ignore: cast_nullable_to_non_nullable
as List<BuddyPersonalFood>,savedMeals: null == savedMeals ? _self.savedMeals : savedMeals // ignore: cast_nullable_to_non_nullable
as List<BuddyNamedReference>,openBatches: null == openBatches ? _self.openBatches : openBatches // ignore: cast_nullable_to_non_nullable
as List<BuddyNamedReference>,memory: null == memory ? _self.memory : memory // ignore: cast_nullable_to_non_nullable
as List<BuddyMemory>,recentEntries: null == recentEntries ? _self.recentEntries : recentEntries // ignore: cast_nullable_to_non_nullable
as List<BuddyRecentEntry>,customExercises: null == customExercises ? _self.customExercises : customExercises // ignore: cast_nullable_to_non_nullable
as List<BuddyNamedReference>,activeCard: freezed == activeCard ? _self.activeCard : activeCard // ignore: cast_nullable_to_non_nullable
as BuddyActiveCard?,
  ));
}
/// Create a copy of BuddyContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyActiveCardCopyWith<$Res>? get activeCard {
    if (_self.activeCard == null) {
    return null;
  }

  return $BuddyActiveCardCopyWith<$Res>(_self.activeCard!, (value) {
    return _then(_self.copyWith(activeCard: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyContext].
extension BuddyContextPatterns on BuddyContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyContext value)  $default,){
final _that = this;
switch (_that) {
case _BuddyContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyContext value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BuddyPersonalFood> personalFoods,  List<BuddyNamedReference> savedMeals,  List<BuddyNamedReference> openBatches,  List<BuddyMemory> memory,  List<BuddyRecentEntry> recentEntries,  List<BuddyNamedReference> customExercises,  BuddyActiveCard? activeCard)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyContext() when $default != null:
return $default(_that.personalFoods,_that.savedMeals,_that.openBatches,_that.memory,_that.recentEntries,_that.customExercises,_that.activeCard);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BuddyPersonalFood> personalFoods,  List<BuddyNamedReference> savedMeals,  List<BuddyNamedReference> openBatches,  List<BuddyMemory> memory,  List<BuddyRecentEntry> recentEntries,  List<BuddyNamedReference> customExercises,  BuddyActiveCard? activeCard)  $default,) {final _that = this;
switch (_that) {
case _BuddyContext():
return $default(_that.personalFoods,_that.savedMeals,_that.openBatches,_that.memory,_that.recentEntries,_that.customExercises,_that.activeCard);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BuddyPersonalFood> personalFoods,  List<BuddyNamedReference> savedMeals,  List<BuddyNamedReference> openBatches,  List<BuddyMemory> memory,  List<BuddyRecentEntry> recentEntries,  List<BuddyNamedReference> customExercises,  BuddyActiveCard? activeCard)?  $default,) {final _that = this;
switch (_that) {
case _BuddyContext() when $default != null:
return $default(_that.personalFoods,_that.savedMeals,_that.openBatches,_that.memory,_that.recentEntries,_that.customExercises,_that.activeCard);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyContext implements BuddyContext {
  const _BuddyContext({required  List<BuddyPersonalFood> personalFoods, required  List<BuddyNamedReference> savedMeals, required  List<BuddyNamedReference> openBatches, required  List<BuddyMemory> memory, required  List<BuddyRecentEntry> recentEntries, required  List<BuddyNamedReference> customExercises, this.activeCard}): _personalFoods = personalFoods,_savedMeals = savedMeals,_openBatches = openBatches,_memory = memory,_recentEntries = recentEntries,_customExercises = customExercises;
  factory _BuddyContext.fromJson(Map<String, dynamic> json) => _$BuddyContextFromJson(json);

 final  List<BuddyPersonalFood> _personalFoods;
@override List<BuddyPersonalFood> get personalFoods {
  if (_personalFoods is EqualUnmodifiableListView) return _personalFoods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_personalFoods);
}

 final  List<BuddyNamedReference> _savedMeals;
@override List<BuddyNamedReference> get savedMeals {
  if (_savedMeals is EqualUnmodifiableListView) return _savedMeals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_savedMeals);
}

 final  List<BuddyNamedReference> _openBatches;
@override List<BuddyNamedReference> get openBatches {
  if (_openBatches is EqualUnmodifiableListView) return _openBatches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_openBatches);
}

 final  List<BuddyMemory> _memory;
@override List<BuddyMemory> get memory {
  if (_memory is EqualUnmodifiableListView) return _memory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memory);
}

/// Ordered newest first; at most 30, about 3 days. Only date, slot and name are forwarded to the model.
 final  List<BuddyRecentEntry> _recentEntries;
/// Ordered newest first; at most 30, about 3 days. Only date, slot and name are forwarded to the model.
@override List<BuddyRecentEntry> get recentEntries {
  if (_recentEntries is EqualUnmodifiableListView) return _recentEntries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentEntries);
}

 final  List<BuddyNamedReference> _customExercises;
@override List<BuddyNamedReference> get customExercises {
  if (_customExercises is EqualUnmodifiableListView) return _customExercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customExercises);
}

/// The open proposal card a follow-up refers to (AI-044). Requires activeProposal (else 400). Optional: older apps omit it; absent and null are the same. Its slot, time and line name/amount/unitCode/state are forwarded to the model.
@override final  BuddyActiveCard? activeCard;

/// Create a copy of BuddyContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyContextCopyWith<_BuddyContext> get copyWith => __$BuddyContextCopyWithImpl<_BuddyContext>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyContextToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyContext&&const DeepCollectionEquality().equals(other.personalFoods, _personalFoods)&&const DeepCollectionEquality().equals(other.savedMeals, _savedMeals)&&const DeepCollectionEquality().equals(other.openBatches, _openBatches)&&const DeepCollectionEquality().equals(other.memory, _memory)&&const DeepCollectionEquality().equals(other.recentEntries, _recentEntries)&&const DeepCollectionEquality().equals(other.customExercises, _customExercises)&&(identical(other.activeCard, activeCard) || other.activeCard == activeCard));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_personalFoods),const DeepCollectionEquality().hash(_savedMeals),const DeepCollectionEquality().hash(_openBatches),const DeepCollectionEquality().hash(_memory),const DeepCollectionEquality().hash(_recentEntries),const DeepCollectionEquality().hash(_customExercises),activeCard);
}

@override
String toString() {
    return 'BuddyContext(personalFoods: $personalFoods, savedMeals: $savedMeals, openBatches: $openBatches, memory: $memory, recentEntries: $recentEntries, customExercises: $customExercises, activeCard: $activeCard)';
}


}

/// @nodoc
abstract mixin class _$BuddyContextCopyWith<$Res> implements $BuddyContextCopyWith<$Res> {
  factory _$BuddyContextCopyWith(_BuddyContext value, $Res Function(_BuddyContext) _then) = __$BuddyContextCopyWithImpl;
@override @useResult
$Res call({
 List<BuddyPersonalFood> personalFoods, List<BuddyNamedReference> savedMeals, List<BuddyNamedReference> openBatches, List<BuddyMemory> memory, List<BuddyRecentEntry> recentEntries, List<BuddyNamedReference> customExercises, BuddyActiveCard? activeCard
});


@override $BuddyActiveCardCopyWith<$Res>? get activeCard;

}
/// @nodoc
class __$BuddyContextCopyWithImpl<$Res>
    implements _$BuddyContextCopyWith<$Res> {
  __$BuddyContextCopyWithImpl(this._self, this._then);

  final _BuddyContext _self;
  final $Res Function(_BuddyContext) _then;

/// Create a copy of BuddyContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? personalFoods = null,Object? savedMeals = null,Object? openBatches = null,Object? memory = null,Object? recentEntries = null,Object? customExercises = null,Object? activeCard = freezed,}) {
  return _then(_BuddyContext(
personalFoods: null == personalFoods ? _self._personalFoods : personalFoods // ignore: cast_nullable_to_non_nullable
as List<BuddyPersonalFood>,savedMeals: null == savedMeals ? _self._savedMeals : savedMeals // ignore: cast_nullable_to_non_nullable
as List<BuddyNamedReference>,openBatches: null == openBatches ? _self._openBatches : openBatches // ignore: cast_nullable_to_non_nullable
as List<BuddyNamedReference>,memory: null == memory ? _self._memory : memory // ignore: cast_nullable_to_non_nullable
as List<BuddyMemory>,recentEntries: null == recentEntries ? _self._recentEntries : recentEntries // ignore: cast_nullable_to_non_nullable
as List<BuddyRecentEntry>,customExercises: null == customExercises ? _self._customExercises : customExercises // ignore: cast_nullable_to_non_nullable
as List<BuddyNamedReference>,activeCard: freezed == activeCard ? _self.activeCard : activeCard // ignore: cast_nullable_to_non_nullable
as BuddyActiveCard?,
  ));
}

/// Create a copy of BuddyContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyActiveCardCopyWith<$Res>? get activeCard {
    if (_self.activeCard == null) {
    return null;
  }

  return $BuddyActiveCardCopyWith<$Res>(_self.activeCard!, (value) {
    return _then(_self.copyWith(activeCard: value));
  });
}
}

// dart format on
