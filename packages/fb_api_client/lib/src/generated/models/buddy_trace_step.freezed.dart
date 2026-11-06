// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_trace_step.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyTraceStep {

 String get tool; String get args; String get resultSummary; int get ms; int get tokens; double get usd;
/// Create a copy of BuddyTraceStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTraceStepCopyWith<BuddyTraceStep> get copyWith => _$BuddyTraceStepCopyWithImpl<BuddyTraceStep>(this as BuddyTraceStep, _$identity);

  /// Serializes this BuddyTraceStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyTraceStep;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTraceStep&&(identical(other.tool, _this.tool) || other.tool == _this.tool)&&(identical(other.args, _this.args) || other.args == _this.args)&&(identical(other.resultSummary, _this.resultSummary) || other.resultSummary == _this.resultSummary)&&(identical(other.ms, _this.ms) || other.ms == _this.ms)&&(identical(other.tokens, _this.tokens) || other.tokens == _this.tokens)&&(identical(other.usd, _this.usd) || other.usd == _this.usd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyTraceStep;
  return Object.hash(runtimeType,_this.tool,_this.args,_this.resultSummary,_this.ms,_this.tokens,_this.usd);
}

@override
String toString() {
  final _this = this as BuddyTraceStep;
  return 'BuddyTraceStep(tool: ${_this.tool}, args: ${_this.args}, resultSummary: ${_this.resultSummary}, ms: ${_this.ms}, tokens: ${_this.tokens}, usd: ${_this.usd})';
}


}

/// @nodoc
abstract mixin class $BuddyTraceStepCopyWith<$Res>  {
  factory $BuddyTraceStepCopyWith(BuddyTraceStep value, $Res Function(BuddyTraceStep) _then) = _$BuddyTraceStepCopyWithImpl;
@useResult
$Res call({
 String tool, String args, String resultSummary, int ms, int tokens, double usd
});




}
/// @nodoc
class _$BuddyTraceStepCopyWithImpl<$Res>
    implements $BuddyTraceStepCopyWith<$Res> {
  _$BuddyTraceStepCopyWithImpl(this._self, this._then);

  final BuddyTraceStep _self;
  final $Res Function(BuddyTraceStep) _then;

/// Create a copy of BuddyTraceStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tool = null,Object? args = null,Object? resultSummary = null,Object? ms = null,Object? tokens = null,Object? usd = null,}) {
  return _then(BuddyTraceStep(
tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as String,resultSummary: null == resultSummary ? _self.resultSummary : resultSummary // ignore: cast_nullable_to_non_nullable
as String,ms: null == ms ? _self.ms : ms // ignore: cast_nullable_to_non_nullable
as int,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as int,usd: null == usd ? _self.usd : usd // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyTraceStep].
extension BuddyTraceStepPatterns on BuddyTraceStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyTraceStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyTraceStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyTraceStep value)  $default,){
final _that = this;
switch (_that) {
case _BuddyTraceStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyTraceStep value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyTraceStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tool,  String args,  String resultSummary,  int ms,  int tokens,  double usd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyTraceStep() when $default != null:
return $default(_that.tool,_that.args,_that.resultSummary,_that.ms,_that.tokens,_that.usd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tool,  String args,  String resultSummary,  int ms,  int tokens,  double usd)  $default,) {final _that = this;
switch (_that) {
case _BuddyTraceStep():
return $default(_that.tool,_that.args,_that.resultSummary,_that.ms,_that.tokens,_that.usd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tool,  String args,  String resultSummary,  int ms,  int tokens,  double usd)?  $default,) {final _that = this;
switch (_that) {
case _BuddyTraceStep() when $default != null:
return $default(_that.tool,_that.args,_that.resultSummary,_that.ms,_that.tokens,_that.usd);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyTraceStep implements BuddyTraceStep {
  const _BuddyTraceStep({required this.tool, required this.args, required this.resultSummary, required this.ms, required this.tokens, required this.usd});
  factory _BuddyTraceStep.fromJson(Map<String, dynamic> json) => _$BuddyTraceStepFromJson(json);

@override final  String tool;
@override final  String args;
@override final  String resultSummary;
@override final  int ms;
@override final  int tokens;
@override final  double usd;

/// Create a copy of BuddyTraceStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyTraceStepCopyWith<_BuddyTraceStep> get copyWith => __$BuddyTraceStepCopyWithImpl<_BuddyTraceStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTraceStepToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyTraceStep&&(identical(other.tool, tool) || other.tool == tool)&&(identical(other.args, args) || other.args == args)&&(identical(other.resultSummary, resultSummary) || other.resultSummary == resultSummary)&&(identical(other.ms, ms) || other.ms == ms)&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.usd, usd) || other.usd == usd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,tool,args,resultSummary,ms,tokens,usd);
}

@override
String toString() {
    return 'BuddyTraceStep(tool: $tool, args: $args, resultSummary: $resultSummary, ms: $ms, tokens: $tokens, usd: $usd)';
}


}

/// @nodoc
abstract mixin class _$BuddyTraceStepCopyWith<$Res> implements $BuddyTraceStepCopyWith<$Res> {
  factory _$BuddyTraceStepCopyWith(_BuddyTraceStep value, $Res Function(_BuddyTraceStep) _then) = __$BuddyTraceStepCopyWithImpl;
@override @useResult
$Res call({
 String tool, String args, String resultSummary, int ms, int tokens, double usd
});




}
/// @nodoc
class __$BuddyTraceStepCopyWithImpl<$Res>
    implements _$BuddyTraceStepCopyWith<$Res> {
  __$BuddyTraceStepCopyWithImpl(this._self, this._then);

  final _BuddyTraceStep _self;
  final $Res Function(_BuddyTraceStep) _then;

/// Create a copy of BuddyTraceStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tool = null,Object? args = null,Object? resultSummary = null,Object? ms = null,Object? tokens = null,Object? usd = null,}) {
  return _then(_BuddyTraceStep(
tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as String,resultSummary: null == resultSummary ? _self.resultSummary : resultSummary // ignore: cast_nullable_to_non_nullable
as String,ms: null == ms ? _self.ms : ms // ignore: cast_nullable_to_non_nullable
as int,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as int,usd: null == usd ? _self.usd : usd // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
