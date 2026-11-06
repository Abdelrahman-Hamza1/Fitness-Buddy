// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_outcome.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyOutcome {

/// The card's intent kind (open, ≤ 32).
 String get kind; String get proposalId; BuddyOutcomeStatus get status;/// The card's compact summary as the phone shows it.
 String get label;
/// Create a copy of BuddyOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyOutcomeCopyWith<BuddyOutcome> get copyWith => _$BuddyOutcomeCopyWithImpl<BuddyOutcome>(this as BuddyOutcome, _$identity);

  /// Serializes this BuddyOutcome to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyOutcome;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyOutcome&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.proposalId, _this.proposalId) || other.proposalId == _this.proposalId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.label, _this.label) || other.label == _this.label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyOutcome;
  return Object.hash(runtimeType,_this.kind,_this.proposalId,_this.status,_this.label);
}

@override
String toString() {
  final _this = this as BuddyOutcome;
  return 'BuddyOutcome(kind: ${_this.kind}, proposalId: ${_this.proposalId}, status: ${_this.status}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $BuddyOutcomeCopyWith<$Res>  {
  factory $BuddyOutcomeCopyWith(BuddyOutcome value, $Res Function(BuddyOutcome) _then) = _$BuddyOutcomeCopyWithImpl;
@useResult
$Res call({
 String kind, String proposalId, BuddyOutcomeStatus status, String label
});




}
/// @nodoc
class _$BuddyOutcomeCopyWithImpl<$Res>
    implements $BuddyOutcomeCopyWith<$Res> {
  _$BuddyOutcomeCopyWithImpl(this._self, this._then);

  final BuddyOutcome _self;
  final $Res Function(BuddyOutcome) _then;

/// Create a copy of BuddyOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? proposalId = null,Object? status = null,Object? label = null,}) {
  return _then(BuddyOutcome(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,proposalId: null == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuddyOutcomeStatus,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyOutcome].
extension BuddyOutcomePatterns on BuddyOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyOutcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyOutcome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyOutcome value)  $default,){
final _that = this;
switch (_that) {
case _BuddyOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyOutcome value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyOutcome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String proposalId,  BuddyOutcomeStatus status,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyOutcome() when $default != null:
return $default(_that.kind,_that.proposalId,_that.status,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String proposalId,  BuddyOutcomeStatus status,  String label)  $default,) {final _that = this;
switch (_that) {
case _BuddyOutcome():
return $default(_that.kind,_that.proposalId,_that.status,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String proposalId,  BuddyOutcomeStatus status,  String label)?  $default,) {final _that = this;
switch (_that) {
case _BuddyOutcome() when $default != null:
return $default(_that.kind,_that.proposalId,_that.status,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyOutcome implements BuddyOutcome {
  const _BuddyOutcome({required this.kind, required this.proposalId, required this.status, required this.label});
  factory _BuddyOutcome.fromJson(Map<String, dynamic> json) => _$BuddyOutcomeFromJson(json);

/// The card's intent kind (open, ≤ 32).
@override final  String kind;
@override final  String proposalId;
@override final  BuddyOutcomeStatus status;
/// The card's compact summary as the phone shows it.
@override final  String label;

/// Create a copy of BuddyOutcome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyOutcomeCopyWith<_BuddyOutcome> get copyWith => __$BuddyOutcomeCopyWithImpl<_BuddyOutcome>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyOutcomeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyOutcome&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.proposalId, proposalId) || other.proposalId == proposalId)&&(identical(other.status, status) || other.status == status)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,proposalId,status,label);
}

@override
String toString() {
    return 'BuddyOutcome(kind: $kind, proposalId: $proposalId, status: $status, label: $label)';
}


}

/// @nodoc
abstract mixin class _$BuddyOutcomeCopyWith<$Res> implements $BuddyOutcomeCopyWith<$Res> {
  factory _$BuddyOutcomeCopyWith(_BuddyOutcome value, $Res Function(_BuddyOutcome) _then) = __$BuddyOutcomeCopyWithImpl;
@override @useResult
$Res call({
 String kind, String proposalId, BuddyOutcomeStatus status, String label
});




}
/// @nodoc
class __$BuddyOutcomeCopyWithImpl<$Res>
    implements _$BuddyOutcomeCopyWith<$Res> {
  __$BuddyOutcomeCopyWithImpl(this._self, this._then);

  final _BuddyOutcome _self;
  final $Res Function(_BuddyOutcome) _then;

/// Create a copy of BuddyOutcome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? proposalId = null,Object? status = null,Object? label = null,}) {
  return _then(_BuddyOutcome(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,proposalId: null == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuddyOutcomeStatus,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
