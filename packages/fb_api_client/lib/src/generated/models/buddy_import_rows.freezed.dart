// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_import_rows.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyImportRows {

 BuddyImportRowsKind get kind; String get language; String get script; BuddyImportMetric get metric; BuddyBodyMeasurementKind? get measurementKind; List<BuddyImportRow> get rows;
/// Create a copy of BuddyImportRows
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyImportRowsCopyWith<BuddyImportRows> get copyWith => _$BuddyImportRowsCopyWithImpl<BuddyImportRows>(this as BuddyImportRows, _$identity);

  /// Serializes this BuddyImportRows to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyImportRows;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyImportRows&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.metric, _this.metric) || other.metric == _this.metric)&&(identical(other.measurementKind, _this.measurementKind) || other.measurementKind == _this.measurementKind)&&const DeepCollectionEquality().equals(other.rows, _this.rows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyImportRows;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.metric,_this.measurementKind,const DeepCollectionEquality().hash(_this.rows));
}

@override
String toString() {
  final _this = this as BuddyImportRows;
  return 'BuddyImportRows(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, metric: ${_this.metric}, measurementKind: ${_this.measurementKind}, rows: ${_this.rows})';
}


}

/// @nodoc
abstract mixin class $BuddyImportRowsCopyWith<$Res>  {
  factory $BuddyImportRowsCopyWith(BuddyImportRows value, $Res Function(BuddyImportRows) _then) = _$BuddyImportRowsCopyWithImpl;
@useResult
$Res call({
 BuddyImportRowsKind kind, String language, String script, BuddyImportMetric metric, BuddyBodyMeasurementKind? measurementKind, List<BuddyImportRow> rows
});




}
/// @nodoc
class _$BuddyImportRowsCopyWithImpl<$Res>
    implements $BuddyImportRowsCopyWith<$Res> {
  _$BuddyImportRowsCopyWithImpl(this._self, this._then);

  final BuddyImportRows _self;
  final $Res Function(BuddyImportRows) _then;

/// Create a copy of BuddyImportRows
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? metric = null,Object? measurementKind = freezed,Object? rows = null,}) {
  return _then(BuddyImportRows(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyImportRowsKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as BuddyImportMetric,measurementKind: freezed == measurementKind ? _self.measurementKind : measurementKind // ignore: cast_nullable_to_non_nullable
as BuddyBodyMeasurementKind?,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<BuddyImportRow>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyImportRows].
extension BuddyImportRowsPatterns on BuddyImportRows {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyImportRows value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyImportRows() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyImportRows value)  $default,){
final _that = this;
switch (_that) {
case _BuddyImportRows():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyImportRows value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyImportRows() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyImportRowsKind kind,  String language,  String script,  BuddyImportMetric metric,  BuddyBodyMeasurementKind? measurementKind,  List<BuddyImportRow> rows)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyImportRows() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.metric,_that.measurementKind,_that.rows);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyImportRowsKind kind,  String language,  String script,  BuddyImportMetric metric,  BuddyBodyMeasurementKind? measurementKind,  List<BuddyImportRow> rows)  $default,) {final _that = this;
switch (_that) {
case _BuddyImportRows():
return $default(_that.kind,_that.language,_that.script,_that.metric,_that.measurementKind,_that.rows);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyImportRowsKind kind,  String language,  String script,  BuddyImportMetric metric,  BuddyBodyMeasurementKind? measurementKind,  List<BuddyImportRow> rows)?  $default,) {final _that = this;
switch (_that) {
case _BuddyImportRows() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.metric,_that.measurementKind,_that.rows);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyImportRows implements BuddyImportRows {
  const _BuddyImportRows({required this.kind, required this.language, required this.script, required this.metric, required this.measurementKind, required  List<BuddyImportRow> rows}): _rows = rows;
  factory _BuddyImportRows.fromJson(Map<String, dynamic> json) => _$BuddyImportRowsFromJson(json);

@override final  BuddyImportRowsKind kind;
@override final  String language;
@override final  String script;
@override final  BuddyImportMetric metric;
@override final  BuddyBodyMeasurementKind? measurementKind;
 final  List<BuddyImportRow> _rows;
@override List<BuddyImportRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}


/// Create a copy of BuddyImportRows
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyImportRowsCopyWith<_BuddyImportRows> get copyWith => __$BuddyImportRowsCopyWithImpl<_BuddyImportRows>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyImportRowsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyImportRows&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.metric, metric) || other.metric == metric)&&(identical(other.measurementKind, measurementKind) || other.measurementKind == measurementKind)&&const DeepCollectionEquality().equals(other.rows, _rows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,metric,measurementKind,const DeepCollectionEquality().hash(_rows));
}

@override
String toString() {
    return 'BuddyImportRows(kind: $kind, language: $language, script: $script, metric: $metric, measurementKind: $measurementKind, rows: $rows)';
}


}

/// @nodoc
abstract mixin class _$BuddyImportRowsCopyWith<$Res> implements $BuddyImportRowsCopyWith<$Res> {
  factory _$BuddyImportRowsCopyWith(_BuddyImportRows value, $Res Function(_BuddyImportRows) _then) = __$BuddyImportRowsCopyWithImpl;
@override @useResult
$Res call({
 BuddyImportRowsKind kind, String language, String script, BuddyImportMetric metric, BuddyBodyMeasurementKind? measurementKind, List<BuddyImportRow> rows
});




}
/// @nodoc
class __$BuddyImportRowsCopyWithImpl<$Res>
    implements _$BuddyImportRowsCopyWith<$Res> {
  __$BuddyImportRowsCopyWithImpl(this._self, this._then);

  final _BuddyImportRows _self;
  final $Res Function(_BuddyImportRows) _then;

/// Create a copy of BuddyImportRows
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? metric = null,Object? measurementKind = freezed,Object? rows = null,}) {
  return _then(_BuddyImportRows(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyImportRowsKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as BuddyImportMetric,measurementKind: freezed == measurementKind ? _self.measurementKind : measurementKind // ignore: cast_nullable_to_non_nullable
as BuddyBodyMeasurementKind?,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<BuddyImportRow>,
  ));
}


}

// dart format on
