// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_conversation_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyConversationSummary {

 String get text; int get revision;/// The last summarised chat message ID.
 String get watermark;
/// Create a copy of BuddyConversationSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyConversationSummaryCopyWith<BuddyConversationSummary> get copyWith => _$BuddyConversationSummaryCopyWithImpl<BuddyConversationSummary>(this as BuddyConversationSummary, _$identity);

  /// Serializes this BuddyConversationSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyConversationSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyConversationSummary&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&(identical(other.watermark, _this.watermark) || other.watermark == _this.watermark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyConversationSummary;
  return Object.hash(runtimeType,_this.text,_this.revision,_this.watermark);
}

@override
String toString() {
  final _this = this as BuddyConversationSummary;
  return 'BuddyConversationSummary(text: ${_this.text}, revision: ${_this.revision}, watermark: ${_this.watermark})';
}


}

/// @nodoc
abstract mixin class $BuddyConversationSummaryCopyWith<$Res>  {
  factory $BuddyConversationSummaryCopyWith(BuddyConversationSummary value, $Res Function(BuddyConversationSummary) _then) = _$BuddyConversationSummaryCopyWithImpl;
@useResult
$Res call({
 String text, int revision, String watermark
});




}
/// @nodoc
class _$BuddyConversationSummaryCopyWithImpl<$Res>
    implements $BuddyConversationSummaryCopyWith<$Res> {
  _$BuddyConversationSummaryCopyWithImpl(this._self, this._then);

  final BuddyConversationSummary _self;
  final $Res Function(BuddyConversationSummary) _then;

/// Create a copy of BuddyConversationSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? revision = null,Object? watermark = null,}) {
  return _then(BuddyConversationSummary(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,watermark: null == watermark ? _self.watermark : watermark // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyConversationSummary].
extension BuddyConversationSummaryPatterns on BuddyConversationSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyConversationSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyConversationSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyConversationSummary value)  $default,){
final _that = this;
switch (_that) {
case _BuddyConversationSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyConversationSummary value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyConversationSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  int revision,  String watermark)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyConversationSummary() when $default != null:
return $default(_that.text,_that.revision,_that.watermark);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  int revision,  String watermark)  $default,) {final _that = this;
switch (_that) {
case _BuddyConversationSummary():
return $default(_that.text,_that.revision,_that.watermark);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  int revision,  String watermark)?  $default,) {final _that = this;
switch (_that) {
case _BuddyConversationSummary() when $default != null:
return $default(_that.text,_that.revision,_that.watermark);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyConversationSummary implements BuddyConversationSummary {
  const _BuddyConversationSummary({required this.text, required this.revision, required this.watermark});
  factory _BuddyConversationSummary.fromJson(Map<String, dynamic> json) => _$BuddyConversationSummaryFromJson(json);

@override final  String text;
@override final  int revision;
/// The last summarised chat message ID.
@override final  String watermark;

/// Create a copy of BuddyConversationSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyConversationSummaryCopyWith<_BuddyConversationSummary> get copyWith => __$BuddyConversationSummaryCopyWithImpl<_BuddyConversationSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyConversationSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyConversationSummary&&(identical(other.text, text) || other.text == text)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.watermark, watermark) || other.watermark == watermark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text,revision,watermark);
}

@override
String toString() {
    return 'BuddyConversationSummary(text: $text, revision: $revision, watermark: $watermark)';
}


}

/// @nodoc
abstract mixin class _$BuddyConversationSummaryCopyWith<$Res> implements $BuddyConversationSummaryCopyWith<$Res> {
  factory _$BuddyConversationSummaryCopyWith(_BuddyConversationSummary value, $Res Function(_BuddyConversationSummary) _then) = __$BuddyConversationSummaryCopyWithImpl;
@override @useResult
$Res call({
 String text, int revision, String watermark
});




}
/// @nodoc
class __$BuddyConversationSummaryCopyWithImpl<$Res>
    implements _$BuddyConversationSummaryCopyWith<$Res> {
  __$BuddyConversationSummaryCopyWithImpl(this._self, this._then);

  final _BuddyConversationSummary _self;
  final $Res Function(_BuddyConversationSummary) _then;

/// Create a copy of BuddyConversationSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? revision = null,Object? watermark = null,}) {
  return _then(_BuddyConversationSummary(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,watermark: null == watermark ? _self.watermark : watermark // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
