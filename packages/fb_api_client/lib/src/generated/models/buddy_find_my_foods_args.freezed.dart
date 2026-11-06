// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_find_my_foods_args.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyFindMyFoodsArgs {

 String get query;/// Empty means every kind.
 List<BuddyPersonalKind> get kinds;
/// Create a copy of BuddyFindMyFoodsArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyFindMyFoodsArgsCopyWith<BuddyFindMyFoodsArgs> get copyWith => _$BuddyFindMyFoodsArgsCopyWithImpl<BuddyFindMyFoodsArgs>(this as BuddyFindMyFoodsArgs, _$identity);

  /// Serializes this BuddyFindMyFoodsArgs to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyFindMyFoodsArgs;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyFindMyFoodsArgs&&(identical(other.query, _this.query) || other.query == _this.query)&&const DeepCollectionEquality().equals(other.kinds, _this.kinds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyFindMyFoodsArgs;
  return Object.hash(runtimeType,_this.query,const DeepCollectionEquality().hash(_this.kinds));
}

@override
String toString() {
  final _this = this as BuddyFindMyFoodsArgs;
  return 'BuddyFindMyFoodsArgs(query: ${_this.query}, kinds: ${_this.kinds})';
}


}

/// @nodoc
abstract mixin class $BuddyFindMyFoodsArgsCopyWith<$Res>  {
  factory $BuddyFindMyFoodsArgsCopyWith(BuddyFindMyFoodsArgs value, $Res Function(BuddyFindMyFoodsArgs) _then) = _$BuddyFindMyFoodsArgsCopyWithImpl;
@useResult
$Res call({
 String query, List<BuddyPersonalKind> kinds
});




}
/// @nodoc
class _$BuddyFindMyFoodsArgsCopyWithImpl<$Res>
    implements $BuddyFindMyFoodsArgsCopyWith<$Res> {
  _$BuddyFindMyFoodsArgsCopyWithImpl(this._self, this._then);

  final BuddyFindMyFoodsArgs _self;
  final $Res Function(BuddyFindMyFoodsArgs) _then;

/// Create a copy of BuddyFindMyFoodsArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? kinds = null,}) {
  return _then(BuddyFindMyFoodsArgs(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,kinds: null == kinds ? _self.kinds : kinds // ignore: cast_nullable_to_non_nullable
as List<BuddyPersonalKind>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyFindMyFoodsArgs].
extension BuddyFindMyFoodsArgsPatterns on BuddyFindMyFoodsArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyFindMyFoodsArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyFindMyFoodsArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyFindMyFoodsArgs value)  $default,){
final _that = this;
switch (_that) {
case _BuddyFindMyFoodsArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyFindMyFoodsArgs value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyFindMyFoodsArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  List<BuddyPersonalKind> kinds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyFindMyFoodsArgs() when $default != null:
return $default(_that.query,_that.kinds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  List<BuddyPersonalKind> kinds)  $default,) {final _that = this;
switch (_that) {
case _BuddyFindMyFoodsArgs():
return $default(_that.query,_that.kinds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  List<BuddyPersonalKind> kinds)?  $default,) {final _that = this;
switch (_that) {
case _BuddyFindMyFoodsArgs() when $default != null:
return $default(_that.query,_that.kinds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyFindMyFoodsArgs implements BuddyFindMyFoodsArgs {
  const _BuddyFindMyFoodsArgs({required this.query, required  List<BuddyPersonalKind> kinds}): _kinds = kinds;
  factory _BuddyFindMyFoodsArgs.fromJson(Map<String, dynamic> json) => _$BuddyFindMyFoodsArgsFromJson(json);

@override final  String query;
/// Empty means every kind.
 final  List<BuddyPersonalKind> _kinds;
/// Empty means every kind.
@override List<BuddyPersonalKind> get kinds {
  if (_kinds is EqualUnmodifiableListView) return _kinds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_kinds);
}


/// Create a copy of BuddyFindMyFoodsArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyFindMyFoodsArgsCopyWith<_BuddyFindMyFoodsArgs> get copyWith => __$BuddyFindMyFoodsArgsCopyWithImpl<_BuddyFindMyFoodsArgs>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyFindMyFoodsArgsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyFindMyFoodsArgs&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other.kinds, _kinds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,query,const DeepCollectionEquality().hash(_kinds));
}

@override
String toString() {
    return 'BuddyFindMyFoodsArgs(query: $query, kinds: $kinds)';
}


}

/// @nodoc
abstract mixin class _$BuddyFindMyFoodsArgsCopyWith<$Res> implements $BuddyFindMyFoodsArgsCopyWith<$Res> {
  factory _$BuddyFindMyFoodsArgsCopyWith(_BuddyFindMyFoodsArgs value, $Res Function(_BuddyFindMyFoodsArgs) _then) = __$BuddyFindMyFoodsArgsCopyWithImpl;
@override @useResult
$Res call({
 String query, List<BuddyPersonalKind> kinds
});




}
/// @nodoc
class __$BuddyFindMyFoodsArgsCopyWithImpl<$Res>
    implements _$BuddyFindMyFoodsArgsCopyWith<$Res> {
  __$BuddyFindMyFoodsArgsCopyWithImpl(this._self, this._then);

  final _BuddyFindMyFoodsArgs _self;
  final $Res Function(_BuddyFindMyFoodsArgs) _then;

/// Create a copy of BuddyFindMyFoodsArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? kinds = null,}) {
  return _then(_BuddyFindMyFoodsArgs(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,kinds: null == kinds ? _self._kinds : kinds // ignore: cast_nullable_to_non_nullable
as List<BuddyPersonalKind>,
  ));
}


}

// dart format on
