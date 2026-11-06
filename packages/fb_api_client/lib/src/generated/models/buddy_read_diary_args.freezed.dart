// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_diary_args.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadDiaryArgs {

/// A day in the closed day grammar (as on intents), or null when range is set.
 String? get dateHint; BuddyDateRange? get range; String? get slotHint; String? get query;
/// Create a copy of BuddyReadDiaryArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadDiaryArgsCopyWith<BuddyReadDiaryArgs> get copyWith => _$BuddyReadDiaryArgsCopyWithImpl<BuddyReadDiaryArgs>(this as BuddyReadDiaryArgs, _$identity);

  /// Serializes this BuddyReadDiaryArgs to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadDiaryArgs;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadDiaryArgs&&(identical(other.dateHint, _this.dateHint) || other.dateHint == _this.dateHint)&&(identical(other.range, _this.range) || other.range == _this.range)&&(identical(other.slotHint, _this.slotHint) || other.slotHint == _this.slotHint)&&(identical(other.query, _this.query) || other.query == _this.query));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadDiaryArgs;
  return Object.hash(runtimeType,_this.dateHint,_this.range,_this.slotHint,_this.query);
}

@override
String toString() {
  final _this = this as BuddyReadDiaryArgs;
  return 'BuddyReadDiaryArgs(dateHint: ${_this.dateHint}, range: ${_this.range}, slotHint: ${_this.slotHint}, query: ${_this.query})';
}


}

/// @nodoc
abstract mixin class $BuddyReadDiaryArgsCopyWith<$Res>  {
  factory $BuddyReadDiaryArgsCopyWith(BuddyReadDiaryArgs value, $Res Function(BuddyReadDiaryArgs) _then) = _$BuddyReadDiaryArgsCopyWithImpl;
@useResult
$Res call({
 String? dateHint, BuddyDateRange? range, String? slotHint, String? query
});


$BuddyDateRangeCopyWith<$Res>? get range;

}
/// @nodoc
class _$BuddyReadDiaryArgsCopyWithImpl<$Res>
    implements $BuddyReadDiaryArgsCopyWith<$Res> {
  _$BuddyReadDiaryArgsCopyWithImpl(this._self, this._then);

  final BuddyReadDiaryArgs _self;
  final $Res Function(BuddyReadDiaryArgs) _then;

/// Create a copy of BuddyReadDiaryArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dateHint = freezed,Object? range = freezed,Object? slotHint = freezed,Object? query = freezed,}) {
  return _then(BuddyReadDiaryArgs(
dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,range: freezed == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as BuddyDateRange?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BuddyReadDiaryArgs
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDateRangeCopyWith<$Res>? get range {
    if (_self.range == null) {
    return null;
  }

  return $BuddyDateRangeCopyWith<$Res>(_self.range!, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyReadDiaryArgs].
extension BuddyReadDiaryArgsPatterns on BuddyReadDiaryArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadDiaryArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadDiaryArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadDiaryArgs value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadDiaryArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadDiaryArgs value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadDiaryArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? dateHint,  BuddyDateRange? range,  String? slotHint,  String? query)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadDiaryArgs() when $default != null:
return $default(_that.dateHint,_that.range,_that.slotHint,_that.query);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? dateHint,  BuddyDateRange? range,  String? slotHint,  String? query)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadDiaryArgs():
return $default(_that.dateHint,_that.range,_that.slotHint,_that.query);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? dateHint,  BuddyDateRange? range,  String? slotHint,  String? query)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadDiaryArgs() when $default != null:
return $default(_that.dateHint,_that.range,_that.slotHint,_that.query);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadDiaryArgs implements BuddyReadDiaryArgs {
  const _BuddyReadDiaryArgs({required this.dateHint, required this.range, required this.slotHint, required this.query});
  factory _BuddyReadDiaryArgs.fromJson(Map<String, dynamic> json) => _$BuddyReadDiaryArgsFromJson(json);

/// A day in the closed day grammar (as on intents), or null when range is set.
@override final  String? dateHint;
@override final  BuddyDateRange? range;
@override final  String? slotHint;
@override final  String? query;

/// Create a copy of BuddyReadDiaryArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadDiaryArgsCopyWith<_BuddyReadDiaryArgs> get copyWith => __$BuddyReadDiaryArgsCopyWithImpl<_BuddyReadDiaryArgs>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadDiaryArgsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadDiaryArgs&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint)&&(identical(other.range, range) || other.range == range)&&(identical(other.slotHint, slotHint) || other.slotHint == slotHint)&&(identical(other.query, query) || other.query == query));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,dateHint,range,slotHint,query);
}

@override
String toString() {
    return 'BuddyReadDiaryArgs(dateHint: $dateHint, range: $range, slotHint: $slotHint, query: $query)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadDiaryArgsCopyWith<$Res> implements $BuddyReadDiaryArgsCopyWith<$Res> {
  factory _$BuddyReadDiaryArgsCopyWith(_BuddyReadDiaryArgs value, $Res Function(_BuddyReadDiaryArgs) _then) = __$BuddyReadDiaryArgsCopyWithImpl;
@override @useResult
$Res call({
 String? dateHint, BuddyDateRange? range, String? slotHint, String? query
});


@override $BuddyDateRangeCopyWith<$Res>? get range;

}
/// @nodoc
class __$BuddyReadDiaryArgsCopyWithImpl<$Res>
    implements _$BuddyReadDiaryArgsCopyWith<$Res> {
  __$BuddyReadDiaryArgsCopyWithImpl(this._self, this._then);

  final _BuddyReadDiaryArgs _self;
  final $Res Function(_BuddyReadDiaryArgs) _then;

/// Create a copy of BuddyReadDiaryArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dateHint = freezed,Object? range = freezed,Object? slotHint = freezed,Object? query = freezed,}) {
  return _then(_BuddyReadDiaryArgs(
dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,range: freezed == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as BuddyDateRange?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BuddyReadDiaryArgs
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDateRangeCopyWith<$Res>? get range {
    if (_self.range == null) {
    return null;
  }

  return $BuddyDateRangeCopyWith<$Res>(_self.range!, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}

// dart format on
