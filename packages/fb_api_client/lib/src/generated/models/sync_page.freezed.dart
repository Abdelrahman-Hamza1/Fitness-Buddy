// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncPage {

 List<SyncDocument> get changes; String get nextCursor;
/// Create a copy of SyncPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncPageCopyWith<SyncPage> get copyWith => _$SyncPageCopyWithImpl<SyncPage>(this as SyncPage, _$identity);

  /// Serializes this SyncPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncPage&&const DeepCollectionEquality().equals(other.changes, _this.changes)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncPage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.changes),_this.nextCursor);
}

@override
String toString() {
  final _this = this as SyncPage;
  return 'SyncPage(changes: ${_this.changes}, nextCursor: ${_this.nextCursor})';
}


}

/// @nodoc
abstract mixin class $SyncPageCopyWith<$Res>  {
  factory $SyncPageCopyWith(SyncPage value, $Res Function(SyncPage) _then) = _$SyncPageCopyWithImpl;
@useResult
$Res call({
 List<SyncDocument> changes, String nextCursor
});




}
/// @nodoc
class _$SyncPageCopyWithImpl<$Res>
    implements $SyncPageCopyWith<$Res> {
  _$SyncPageCopyWithImpl(this._self, this._then);

  final SyncPage _self;
  final $Res Function(SyncPage) _then;

/// Create a copy of SyncPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? changes = null,Object? nextCursor = null,}) {
  return _then(SyncPage(
changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as List<SyncDocument>,nextCursor: null == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncPage].
extension SyncPagePatterns on SyncPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncPage value)  $default,){
final _that = this;
switch (_that) {
case _SyncPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncPage value)?  $default,){
final _that = this;
switch (_that) {
case _SyncPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SyncDocument> changes,  String nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncPage() when $default != null:
return $default(_that.changes,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SyncDocument> changes,  String nextCursor)  $default,) {final _that = this;
switch (_that) {
case _SyncPage():
return $default(_that.changes,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SyncDocument> changes,  String nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _SyncPage() when $default != null:
return $default(_that.changes,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncPage implements SyncPage {
  const _SyncPage({required  List<SyncDocument> changes, required this.nextCursor}): _changes = changes;
  factory _SyncPage.fromJson(Map<String, dynamic> json) => _$SyncPageFromJson(json);

 final  List<SyncDocument> _changes;
@override List<SyncDocument> get changes {
  if (_changes is EqualUnmodifiableListView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_changes);
}

@override final  String nextCursor;

/// Create a copy of SyncPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncPageCopyWith<_SyncPage> get copyWith => __$SyncPageCopyWithImpl<_SyncPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncPageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncPage&&const DeepCollectionEquality().equals(other.changes, _changes)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_changes),nextCursor);
}

@override
String toString() {
    return 'SyncPage(changes: $changes, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$SyncPageCopyWith<$Res> implements $SyncPageCopyWith<$Res> {
  factory _$SyncPageCopyWith(_SyncPage value, $Res Function(_SyncPage) _then) = __$SyncPageCopyWithImpl;
@override @useResult
$Res call({
 List<SyncDocument> changes, String nextCursor
});




}
/// @nodoc
class __$SyncPageCopyWithImpl<$Res>
    implements _$SyncPageCopyWith<$Res> {
  __$SyncPageCopyWithImpl(this._self, this._then);

  final _SyncPage _self;
  final $Res Function(_SyncPage) _then;

/// Create a copy of SyncPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? changes = null,Object? nextCursor = null,}) {
  return _then(_SyncPage(
changes: null == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as List<SyncDocument>,nextCursor: null == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
