// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_phone_tool_call.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
BuddyPhoneToolCall _$BuddyPhoneToolCallFromJson(
  Map<String, dynamic> json
) {
        switch (json['name']) {
                  case 'findMyFoods':
          return BuddyPhoneToolCallFindMyFoods.fromJson(
            json
          );
                case 'readDiary':
          return BuddyPhoneToolCallReadDiary.fromJson(
            json
          );
                case 'readBody':
          return BuddyPhoneToolCallReadBody.fromJson(
            json
          );
                case 'readWorkouts':
          return BuddyPhoneToolCallReadWorkouts.fromJson(
            json
          );
                case 'readMemory':
          return BuddyPhoneToolCallReadMemory.fromJson(
            json
          );
                case 'queryData':
          return BuddyPhoneToolCallQueryData.fromJson(
            json
          );
        
          default:
            return BuddyPhoneToolCallUnrecognized.fromJson(
  json
);
        }
      
}

/// @nodoc
mixin _$BuddyPhoneToolCall {



  /// Serializes this BuddyPhoneToolCall to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolCall);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BuddyPhoneToolCall()';
}


}

/// @nodoc
class $BuddyPhoneToolCallCopyWith<$Res>  {
$BuddyPhoneToolCallCopyWith(BuddyPhoneToolCall _, $Res Function(BuddyPhoneToolCall) __);
}


/// Adds pattern-matching-related methods to [BuddyPhoneToolCall].
extension BuddyPhoneToolCallPatterns on BuddyPhoneToolCall {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BuddyPhoneToolCallFindMyFoods value)?  findMyFoods,TResult Function( BuddyPhoneToolCallReadDiary value)?  readDiary,TResult Function( BuddyPhoneToolCallReadBody value)?  readBody,TResult Function( BuddyPhoneToolCallReadWorkouts value)?  readWorkouts,TResult Function( BuddyPhoneToolCallReadMemory value)?  readMemory,TResult Function( BuddyPhoneToolCallQueryData value)?  queryData,TResult Function( BuddyPhoneToolCallUnrecognized value)?  unrecognized,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BuddyPhoneToolCallFindMyFoods() when findMyFoods != null:
return findMyFoods(_that);case BuddyPhoneToolCallReadDiary() when readDiary != null:
return readDiary(_that);case BuddyPhoneToolCallReadBody() when readBody != null:
return readBody(_that);case BuddyPhoneToolCallReadWorkouts() when readWorkouts != null:
return readWorkouts(_that);case BuddyPhoneToolCallReadMemory() when readMemory != null:
return readMemory(_that);case BuddyPhoneToolCallQueryData() when queryData != null:
return queryData(_that);case BuddyPhoneToolCallUnrecognized() when unrecognized != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BuddyPhoneToolCallFindMyFoods value)  findMyFoods,required TResult Function( BuddyPhoneToolCallReadDiary value)  readDiary,required TResult Function( BuddyPhoneToolCallReadBody value)  readBody,required TResult Function( BuddyPhoneToolCallReadWorkouts value)  readWorkouts,required TResult Function( BuddyPhoneToolCallReadMemory value)  readMemory,required TResult Function( BuddyPhoneToolCallQueryData value)  queryData,required TResult Function( BuddyPhoneToolCallUnrecognized value)  unrecognized,}){
final _that = this;
switch (_that) {
case BuddyPhoneToolCallFindMyFoods():
return findMyFoods(_that);case BuddyPhoneToolCallReadDiary():
return readDiary(_that);case BuddyPhoneToolCallReadBody():
return readBody(_that);case BuddyPhoneToolCallReadWorkouts():
return readWorkouts(_that);case BuddyPhoneToolCallReadMemory():
return readMemory(_that);case BuddyPhoneToolCallQueryData():
return queryData(_that);case BuddyPhoneToolCallUnrecognized():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BuddyPhoneToolCallFindMyFoods value)?  findMyFoods,TResult? Function( BuddyPhoneToolCallReadDiary value)?  readDiary,TResult? Function( BuddyPhoneToolCallReadBody value)?  readBody,TResult? Function( BuddyPhoneToolCallReadWorkouts value)?  readWorkouts,TResult? Function( BuddyPhoneToolCallReadMemory value)?  readMemory,TResult? Function( BuddyPhoneToolCallQueryData value)?  queryData,TResult? Function( BuddyPhoneToolCallUnrecognized value)?  unrecognized,}){
final _that = this;
switch (_that) {
case BuddyPhoneToolCallFindMyFoods() when findMyFoods != null:
return findMyFoods(_that);case BuddyPhoneToolCallReadDiary() when readDiary != null:
return readDiary(_that);case BuddyPhoneToolCallReadBody() when readBody != null:
return readBody(_that);case BuddyPhoneToolCallReadWorkouts() when readWorkouts != null:
return readWorkouts(_that);case BuddyPhoneToolCallReadMemory() when readMemory != null:
return readMemory(_that);case BuddyPhoneToolCallQueryData() when queryData != null:
return queryData(_that);case BuddyPhoneToolCallUnrecognized() when unrecognized != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( BuddyFindMyFoodsCallName name,  String callId,  BuddyFindMyFoodsArgs args)?  findMyFoods,TResult Function( BuddyReadDiaryCallName name,  String callId,  BuddyReadDiaryArgs args)?  readDiary,TResult Function( BuddyReadBodyCallName name,  String callId,  BuddyReadBodyArgs args)?  readBody,TResult Function( BuddyReadWorkoutsCallName name,  String callId,  BuddyReadWorkoutsArgs args)?  readWorkouts,TResult Function( BuddyReadMemoryCallName name,  String callId,  BuddyReadMemoryArgs args)?  readMemory,TResult Function( BuddyQueryDataCallName name,  String callId,  BuddyQueryPlan args)?  queryData,TResult Function()?  unrecognized,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BuddyPhoneToolCallFindMyFoods() when findMyFoods != null:
return findMyFoods(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallReadDiary() when readDiary != null:
return readDiary(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallReadBody() when readBody != null:
return readBody(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallReadWorkouts() when readWorkouts != null:
return readWorkouts(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallReadMemory() when readMemory != null:
return readMemory(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallQueryData() when queryData != null:
return queryData(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallUnrecognized() when unrecognized != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( BuddyFindMyFoodsCallName name,  String callId,  BuddyFindMyFoodsArgs args)  findMyFoods,required TResult Function( BuddyReadDiaryCallName name,  String callId,  BuddyReadDiaryArgs args)  readDiary,required TResult Function( BuddyReadBodyCallName name,  String callId,  BuddyReadBodyArgs args)  readBody,required TResult Function( BuddyReadWorkoutsCallName name,  String callId,  BuddyReadWorkoutsArgs args)  readWorkouts,required TResult Function( BuddyReadMemoryCallName name,  String callId,  BuddyReadMemoryArgs args)  readMemory,required TResult Function( BuddyQueryDataCallName name,  String callId,  BuddyQueryPlan args)  queryData,required TResult Function()  unrecognized,}) {final _that = this;
switch (_that) {
case BuddyPhoneToolCallFindMyFoods():
return findMyFoods(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallReadDiary():
return readDiary(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallReadBody():
return readBody(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallReadWorkouts():
return readWorkouts(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallReadMemory():
return readMemory(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallQueryData():
return queryData(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallUnrecognized():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( BuddyFindMyFoodsCallName name,  String callId,  BuddyFindMyFoodsArgs args)?  findMyFoods,TResult? Function( BuddyReadDiaryCallName name,  String callId,  BuddyReadDiaryArgs args)?  readDiary,TResult? Function( BuddyReadBodyCallName name,  String callId,  BuddyReadBodyArgs args)?  readBody,TResult? Function( BuddyReadWorkoutsCallName name,  String callId,  BuddyReadWorkoutsArgs args)?  readWorkouts,TResult? Function( BuddyReadMemoryCallName name,  String callId,  BuddyReadMemoryArgs args)?  readMemory,TResult? Function( BuddyQueryDataCallName name,  String callId,  BuddyQueryPlan args)?  queryData,TResult? Function()?  unrecognized,}) {final _that = this;
switch (_that) {
case BuddyPhoneToolCallFindMyFoods() when findMyFoods != null:
return findMyFoods(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallReadDiary() when readDiary != null:
return readDiary(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallReadBody() when readBody != null:
return readBody(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallReadWorkouts() when readWorkouts != null:
return readWorkouts(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallReadMemory() when readMemory != null:
return readMemory(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallQueryData() when queryData != null:
return queryData(_that.name,_that.callId,_that.args);case BuddyPhoneToolCallUnrecognized() when unrecognized != null:
return unrecognized();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolCallFindMyFoods implements BuddyPhoneToolCall {
  const BuddyPhoneToolCallFindMyFoods({required this.name, required this.callId, required this.args});
  factory BuddyPhoneToolCallFindMyFoods.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolCallFindMyFoodsFromJson(json);

 final  BuddyFindMyFoodsCallName name;
 final  String callId;
 final  BuddyFindMyFoodsArgs args;

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPhoneToolCallFindMyFoodsCopyWith<BuddyPhoneToolCallFindMyFoods> get copyWith => _$BuddyPhoneToolCallFindMyFoodsCopyWithImpl<BuddyPhoneToolCallFindMyFoods>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolCallFindMyFoodsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolCallFindMyFoods&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.args, args) || other.args == args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,args);
}

@override
String toString() {
    return 'BuddyPhoneToolCall.findMyFoods(name: $name, callId: $callId, args: $args)';
}


}

/// @nodoc
abstract mixin class $BuddyPhoneToolCallFindMyFoodsCopyWith<$Res> implements $BuddyPhoneToolCallCopyWith<$Res> {
  factory $BuddyPhoneToolCallFindMyFoodsCopyWith(BuddyPhoneToolCallFindMyFoods value, $Res Function(BuddyPhoneToolCallFindMyFoods) _then) = _$BuddyPhoneToolCallFindMyFoodsCopyWithImpl;
@useResult
$Res call({
 BuddyFindMyFoodsCallName name, String callId, BuddyFindMyFoodsArgs args
});


$BuddyFindMyFoodsArgsCopyWith<$Res> get args;

}
/// @nodoc
class _$BuddyPhoneToolCallFindMyFoodsCopyWithImpl<$Res>
    implements $BuddyPhoneToolCallFindMyFoodsCopyWith<$Res> {
  _$BuddyPhoneToolCallFindMyFoodsCopyWithImpl(this._self, this._then);

  final BuddyPhoneToolCallFindMyFoods _self;
  final $Res Function(BuddyPhoneToolCallFindMyFoods) _then;

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(BuddyPhoneToolCallFindMyFoods(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyFindMyFoodsCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyFindMyFoodsArgs,
  ));
}

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyFindMyFoodsArgsCopyWith<$Res> get args {
  
  return $BuddyFindMyFoodsArgsCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolCallReadDiary implements BuddyPhoneToolCall {
  const BuddyPhoneToolCallReadDiary({required this.name, required this.callId, required this.args});
  factory BuddyPhoneToolCallReadDiary.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolCallReadDiaryFromJson(json);

 final  BuddyReadDiaryCallName name;
 final  String callId;
 final  BuddyReadDiaryArgs args;

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPhoneToolCallReadDiaryCopyWith<BuddyPhoneToolCallReadDiary> get copyWith => _$BuddyPhoneToolCallReadDiaryCopyWithImpl<BuddyPhoneToolCallReadDiary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolCallReadDiaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolCallReadDiary&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.args, args) || other.args == args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,args);
}

@override
String toString() {
    return 'BuddyPhoneToolCall.readDiary(name: $name, callId: $callId, args: $args)';
}


}

/// @nodoc
abstract mixin class $BuddyPhoneToolCallReadDiaryCopyWith<$Res> implements $BuddyPhoneToolCallCopyWith<$Res> {
  factory $BuddyPhoneToolCallReadDiaryCopyWith(BuddyPhoneToolCallReadDiary value, $Res Function(BuddyPhoneToolCallReadDiary) _then) = _$BuddyPhoneToolCallReadDiaryCopyWithImpl;
@useResult
$Res call({
 BuddyReadDiaryCallName name, String callId, BuddyReadDiaryArgs args
});


$BuddyReadDiaryArgsCopyWith<$Res> get args;

}
/// @nodoc
class _$BuddyPhoneToolCallReadDiaryCopyWithImpl<$Res>
    implements $BuddyPhoneToolCallReadDiaryCopyWith<$Res> {
  _$BuddyPhoneToolCallReadDiaryCopyWithImpl(this._self, this._then);

  final BuddyPhoneToolCallReadDiary _self;
  final $Res Function(BuddyPhoneToolCallReadDiary) _then;

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(BuddyPhoneToolCallReadDiary(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadDiaryCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyReadDiaryArgs,
  ));
}

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadDiaryArgsCopyWith<$Res> get args {
  
  return $BuddyReadDiaryArgsCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolCallReadBody implements BuddyPhoneToolCall {
  const BuddyPhoneToolCallReadBody({required this.name, required this.callId, required this.args});
  factory BuddyPhoneToolCallReadBody.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolCallReadBodyFromJson(json);

 final  BuddyReadBodyCallName name;
 final  String callId;
 final  BuddyReadBodyArgs args;

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPhoneToolCallReadBodyCopyWith<BuddyPhoneToolCallReadBody> get copyWith => _$BuddyPhoneToolCallReadBodyCopyWithImpl<BuddyPhoneToolCallReadBody>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolCallReadBodyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolCallReadBody&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.args, args) || other.args == args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,args);
}

@override
String toString() {
    return 'BuddyPhoneToolCall.readBody(name: $name, callId: $callId, args: $args)';
}


}

/// @nodoc
abstract mixin class $BuddyPhoneToolCallReadBodyCopyWith<$Res> implements $BuddyPhoneToolCallCopyWith<$Res> {
  factory $BuddyPhoneToolCallReadBodyCopyWith(BuddyPhoneToolCallReadBody value, $Res Function(BuddyPhoneToolCallReadBody) _then) = _$BuddyPhoneToolCallReadBodyCopyWithImpl;
@useResult
$Res call({
 BuddyReadBodyCallName name, String callId, BuddyReadBodyArgs args
});


$BuddyReadBodyArgsCopyWith<$Res> get args;

}
/// @nodoc
class _$BuddyPhoneToolCallReadBodyCopyWithImpl<$Res>
    implements $BuddyPhoneToolCallReadBodyCopyWith<$Res> {
  _$BuddyPhoneToolCallReadBodyCopyWithImpl(this._self, this._then);

  final BuddyPhoneToolCallReadBody _self;
  final $Res Function(BuddyPhoneToolCallReadBody) _then;

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(BuddyPhoneToolCallReadBody(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadBodyCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyReadBodyArgs,
  ));
}

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadBodyArgsCopyWith<$Res> get args {
  
  return $BuddyReadBodyArgsCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolCallReadWorkouts implements BuddyPhoneToolCall {
  const BuddyPhoneToolCallReadWorkouts({required this.name, required this.callId, required this.args});
  factory BuddyPhoneToolCallReadWorkouts.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolCallReadWorkoutsFromJson(json);

 final  BuddyReadWorkoutsCallName name;
 final  String callId;
 final  BuddyReadWorkoutsArgs args;

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPhoneToolCallReadWorkoutsCopyWith<BuddyPhoneToolCallReadWorkouts> get copyWith => _$BuddyPhoneToolCallReadWorkoutsCopyWithImpl<BuddyPhoneToolCallReadWorkouts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolCallReadWorkoutsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolCallReadWorkouts&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.args, args) || other.args == args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,args);
}

@override
String toString() {
    return 'BuddyPhoneToolCall.readWorkouts(name: $name, callId: $callId, args: $args)';
}


}

/// @nodoc
abstract mixin class $BuddyPhoneToolCallReadWorkoutsCopyWith<$Res> implements $BuddyPhoneToolCallCopyWith<$Res> {
  factory $BuddyPhoneToolCallReadWorkoutsCopyWith(BuddyPhoneToolCallReadWorkouts value, $Res Function(BuddyPhoneToolCallReadWorkouts) _then) = _$BuddyPhoneToolCallReadWorkoutsCopyWithImpl;
@useResult
$Res call({
 BuddyReadWorkoutsCallName name, String callId, BuddyReadWorkoutsArgs args
});


$BuddyReadWorkoutsArgsCopyWith<$Res> get args;

}
/// @nodoc
class _$BuddyPhoneToolCallReadWorkoutsCopyWithImpl<$Res>
    implements $BuddyPhoneToolCallReadWorkoutsCopyWith<$Res> {
  _$BuddyPhoneToolCallReadWorkoutsCopyWithImpl(this._self, this._then);

  final BuddyPhoneToolCallReadWorkouts _self;
  final $Res Function(BuddyPhoneToolCallReadWorkouts) _then;

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(BuddyPhoneToolCallReadWorkouts(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadWorkoutsCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyReadWorkoutsArgs,
  ));
}

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadWorkoutsArgsCopyWith<$Res> get args {
  
  return $BuddyReadWorkoutsArgsCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolCallReadMemory implements BuddyPhoneToolCall {
  const BuddyPhoneToolCallReadMemory({required this.name, required this.callId, required this.args});
  factory BuddyPhoneToolCallReadMemory.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolCallReadMemoryFromJson(json);

 final  BuddyReadMemoryCallName name;
 final  String callId;
 final  BuddyReadMemoryArgs args;

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPhoneToolCallReadMemoryCopyWith<BuddyPhoneToolCallReadMemory> get copyWith => _$BuddyPhoneToolCallReadMemoryCopyWithImpl<BuddyPhoneToolCallReadMemory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolCallReadMemoryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolCallReadMemory&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.args, args) || other.args == args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,args);
}

@override
String toString() {
    return 'BuddyPhoneToolCall.readMemory(name: $name, callId: $callId, args: $args)';
}


}

/// @nodoc
abstract mixin class $BuddyPhoneToolCallReadMemoryCopyWith<$Res> implements $BuddyPhoneToolCallCopyWith<$Res> {
  factory $BuddyPhoneToolCallReadMemoryCopyWith(BuddyPhoneToolCallReadMemory value, $Res Function(BuddyPhoneToolCallReadMemory) _then) = _$BuddyPhoneToolCallReadMemoryCopyWithImpl;
@useResult
$Res call({
 BuddyReadMemoryCallName name, String callId, BuddyReadMemoryArgs args
});


$BuddyReadMemoryArgsCopyWith<$Res> get args;

}
/// @nodoc
class _$BuddyPhoneToolCallReadMemoryCopyWithImpl<$Res>
    implements $BuddyPhoneToolCallReadMemoryCopyWith<$Res> {
  _$BuddyPhoneToolCallReadMemoryCopyWithImpl(this._self, this._then);

  final BuddyPhoneToolCallReadMemory _self;
  final $Res Function(BuddyPhoneToolCallReadMemory) _then;

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(BuddyPhoneToolCallReadMemory(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadMemoryCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyReadMemoryArgs,
  ));
}

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadMemoryArgsCopyWith<$Res> get args {
  
  return $BuddyReadMemoryArgsCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolCallQueryData implements BuddyPhoneToolCall {
  const BuddyPhoneToolCallQueryData({required this.name, required this.callId, required this.args});
  factory BuddyPhoneToolCallQueryData.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolCallQueryDataFromJson(json);

 final  BuddyQueryDataCallName name;
 final  String callId;
 final  BuddyQueryPlan args;

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPhoneToolCallQueryDataCopyWith<BuddyPhoneToolCallQueryData> get copyWith => _$BuddyPhoneToolCallQueryDataCopyWithImpl<BuddyPhoneToolCallQueryData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolCallQueryDataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolCallQueryData&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.args, args) || other.args == args));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,args);
}

@override
String toString() {
    return 'BuddyPhoneToolCall.queryData(name: $name, callId: $callId, args: $args)';
}


}

/// @nodoc
abstract mixin class $BuddyPhoneToolCallQueryDataCopyWith<$Res> implements $BuddyPhoneToolCallCopyWith<$Res> {
  factory $BuddyPhoneToolCallQueryDataCopyWith(BuddyPhoneToolCallQueryData value, $Res Function(BuddyPhoneToolCallQueryData) _then) = _$BuddyPhoneToolCallQueryDataCopyWithImpl;
@useResult
$Res call({
 BuddyQueryDataCallName name, String callId, BuddyQueryPlan args
});


$BuddyQueryPlanCopyWith<$Res> get args;

}
/// @nodoc
class _$BuddyPhoneToolCallQueryDataCopyWithImpl<$Res>
    implements $BuddyPhoneToolCallQueryDataCopyWith<$Res> {
  _$BuddyPhoneToolCallQueryDataCopyWithImpl(this._self, this._then);

  final BuddyPhoneToolCallQueryData _self;
  final $Res Function(BuddyPhoneToolCallQueryData) _then;

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? args = null,}) {
  return _then(BuddyPhoneToolCallQueryData(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyQueryDataCallName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as BuddyQueryPlan,
  ));
}

/// Create a copy of BuddyPhoneToolCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyQueryPlanCopyWith<$Res> get args {
  
  return $BuddyQueryPlanCopyWith<$Res>(_self.args, (value) {
    return _then(_self.copyWith(args: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyPhoneToolCallUnrecognized implements BuddyPhoneToolCall {
  const BuddyPhoneToolCallUnrecognized({ String? $type}): $type = $type ?? 'unrecognized';
  factory BuddyPhoneToolCallUnrecognized.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolCallUnrecognizedFromJson(json);



@JsonKey(name: 'name')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolCallUnrecognizedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolCallUnrecognized);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BuddyPhoneToolCall.unrecognized()';
}


}




// dart format on
