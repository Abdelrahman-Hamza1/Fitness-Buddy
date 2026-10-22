// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'interpret_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InterpretRequest {

 String get requestId; String get text; DateTime get now; int get tzOffsetMin; BuddyRamadan get ramadan; List<BuddySlot> get slots; String? get activeProposal; BuddyContext get context;
/// Create a copy of InterpretRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InterpretRequestCopyWith<InterpretRequest> get copyWith => _$InterpretRequestCopyWithImpl<InterpretRequest>(this as InterpretRequest, _$identity);

  /// Serializes this InterpretRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InterpretRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InterpretRequest&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.now, _this.now) || other.now == _this.now)&&(identical(other.tzOffsetMin, _this.tzOffsetMin) || other.tzOffsetMin == _this.tzOffsetMin)&&(identical(other.ramadan, _this.ramadan) || other.ramadan == _this.ramadan)&&const DeepCollectionEquality().equals(other.slots, _this.slots)&&(identical(other.activeProposal, _this.activeProposal) || other.activeProposal == _this.activeProposal)&&(identical(other.context, _this.context) || other.context == _this.context));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InterpretRequest;
  return Object.hash(runtimeType,_this.requestId,_this.text,_this.now,_this.tzOffsetMin,_this.ramadan,const DeepCollectionEquality().hash(_this.slots),_this.activeProposal,_this.context);
}

@override
String toString() {
  final _this = this as InterpretRequest;
  return 'InterpretRequest(requestId: ${_this.requestId}, text: ${_this.text}, now: ${_this.now}, tzOffsetMin: ${_this.tzOffsetMin}, ramadan: ${_this.ramadan}, slots: ${_this.slots}, activeProposal: ${_this.activeProposal}, context: ${_this.context})';
}


}

/// @nodoc
abstract mixin class $InterpretRequestCopyWith<$Res>  {
  factory $InterpretRequestCopyWith(InterpretRequest value, $Res Function(InterpretRequest) _then) = _$InterpretRequestCopyWithImpl;
@useResult
$Res call({
 String requestId, String text, DateTime now, int tzOffsetMin, BuddyRamadan ramadan, List<BuddySlot> slots, String? activeProposal, BuddyContext context
});


$BuddyRamadanCopyWith<$Res> get ramadan;$BuddyContextCopyWith<$Res> get context;

}
/// @nodoc
class _$InterpretRequestCopyWithImpl<$Res>
    implements $InterpretRequestCopyWith<$Res> {
  _$InterpretRequestCopyWithImpl(this._self, this._then);

  final InterpretRequest _self;
  final $Res Function(InterpretRequest) _then;

/// Create a copy of InterpretRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? text = null,Object? now = null,Object? tzOffsetMin = null,Object? ramadan = null,Object? slots = null,Object? activeProposal = freezed,Object? context = null,}) {
  return _then(InterpretRequest(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,now: null == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as DateTime,tzOffsetMin: null == tzOffsetMin ? _self.tzOffsetMin : tzOffsetMin // ignore: cast_nullable_to_non_nullable
as int,ramadan: null == ramadan ? _self.ramadan : ramadan // ignore: cast_nullable_to_non_nullable
as BuddyRamadan,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as List<BuddySlot>,activeProposal: freezed == activeProposal ? _self.activeProposal : activeProposal // ignore: cast_nullable_to_non_nullable
as String?,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as BuddyContext,
  ));
}
/// Create a copy of InterpretRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyRamadanCopyWith<$Res> get ramadan {
  
  return $BuddyRamadanCopyWith<$Res>(_self.ramadan, (value) {
    return _then(_self.copyWith(ramadan: value));
  });
}/// Create a copy of InterpretRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyContextCopyWith<$Res> get context {
  
  return $BuddyContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}


/// Adds pattern-matching-related methods to [InterpretRequest].
extension InterpretRequestPatterns on InterpretRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InterpretRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InterpretRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InterpretRequest value)  $default,){
final _that = this;
switch (_that) {
case _InterpretRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InterpretRequest value)?  $default,){
final _that = this;
switch (_that) {
case _InterpretRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String requestId,  String text,  DateTime now,  int tzOffsetMin,  BuddyRamadan ramadan,  List<BuddySlot> slots,  String? activeProposal,  BuddyContext context)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InterpretRequest() when $default != null:
return $default(_that.requestId,_that.text,_that.now,_that.tzOffsetMin,_that.ramadan,_that.slots,_that.activeProposal,_that.context);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String requestId,  String text,  DateTime now,  int tzOffsetMin,  BuddyRamadan ramadan,  List<BuddySlot> slots,  String? activeProposal,  BuddyContext context)  $default,) {final _that = this;
switch (_that) {
case _InterpretRequest():
return $default(_that.requestId,_that.text,_that.now,_that.tzOffsetMin,_that.ramadan,_that.slots,_that.activeProposal,_that.context);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String requestId,  String text,  DateTime now,  int tzOffsetMin,  BuddyRamadan ramadan,  List<BuddySlot> slots,  String? activeProposal,  BuddyContext context)?  $default,) {final _that = this;
switch (_that) {
case _InterpretRequest() when $default != null:
return $default(_that.requestId,_that.text,_that.now,_that.tzOffsetMin,_that.ramadan,_that.slots,_that.activeProposal,_that.context);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InterpretRequest implements InterpretRequest {
  const _InterpretRequest({required this.requestId, required this.text, required this.now, required this.tzOffsetMin, required this.ramadan, required  List<BuddySlot> slots, required this.activeProposal, required this.context}): _slots = slots;
  factory _InterpretRequest.fromJson(Map<String, dynamic> json) => _$InterpretRequestFromJson(json);

@override final  String requestId;
@override final  String text;
@override final  DateTime now;
@override final  int tzOffsetMin;
@override final  BuddyRamadan ramadan;
 final  List<BuddySlot> _slots;
@override List<BuddySlot> get slots {
  if (_slots is EqualUnmodifiableListView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slots);
}

@override final  String? activeProposal;
@override final  BuddyContext context;

/// Create a copy of InterpretRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InterpretRequestCopyWith<_InterpretRequest> get copyWith => __$InterpretRequestCopyWithImpl<_InterpretRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InterpretRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InterpretRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.text, text) || other.text == text)&&(identical(other.now, now) || other.now == now)&&(identical(other.tzOffsetMin, tzOffsetMin) || other.tzOffsetMin == tzOffsetMin)&&(identical(other.ramadan, ramadan) || other.ramadan == ramadan)&&const DeepCollectionEquality().equals(other.slots, _slots)&&(identical(other.activeProposal, activeProposal) || other.activeProposal == activeProposal)&&(identical(other.context, context) || other.context == context));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,requestId,text,now,tzOffsetMin,ramadan,const DeepCollectionEquality().hash(_slots),activeProposal,context);
}

@override
String toString() {
    return 'InterpretRequest(requestId: $requestId, text: $text, now: $now, tzOffsetMin: $tzOffsetMin, ramadan: $ramadan, slots: $slots, activeProposal: $activeProposal, context: $context)';
}


}

/// @nodoc
abstract mixin class _$InterpretRequestCopyWith<$Res> implements $InterpretRequestCopyWith<$Res> {
  factory _$InterpretRequestCopyWith(_InterpretRequest value, $Res Function(_InterpretRequest) _then) = __$InterpretRequestCopyWithImpl;
@override @useResult
$Res call({
 String requestId, String text, DateTime now, int tzOffsetMin, BuddyRamadan ramadan, List<BuddySlot> slots, String? activeProposal, BuddyContext context
});


@override $BuddyRamadanCopyWith<$Res> get ramadan;@override $BuddyContextCopyWith<$Res> get context;

}
/// @nodoc
class __$InterpretRequestCopyWithImpl<$Res>
    implements _$InterpretRequestCopyWith<$Res> {
  __$InterpretRequestCopyWithImpl(this._self, this._then);

  final _InterpretRequest _self;
  final $Res Function(_InterpretRequest) _then;

/// Create a copy of InterpretRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? text = null,Object? now = null,Object? tzOffsetMin = null,Object? ramadan = null,Object? slots = null,Object? activeProposal = freezed,Object? context = null,}) {
  return _then(_InterpretRequest(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,now: null == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as DateTime,tzOffsetMin: null == tzOffsetMin ? _self.tzOffsetMin : tzOffsetMin // ignore: cast_nullable_to_non_nullable
as int,ramadan: null == ramadan ? _self.ramadan : ramadan // ignore: cast_nullable_to_non_nullable
as BuddyRamadan,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as List<BuddySlot>,activeProposal: freezed == activeProposal ? _self.activeProposal : activeProposal // ignore: cast_nullable_to_non_nullable
as String?,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as BuddyContext,
  ));
}

/// Create a copy of InterpretRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyRamadanCopyWith<$Res> get ramadan {
  
  return $BuddyRamadanCopyWith<$Res>(_self.ramadan, (value) {
    return _then(_self.copyWith(ramadan: value));
  });
}/// Create a copy of InterpretRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyContextCopyWith<$Res> get context {
  
  return $BuddyContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}

// dart format on
