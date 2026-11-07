// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_label_extraction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyLabelExtraction {

/// False when no nutrition panel could be read; then basis and serving are null and every value is null.
 bool get found; BuddyLabelBasis? get basis; BuddyLabelServing? get serving; BuddyLabelText get name; BuddyLabelNutrients get nutrients;/// Other nutrients the label lists (vitamins, minerals…), as printed.
 List<BuddyLabelOther> get others;
/// Create a copy of BuddyLabelExtraction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyLabelExtractionCopyWith<BuddyLabelExtraction> get copyWith => _$BuddyLabelExtractionCopyWithImpl<BuddyLabelExtraction>(this as BuddyLabelExtraction, _$identity);

  /// Serializes this BuddyLabelExtraction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyLabelExtraction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyLabelExtraction&&(identical(other.found, _this.found) || other.found == _this.found)&&(identical(other.basis, _this.basis) || other.basis == _this.basis)&&(identical(other.serving, _this.serving) || other.serving == _this.serving)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.nutrients, _this.nutrients) || other.nutrients == _this.nutrients)&&const DeepCollectionEquality().equals(other.others, _this.others));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyLabelExtraction;
  return Object.hash(runtimeType,_this.found,_this.basis,_this.serving,_this.name,_this.nutrients,const DeepCollectionEquality().hash(_this.others));
}

@override
String toString() {
  final _this = this as BuddyLabelExtraction;
  return 'BuddyLabelExtraction(found: ${_this.found}, basis: ${_this.basis}, serving: ${_this.serving}, name: ${_this.name}, nutrients: ${_this.nutrients}, others: ${_this.others})';
}


}

/// @nodoc
abstract mixin class $BuddyLabelExtractionCopyWith<$Res>  {
  factory $BuddyLabelExtractionCopyWith(BuddyLabelExtraction value, $Res Function(BuddyLabelExtraction) _then) = _$BuddyLabelExtractionCopyWithImpl;
@useResult
$Res call({
 bool found, BuddyLabelBasis? basis, BuddyLabelServing? serving, BuddyLabelText name, BuddyLabelNutrients nutrients, List<BuddyLabelOther> others
});


$BuddyLabelServingCopyWith<$Res>? get serving;$BuddyLabelTextCopyWith<$Res> get name;$BuddyLabelNutrientsCopyWith<$Res> get nutrients;

}
/// @nodoc
class _$BuddyLabelExtractionCopyWithImpl<$Res>
    implements $BuddyLabelExtractionCopyWith<$Res> {
  _$BuddyLabelExtractionCopyWithImpl(this._self, this._then);

  final BuddyLabelExtraction _self;
  final $Res Function(BuddyLabelExtraction) _then;

/// Create a copy of BuddyLabelExtraction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? found = null,Object? basis = freezed,Object? serving = freezed,Object? name = null,Object? nutrients = null,Object? others = null,}) {
  return _then(BuddyLabelExtraction(
found: null == found ? _self.found : found // ignore: cast_nullable_to_non_nullable
as bool,basis: freezed == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as BuddyLabelBasis?,serving: freezed == serving ? _self.serving : serving // ignore: cast_nullable_to_non_nullable
as BuddyLabelServing?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyLabelText,nutrients: null == nutrients ? _self.nutrients : nutrients // ignore: cast_nullable_to_non_nullable
as BuddyLabelNutrients,others: null == others ? _self.others : others // ignore: cast_nullable_to_non_nullable
as List<BuddyLabelOther>,
  ));
}
/// Create a copy of BuddyLabelExtraction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyLabelServingCopyWith<$Res>? get serving {
    if (_self.serving == null) {
    return null;
  }

  return $BuddyLabelServingCopyWith<$Res>(_self.serving!, (value) {
    return _then(_self.copyWith(serving: value));
  });
}/// Create a copy of BuddyLabelExtraction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyLabelTextCopyWith<$Res> get name {
  
  return $BuddyLabelTextCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}/// Create a copy of BuddyLabelExtraction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyLabelNutrientsCopyWith<$Res> get nutrients {
  
  return $BuddyLabelNutrientsCopyWith<$Res>(_self.nutrients, (value) {
    return _then(_self.copyWith(nutrients: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyLabelExtraction].
extension BuddyLabelExtractionPatterns on BuddyLabelExtraction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyLabelExtraction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyLabelExtraction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyLabelExtraction value)  $default,){
final _that = this;
switch (_that) {
case _BuddyLabelExtraction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyLabelExtraction value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyLabelExtraction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool found,  BuddyLabelBasis? basis,  BuddyLabelServing? serving,  BuddyLabelText name,  BuddyLabelNutrients nutrients,  List<BuddyLabelOther> others)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyLabelExtraction() when $default != null:
return $default(_that.found,_that.basis,_that.serving,_that.name,_that.nutrients,_that.others);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool found,  BuddyLabelBasis? basis,  BuddyLabelServing? serving,  BuddyLabelText name,  BuddyLabelNutrients nutrients,  List<BuddyLabelOther> others)  $default,) {final _that = this;
switch (_that) {
case _BuddyLabelExtraction():
return $default(_that.found,_that.basis,_that.serving,_that.name,_that.nutrients,_that.others);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool found,  BuddyLabelBasis? basis,  BuddyLabelServing? serving,  BuddyLabelText name,  BuddyLabelNutrients nutrients,  List<BuddyLabelOther> others)?  $default,) {final _that = this;
switch (_that) {
case _BuddyLabelExtraction() when $default != null:
return $default(_that.found,_that.basis,_that.serving,_that.name,_that.nutrients,_that.others);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyLabelExtraction implements BuddyLabelExtraction {
  const _BuddyLabelExtraction({required this.found, required this.basis, required this.serving, required this.name, required this.nutrients, required  List<BuddyLabelOther> others}): _others = others;
  factory _BuddyLabelExtraction.fromJson(Map<String, dynamic> json) => _$BuddyLabelExtractionFromJson(json);

/// False when no nutrition panel could be read; then basis and serving are null and every value is null.
@override final  bool found;
@override final  BuddyLabelBasis? basis;
@override final  BuddyLabelServing? serving;
@override final  BuddyLabelText name;
@override final  BuddyLabelNutrients nutrients;
/// Other nutrients the label lists (vitamins, minerals…), as printed.
 final  List<BuddyLabelOther> _others;
/// Other nutrients the label lists (vitamins, minerals…), as printed.
@override List<BuddyLabelOther> get others {
  if (_others is EqualUnmodifiableListView) return _others;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_others);
}


/// Create a copy of BuddyLabelExtraction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyLabelExtractionCopyWith<_BuddyLabelExtraction> get copyWith => __$BuddyLabelExtractionCopyWithImpl<_BuddyLabelExtraction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyLabelExtractionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyLabelExtraction&&(identical(other.found, found) || other.found == found)&&(identical(other.basis, basis) || other.basis == basis)&&(identical(other.serving, serving) || other.serving == serving)&&(identical(other.name, name) || other.name == name)&&(identical(other.nutrients, nutrients) || other.nutrients == nutrients)&&const DeepCollectionEquality().equals(other.others, _others));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,found,basis,serving,name,nutrients,const DeepCollectionEquality().hash(_others));
}

@override
String toString() {
    return 'BuddyLabelExtraction(found: $found, basis: $basis, serving: $serving, name: $name, nutrients: $nutrients, others: $others)';
}


}

/// @nodoc
abstract mixin class _$BuddyLabelExtractionCopyWith<$Res> implements $BuddyLabelExtractionCopyWith<$Res> {
  factory _$BuddyLabelExtractionCopyWith(_BuddyLabelExtraction value, $Res Function(_BuddyLabelExtraction) _then) = __$BuddyLabelExtractionCopyWithImpl;
@override @useResult
$Res call({
 bool found, BuddyLabelBasis? basis, BuddyLabelServing? serving, BuddyLabelText name, BuddyLabelNutrients nutrients, List<BuddyLabelOther> others
});


@override $BuddyLabelServingCopyWith<$Res>? get serving;@override $BuddyLabelTextCopyWith<$Res> get name;@override $BuddyLabelNutrientsCopyWith<$Res> get nutrients;

}
/// @nodoc
class __$BuddyLabelExtractionCopyWithImpl<$Res>
    implements _$BuddyLabelExtractionCopyWith<$Res> {
  __$BuddyLabelExtractionCopyWithImpl(this._self, this._then);

  final _BuddyLabelExtraction _self;
  final $Res Function(_BuddyLabelExtraction) _then;

/// Create a copy of BuddyLabelExtraction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? found = null,Object? basis = freezed,Object? serving = freezed,Object? name = null,Object? nutrients = null,Object? others = null,}) {
  return _then(_BuddyLabelExtraction(
found: null == found ? _self.found : found // ignore: cast_nullable_to_non_nullable
as bool,basis: freezed == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as BuddyLabelBasis?,serving: freezed == serving ? _self.serving : serving // ignore: cast_nullable_to_non_nullable
as BuddyLabelServing?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyLabelText,nutrients: null == nutrients ? _self.nutrients : nutrients // ignore: cast_nullable_to_non_nullable
as BuddyLabelNutrients,others: null == others ? _self._others : others // ignore: cast_nullable_to_non_nullable
as List<BuddyLabelOther>,
  ));
}

/// Create a copy of BuddyLabelExtraction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyLabelServingCopyWith<$Res>? get serving {
    if (_self.serving == null) {
    return null;
  }

  return $BuddyLabelServingCopyWith<$Res>(_self.serving!, (value) {
    return _then(_self.copyWith(serving: value));
  });
}/// Create a copy of BuddyLabelExtraction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyLabelTextCopyWith<$Res> get name {
  
  return $BuddyLabelTextCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}/// Create a copy of BuddyLabelExtraction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyLabelNutrientsCopyWith<$Res> get nutrients {
  
  return $BuddyLabelNutrientsCopyWith<$Res>(_self.nutrients, (value) {
    return _then(_self.copyWith(nutrients: value));
  });
}
}

// dart format on
