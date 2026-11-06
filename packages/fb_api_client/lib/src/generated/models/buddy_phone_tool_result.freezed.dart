// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_phone_tool_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
BuddyPhoneToolResult _$BuddyPhoneToolResultFromJson(
  Map<String, dynamic> json
) {
        switch (json['name']) {
                  case 'findMyFoods':
          return BuddyPhoneToolResultFindMyFoods.fromJson(
            json
          );
                case 'readDiary':
          return BuddyPhoneToolResultReadDiary.fromJson(
            json
          );
                case 'readBody':
          return BuddyPhoneToolResultReadBody.fromJson(
            json
          );
                case 'readWorkouts':
          return BuddyPhoneToolResultReadWorkouts.fromJson(
            json
          );
                case 'readMemory':
          return BuddyPhoneToolResultReadMemory.fromJson(
            json
          );
                case 'queryData':
          return BuddyPhoneToolResultQueryData.fromJson(
            json
          );
        
          default:
            return BuddyPhoneToolResultUnrecognized.fromJson(
  json
);
        }
      
}

/// @nodoc
mixin _$BuddyPhoneToolResult {



  /// Serializes this BuddyPhoneToolResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolResult);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BuddyPhoneToolResult()';
}


}

/// @nodoc
class $BuddyPhoneToolResultCopyWith<$Res>  {
$BuddyPhoneToolResultCopyWith(BuddyPhoneToolResult _, $Res Function(BuddyPhoneToolResult) __);
}


/// Adds pattern-matching-related methods to [BuddyPhoneToolResult].
extension BuddyPhoneToolResultPatterns on BuddyPhoneToolResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BuddyPhoneToolResultFindMyFoods value)?  findMyFoods,TResult Function( BuddyPhoneToolResultReadDiary value)?  readDiary,TResult Function( BuddyPhoneToolResultReadBody value)?  readBody,TResult Function( BuddyPhoneToolResultReadWorkouts value)?  readWorkouts,TResult Function( BuddyPhoneToolResultReadMemory value)?  readMemory,TResult Function( BuddyPhoneToolResultQueryData value)?  queryData,TResult Function( BuddyPhoneToolResultUnrecognized value)?  unrecognized,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BuddyPhoneToolResultFindMyFoods() when findMyFoods != null:
return findMyFoods(_that);case BuddyPhoneToolResultReadDiary() when readDiary != null:
return readDiary(_that);case BuddyPhoneToolResultReadBody() when readBody != null:
return readBody(_that);case BuddyPhoneToolResultReadWorkouts() when readWorkouts != null:
return readWorkouts(_that);case BuddyPhoneToolResultReadMemory() when readMemory != null:
return readMemory(_that);case BuddyPhoneToolResultQueryData() when queryData != null:
return queryData(_that);case BuddyPhoneToolResultUnrecognized() when unrecognized != null:
return unrecognized(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BuddyPhoneToolResultFindMyFoods value)  findMyFoods,required TResult Function( BuddyPhoneToolResultReadDiary value)  readDiary,required TResult Function( BuddyPhoneToolResultReadBody value)  readBody,required TResult Function( BuddyPhoneToolResultReadWorkouts value)  readWorkouts,required TResult Function( BuddyPhoneToolResultReadMemory value)  readMemory,required TResult Function( BuddyPhoneToolResultQueryData value)  queryData,required TResult Function( BuddyPhoneToolResultUnrecognized value)  unrecognized,}){
final _that = this;
switch (_that) {
case BuddyPhoneToolResultFindMyFoods():
return findMyFoods(_that);case BuddyPhoneToolResultReadDiary():
return readDiary(_that);case BuddyPhoneToolResultReadBody():
return readBody(_that);case BuddyPhoneToolResultReadWorkouts():
return readWorkouts(_that);case BuddyPhoneToolResultReadMemory():
return readMemory(_that);case BuddyPhoneToolResultQueryData():
return queryData(_that);case BuddyPhoneToolResultUnrecognized():
return unrecognized(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BuddyPhoneToolResultFindMyFoods value)?  findMyFoods,TResult? Function( BuddyPhoneToolResultReadDiary value)?  readDiary,TResult? Function( BuddyPhoneToolResultReadBody value)?  readBody,TResult? Function( BuddyPhoneToolResultReadWorkouts value)?  readWorkouts,TResult? Function( BuddyPhoneToolResultReadMemory value)?  readMemory,TResult? Function( BuddyPhoneToolResultQueryData value)?  queryData,TResult? Function( BuddyPhoneToolResultUnrecognized value)?  unrecognized,}){
final _that = this;
switch (_that) {
case BuddyPhoneToolResultFindMyFoods() when findMyFoods != null:
return findMyFoods(_that);case BuddyPhoneToolResultReadDiary() when readDiary != null:
return readDiary(_that);case BuddyPhoneToolResultReadBody() when readBody != null:
return readBody(_that);case BuddyPhoneToolResultReadWorkouts() when readWorkouts != null:
return readWorkouts(_that);case BuddyPhoneToolResultReadMemory() when readMemory != null:
return readMemory(_that);case BuddyPhoneToolResultQueryData() when queryData != null:
return queryData(_that);case BuddyPhoneToolResultUnrecognized() when unrecognized != null:
return unrecognized(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( BuddyFindMyFoodsResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyFindMyFoodsData? data)?  findMyFoods,TResult Function( BuddyReadDiaryResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadDiaryData? data)?  readDiary,TResult Function( BuddyReadBodyResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadBodyData? data)?  readBody,TResult Function( BuddyReadWorkoutsResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadWorkoutsData? data)?  readWorkouts,TResult Function( BuddyReadMemoryResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadMemoryData? data)?  readMemory,TResult Function( BuddyQueryDataResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyQueryResultData? data)?  queryData,TResult Function()?  unrecognized,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BuddyPhoneToolResultFindMyFoods() when findMyFoods != null:
return findMyFoods(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultReadDiary() when readDiary != null:
return readDiary(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultReadBody() when readBody != null:
return readBody(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultReadWorkouts() when readWorkouts != null:
return readWorkouts(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultReadMemory() when readMemory != null:
return readMemory(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultQueryData() when queryData != null:
return queryData(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultUnrecognized() when unrecognized != null:
return unrecognized();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( BuddyFindMyFoodsResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyFindMyFoodsData? data)  findMyFoods,required TResult Function( BuddyReadDiaryResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadDiaryData? data)  readDiary,required TResult Function( BuddyReadBodyResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadBodyData? data)  readBody,required TResult Function( BuddyReadWorkoutsResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadWorkoutsData? data)  readWorkouts,required TResult Function( BuddyReadMemoryResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadMemoryData? data)  readMemory,required TResult Function( BuddyQueryDataResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyQueryResultData? data)  queryData,required TResult Function()  unrecognized,}) {final _that = this;
switch (_that) {
case BuddyPhoneToolResultFindMyFoods():
return findMyFoods(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultReadDiary():
return readDiary(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultReadBody():
return readBody(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultReadWorkouts():
return readWorkouts(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultReadMemory():
return readMemory(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultQueryData():
return queryData(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultUnrecognized():
return unrecognized();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( BuddyFindMyFoodsResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyFindMyFoodsData? data)?  findMyFoods,TResult? Function( BuddyReadDiaryResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadDiaryData? data)?  readDiary,TResult? Function( BuddyReadBodyResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadBodyData? data)?  readBody,TResult? Function( BuddyReadWorkoutsResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadWorkoutsData? data)?  readWorkouts,TResult? Function( BuddyReadMemoryResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadMemoryData? data)?  readMemory,TResult? Function( BuddyQueryDataResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyQueryResultData? data)?  queryData,TResult? Function()?  unrecognized,}) {final _that = this;
switch (_that) {
case BuddyPhoneToolResultFindMyFoods() when findMyFoods != null:
return findMyFoods(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultReadDiary() when readDiary != null:
return readDiary(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultReadBody() when readBody != null:
return readBody(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultReadWorkouts() when readWorkouts != null:
return readWorkouts(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultReadMemory() when readMemory != null:
return readMemory(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultQueryData() when queryData != null:
return queryData(_that.name,_that.callId,_that.ok,_that.error,_that.data);case BuddyPhoneToolResultUnrecognized() when unrecognized != null:
return unrecognized();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolResultFindMyFoods implements BuddyPhoneToolResult {
  const BuddyPhoneToolResultFindMyFoods({required this.name, required this.callId, required this.ok, required this.error, required this.data});
  factory BuddyPhoneToolResultFindMyFoods.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolResultFindMyFoodsFromJson(json);

 final  BuddyFindMyFoodsResultName name;
 final  String callId;
 final  bool ok;
 final  BuddyPhoneToolError? error;
 final  BuddyFindMyFoodsData? data;

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPhoneToolResultFindMyFoodsCopyWith<BuddyPhoneToolResultFindMyFoods> get copyWith => _$BuddyPhoneToolResultFindMyFoodsCopyWithImpl<BuddyPhoneToolResultFindMyFoods>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolResultFindMyFoodsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolResultFindMyFoods&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,ok,error,data);
}

@override
String toString() {
    return 'BuddyPhoneToolResult.findMyFoods(name: $name, callId: $callId, ok: $ok, error: $error, data: $data)';
}


}

/// @nodoc
abstract mixin class $BuddyPhoneToolResultFindMyFoodsCopyWith<$Res> implements $BuddyPhoneToolResultCopyWith<$Res> {
  factory $BuddyPhoneToolResultFindMyFoodsCopyWith(BuddyPhoneToolResultFindMyFoods value, $Res Function(BuddyPhoneToolResultFindMyFoods) _then) = _$BuddyPhoneToolResultFindMyFoodsCopyWithImpl;
@useResult
$Res call({
 BuddyFindMyFoodsResultName name, String callId, bool ok, BuddyPhoneToolError? error, BuddyFindMyFoodsData? data
});


$BuddyFindMyFoodsDataCopyWith<$Res>? get data;

}
/// @nodoc
class _$BuddyPhoneToolResultFindMyFoodsCopyWithImpl<$Res>
    implements $BuddyPhoneToolResultFindMyFoodsCopyWith<$Res> {
  _$BuddyPhoneToolResultFindMyFoodsCopyWithImpl(this._self, this._then);

  final BuddyPhoneToolResultFindMyFoods _self;
  final $Res Function(BuddyPhoneToolResultFindMyFoods) _then;

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,Object? data = freezed,}) {
  return _then(BuddyPhoneToolResultFindMyFoods(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyFindMyFoodsResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BuddyFindMyFoodsData?,
  ));
}

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyFindMyFoodsDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $BuddyFindMyFoodsDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolResultReadDiary implements BuddyPhoneToolResult {
  const BuddyPhoneToolResultReadDiary({required this.name, required this.callId, required this.ok, required this.error, required this.data});
  factory BuddyPhoneToolResultReadDiary.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolResultReadDiaryFromJson(json);

 final  BuddyReadDiaryResultName name;
 final  String callId;
 final  bool ok;
 final  BuddyPhoneToolError? error;
 final  BuddyReadDiaryData? data;

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPhoneToolResultReadDiaryCopyWith<BuddyPhoneToolResultReadDiary> get copyWith => _$BuddyPhoneToolResultReadDiaryCopyWithImpl<BuddyPhoneToolResultReadDiary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolResultReadDiaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolResultReadDiary&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,ok,error,data);
}

@override
String toString() {
    return 'BuddyPhoneToolResult.readDiary(name: $name, callId: $callId, ok: $ok, error: $error, data: $data)';
}


}

/// @nodoc
abstract mixin class $BuddyPhoneToolResultReadDiaryCopyWith<$Res> implements $BuddyPhoneToolResultCopyWith<$Res> {
  factory $BuddyPhoneToolResultReadDiaryCopyWith(BuddyPhoneToolResultReadDiary value, $Res Function(BuddyPhoneToolResultReadDiary) _then) = _$BuddyPhoneToolResultReadDiaryCopyWithImpl;
@useResult
$Res call({
 BuddyReadDiaryResultName name, String callId, bool ok, BuddyPhoneToolError? error, BuddyReadDiaryData? data
});


$BuddyReadDiaryDataCopyWith<$Res>? get data;

}
/// @nodoc
class _$BuddyPhoneToolResultReadDiaryCopyWithImpl<$Res>
    implements $BuddyPhoneToolResultReadDiaryCopyWith<$Res> {
  _$BuddyPhoneToolResultReadDiaryCopyWithImpl(this._self, this._then);

  final BuddyPhoneToolResultReadDiary _self;
  final $Res Function(BuddyPhoneToolResultReadDiary) _then;

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,Object? data = freezed,}) {
  return _then(BuddyPhoneToolResultReadDiary(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadDiaryResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BuddyReadDiaryData?,
  ));
}

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadDiaryDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $BuddyReadDiaryDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolResultReadBody implements BuddyPhoneToolResult {
  const BuddyPhoneToolResultReadBody({required this.name, required this.callId, required this.ok, required this.error, required this.data});
  factory BuddyPhoneToolResultReadBody.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolResultReadBodyFromJson(json);

 final  BuddyReadBodyResultName name;
 final  String callId;
 final  bool ok;
 final  BuddyPhoneToolError? error;
 final  BuddyReadBodyData? data;

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPhoneToolResultReadBodyCopyWith<BuddyPhoneToolResultReadBody> get copyWith => _$BuddyPhoneToolResultReadBodyCopyWithImpl<BuddyPhoneToolResultReadBody>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolResultReadBodyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolResultReadBody&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,ok,error,data);
}

@override
String toString() {
    return 'BuddyPhoneToolResult.readBody(name: $name, callId: $callId, ok: $ok, error: $error, data: $data)';
}


}

/// @nodoc
abstract mixin class $BuddyPhoneToolResultReadBodyCopyWith<$Res> implements $BuddyPhoneToolResultCopyWith<$Res> {
  factory $BuddyPhoneToolResultReadBodyCopyWith(BuddyPhoneToolResultReadBody value, $Res Function(BuddyPhoneToolResultReadBody) _then) = _$BuddyPhoneToolResultReadBodyCopyWithImpl;
@useResult
$Res call({
 BuddyReadBodyResultName name, String callId, bool ok, BuddyPhoneToolError? error, BuddyReadBodyData? data
});


$BuddyReadBodyDataCopyWith<$Res>? get data;

}
/// @nodoc
class _$BuddyPhoneToolResultReadBodyCopyWithImpl<$Res>
    implements $BuddyPhoneToolResultReadBodyCopyWith<$Res> {
  _$BuddyPhoneToolResultReadBodyCopyWithImpl(this._self, this._then);

  final BuddyPhoneToolResultReadBody _self;
  final $Res Function(BuddyPhoneToolResultReadBody) _then;

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,Object? data = freezed,}) {
  return _then(BuddyPhoneToolResultReadBody(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadBodyResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BuddyReadBodyData?,
  ));
}

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadBodyDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $BuddyReadBodyDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolResultReadWorkouts implements BuddyPhoneToolResult {
  const BuddyPhoneToolResultReadWorkouts({required this.name, required this.callId, required this.ok, required this.error, required this.data});
  factory BuddyPhoneToolResultReadWorkouts.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolResultReadWorkoutsFromJson(json);

 final  BuddyReadWorkoutsResultName name;
 final  String callId;
 final  bool ok;
 final  BuddyPhoneToolError? error;
 final  BuddyReadWorkoutsData? data;

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPhoneToolResultReadWorkoutsCopyWith<BuddyPhoneToolResultReadWorkouts> get copyWith => _$BuddyPhoneToolResultReadWorkoutsCopyWithImpl<BuddyPhoneToolResultReadWorkouts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolResultReadWorkoutsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolResultReadWorkouts&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,ok,error,data);
}

@override
String toString() {
    return 'BuddyPhoneToolResult.readWorkouts(name: $name, callId: $callId, ok: $ok, error: $error, data: $data)';
}


}

/// @nodoc
abstract mixin class $BuddyPhoneToolResultReadWorkoutsCopyWith<$Res> implements $BuddyPhoneToolResultCopyWith<$Res> {
  factory $BuddyPhoneToolResultReadWorkoutsCopyWith(BuddyPhoneToolResultReadWorkouts value, $Res Function(BuddyPhoneToolResultReadWorkouts) _then) = _$BuddyPhoneToolResultReadWorkoutsCopyWithImpl;
@useResult
$Res call({
 BuddyReadWorkoutsResultName name, String callId, bool ok, BuddyPhoneToolError? error, BuddyReadWorkoutsData? data
});


$BuddyReadWorkoutsDataCopyWith<$Res>? get data;

}
/// @nodoc
class _$BuddyPhoneToolResultReadWorkoutsCopyWithImpl<$Res>
    implements $BuddyPhoneToolResultReadWorkoutsCopyWith<$Res> {
  _$BuddyPhoneToolResultReadWorkoutsCopyWithImpl(this._self, this._then);

  final BuddyPhoneToolResultReadWorkouts _self;
  final $Res Function(BuddyPhoneToolResultReadWorkouts) _then;

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,Object? data = freezed,}) {
  return _then(BuddyPhoneToolResultReadWorkouts(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadWorkoutsResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BuddyReadWorkoutsData?,
  ));
}

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadWorkoutsDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $BuddyReadWorkoutsDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolResultReadMemory implements BuddyPhoneToolResult {
  const BuddyPhoneToolResultReadMemory({required this.name, required this.callId, required this.ok, required this.error, required this.data});
  factory BuddyPhoneToolResultReadMemory.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolResultReadMemoryFromJson(json);

 final  BuddyReadMemoryResultName name;
 final  String callId;
 final  bool ok;
 final  BuddyPhoneToolError? error;
 final  BuddyReadMemoryData? data;

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPhoneToolResultReadMemoryCopyWith<BuddyPhoneToolResultReadMemory> get copyWith => _$BuddyPhoneToolResultReadMemoryCopyWithImpl<BuddyPhoneToolResultReadMemory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolResultReadMemoryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolResultReadMemory&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,ok,error,data);
}

@override
String toString() {
    return 'BuddyPhoneToolResult.readMemory(name: $name, callId: $callId, ok: $ok, error: $error, data: $data)';
}


}

/// @nodoc
abstract mixin class $BuddyPhoneToolResultReadMemoryCopyWith<$Res> implements $BuddyPhoneToolResultCopyWith<$Res> {
  factory $BuddyPhoneToolResultReadMemoryCopyWith(BuddyPhoneToolResultReadMemory value, $Res Function(BuddyPhoneToolResultReadMemory) _then) = _$BuddyPhoneToolResultReadMemoryCopyWithImpl;
@useResult
$Res call({
 BuddyReadMemoryResultName name, String callId, bool ok, BuddyPhoneToolError? error, BuddyReadMemoryData? data
});


$BuddyReadMemoryDataCopyWith<$Res>? get data;

}
/// @nodoc
class _$BuddyPhoneToolResultReadMemoryCopyWithImpl<$Res>
    implements $BuddyPhoneToolResultReadMemoryCopyWith<$Res> {
  _$BuddyPhoneToolResultReadMemoryCopyWithImpl(this._self, this._then);

  final BuddyPhoneToolResultReadMemory _self;
  final $Res Function(BuddyPhoneToolResultReadMemory) _then;

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,Object? data = freezed,}) {
  return _then(BuddyPhoneToolResultReadMemory(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadMemoryResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BuddyReadMemoryData?,
  ));
}

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadMemoryDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $BuddyReadMemoryDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolResultQueryData implements BuddyPhoneToolResult {
  const BuddyPhoneToolResultQueryData({required this.name, required this.callId, required this.ok, required this.error, required this.data});
  factory BuddyPhoneToolResultQueryData.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolResultQueryDataFromJson(json);

 final  BuddyQueryDataResultName name;
 final  String callId;
 final  bool ok;
 final  BuddyPhoneToolError? error;
 final  BuddyQueryResultData? data;

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPhoneToolResultQueryDataCopyWith<BuddyPhoneToolResultQueryData> get copyWith => _$BuddyPhoneToolResultQueryDataCopyWithImpl<BuddyPhoneToolResultQueryData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolResultQueryDataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolResultQueryData&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,ok,error,data);
}

@override
String toString() {
    return 'BuddyPhoneToolResult.queryData(name: $name, callId: $callId, ok: $ok, error: $error, data: $data)';
}


}

/// @nodoc
abstract mixin class $BuddyPhoneToolResultQueryDataCopyWith<$Res> implements $BuddyPhoneToolResultCopyWith<$Res> {
  factory $BuddyPhoneToolResultQueryDataCopyWith(BuddyPhoneToolResultQueryData value, $Res Function(BuddyPhoneToolResultQueryData) _then) = _$BuddyPhoneToolResultQueryDataCopyWithImpl;
@useResult
$Res call({
 BuddyQueryDataResultName name, String callId, bool ok, BuddyPhoneToolError? error, BuddyQueryResultData? data
});


$BuddyQueryResultDataCopyWith<$Res>? get data;

}
/// @nodoc
class _$BuddyPhoneToolResultQueryDataCopyWithImpl<$Res>
    implements $BuddyPhoneToolResultQueryDataCopyWith<$Res> {
  _$BuddyPhoneToolResultQueryDataCopyWithImpl(this._self, this._then);

  final BuddyPhoneToolResultQueryData _self;
  final $Res Function(BuddyPhoneToolResultQueryData) _then;

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,Object? data = freezed,}) {
  return _then(BuddyPhoneToolResultQueryData(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyQueryDataResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BuddyQueryResultData?,
  ));
}

/// Create a copy of BuddyPhoneToolResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyQueryResultDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $BuddyQueryResultDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolResultUnrecognized implements BuddyPhoneToolResult {
  const BuddyPhoneToolResultUnrecognized({ String? $type}): $type = $type ?? 'unrecognized';
  factory BuddyPhoneToolResultUnrecognized.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolResultUnrecognizedFromJson(json);



@JsonKey(name: 'name')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolResultUnrecognizedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolResultUnrecognized);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BuddyPhoneToolResult.unrecognized()';
}


}




// dart format on
