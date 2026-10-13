// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'intent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
Intent _$IntentFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'logFood':
          return IntentLogFood.fromJson(
            json
          );
                case 'askQuestion':
          return IntentAskQuestion.fromJson(
            json
          );
                case 'unknown':
          return IntentUnknown.fromJson(
            json
          );
        
          default:
            return IntentUnrecognized.fromJson(
  json
);
        }
      
}

/// @nodoc
mixin _$Intent {



  /// Serializes this Intent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Intent);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Intent()';
}


}

/// @nodoc
class $IntentCopyWith<$Res>  {
$IntentCopyWith(Intent _, $Res Function(Intent) __);
}


/// Adds pattern-matching-related methods to [Intent].
extension IntentPatterns on Intent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( IntentLogFood value)?  logFood,TResult Function( IntentAskQuestion value)?  askQuestion,TResult Function( IntentUnknown value)?  unknown,TResult Function( IntentUnrecognized value)?  unrecognized,required TResult orElse(),}){
final _that = this;
switch (_that) {
case IntentLogFood() when logFood != null:
return logFood(_that);case IntentAskQuestion() when askQuestion != null:
return askQuestion(_that);case IntentUnknown() when unknown != null:
return unknown(_that);case IntentUnrecognized() when unrecognized != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( IntentLogFood value)  logFood,required TResult Function( IntentAskQuestion value)  askQuestion,required TResult Function( IntentUnknown value)  unknown,required TResult Function( IntentUnrecognized value)  unrecognized,}){
final _that = this;
switch (_that) {
case IntentLogFood():
return logFood(_that);case IntentAskQuestion():
return askQuestion(_that);case IntentUnknown():
return unknown(_that);case IntentUnrecognized():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( IntentLogFood value)?  logFood,TResult? Function( IntentAskQuestion value)?  askQuestion,TResult? Function( IntentUnknown value)?  unknown,TResult? Function( IntentUnrecognized value)?  unrecognized,}){
final _that = this;
switch (_that) {
case IntentLogFood() when logFood != null:
return logFood(_that);case IntentAskQuestion() when askQuestion != null:
return askQuestion(_that);case IntentUnknown() when unknown != null:
return unknown(_that);case IntentUnrecognized() when unrecognized != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String kind,  List<FoodItem> items,  Instant eatenAt,  LocalDate? date)?  logFood,TResult Function( String kind,  String question,  String? topic)?  askQuestion,TResult Function( String kind,  String? reason)?  unknown,TResult Function()?  unrecognized,required TResult orElse(),}) {final _that = this;
switch (_that) {
case IntentLogFood() when logFood != null:
return logFood(_that.kind,_that.items,_that.eatenAt,_that.date);case IntentAskQuestion() when askQuestion != null:
return askQuestion(_that.kind,_that.question,_that.topic);case IntentUnknown() when unknown != null:
return unknown(_that.kind,_that.reason);case IntentUnrecognized() when unrecognized != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String kind,  List<FoodItem> items,  Instant eatenAt,  LocalDate? date)  logFood,required TResult Function( String kind,  String question,  String? topic)  askQuestion,required TResult Function( String kind,  String? reason)  unknown,required TResult Function()  unrecognized,}) {final _that = this;
switch (_that) {
case IntentLogFood():
return logFood(_that.kind,_that.items,_that.eatenAt,_that.date);case IntentAskQuestion():
return askQuestion(_that.kind,_that.question,_that.topic);case IntentUnknown():
return unknown(_that.kind,_that.reason);case IntentUnrecognized():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String kind,  List<FoodItem> items,  Instant eatenAt,  LocalDate? date)?  logFood,TResult? Function( String kind,  String question,  String? topic)?  askQuestion,TResult? Function( String kind,  String? reason)?  unknown,TResult? Function()?  unrecognized,}) {final _that = this;
switch (_that) {
case IntentLogFood() when logFood != null:
return logFood(_that.kind,_that.items,_that.eatenAt,_that.date);case IntentAskQuestion() when askQuestion != null:
return askQuestion(_that.kind,_that.question,_that.topic);case IntentUnknown() when unknown != null:
return unknown(_that.kind,_that.reason);case IntentUnrecognized() when unrecognized != null:
return unrecognized();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class IntentLogFood implements Intent {
  const IntentLogFood({required this.kind, required  List<FoodItem> items, required this.eatenAt, required this.date}): _items = items;
  factory IntentLogFood.fromJson(Map<String, dynamic> json) => _$IntentLogFoodFromJson(json);

 final  String kind;
 final  List<FoodItem> _items;
 List<FoodItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  Instant eatenAt;
 final  LocalDate? date;

/// Create a copy of Intent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntentLogFoodCopyWith<IntentLogFood> get copyWith => _$IntentLogFoodCopyWithImpl<IntentLogFood>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IntentLogFoodToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IntentLogFood&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.eatenAt, eatenAt) || other.eatenAt == eatenAt)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(_items),eatenAt,date);
}

@override
String toString() {
    return 'Intent.logFood(kind: $kind, items: $items, eatenAt: $eatenAt, date: $date)';
}


}

/// @nodoc
abstract mixin class $IntentLogFoodCopyWith<$Res> implements $IntentCopyWith<$Res> {
  factory $IntentLogFoodCopyWith(IntentLogFood value, $Res Function(IntentLogFood) _then) = _$IntentLogFoodCopyWithImpl;
@useResult
$Res call({
 String kind, List<FoodItem> items, Instant eatenAt, LocalDate? date
});




}
/// @nodoc
class _$IntentLogFoodCopyWithImpl<$Res>
    implements $IntentLogFoodCopyWith<$Res> {
  _$IntentLogFoodCopyWithImpl(this._self, this._then);

  final IntentLogFood _self;
  final $Res Function(IntentLogFood) _then;

/// Create a copy of Intent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? items = null,Object? eatenAt = null,Object? date = freezed,}) {
  return _then(IntentLogFood(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<FoodItem>,eatenAt: null == eatenAt ? _self.eatenAt : eatenAt // ignore: cast_nullable_to_non_nullable
as Instant,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class IntentAskQuestion implements Intent {
  const IntentAskQuestion({required this.kind, required this.question, required this.topic});
  factory IntentAskQuestion.fromJson(Map<String, dynamic> json) => _$IntentAskQuestionFromJson(json);

 final  String kind;
 final  String question;
 final  String? topic;

/// Create a copy of Intent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntentAskQuestionCopyWith<IntentAskQuestion> get copyWith => _$IntentAskQuestionCopyWithImpl<IntentAskQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IntentAskQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IntentAskQuestion&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.question, question) || other.question == question)&&(identical(other.topic, topic) || other.topic == topic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,question,topic);
}

@override
String toString() {
    return 'Intent.askQuestion(kind: $kind, question: $question, topic: $topic)';
}


}

/// @nodoc
abstract mixin class $IntentAskQuestionCopyWith<$Res> implements $IntentCopyWith<$Res> {
  factory $IntentAskQuestionCopyWith(IntentAskQuestion value, $Res Function(IntentAskQuestion) _then) = _$IntentAskQuestionCopyWithImpl;
@useResult
$Res call({
 String kind, String question, String? topic
});




}
/// @nodoc
class _$IntentAskQuestionCopyWithImpl<$Res>
    implements $IntentAskQuestionCopyWith<$Res> {
  _$IntentAskQuestionCopyWithImpl(this._self, this._then);

  final IntentAskQuestion _self;
  final $Res Function(IntentAskQuestion) _then;

/// Create a copy of Intent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? question = null,Object? topic = freezed,}) {
  return _then(IntentAskQuestion(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class IntentUnknown implements Intent {
  const IntentUnknown({required this.kind, required this.reason});
  factory IntentUnknown.fromJson(Map<String, dynamic> json) => _$IntentUnknownFromJson(json);

 final  String kind;
 final  String? reason;

/// Create a copy of Intent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntentUnknownCopyWith<IntentUnknown> get copyWith => _$IntentUnknownCopyWithImpl<IntentUnknown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IntentUnknownToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IntentUnknown&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,reason);
}

@override
String toString() {
    return 'Intent.unknown(kind: $kind, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $IntentUnknownCopyWith<$Res> implements $IntentCopyWith<$Res> {
  factory $IntentUnknownCopyWith(IntentUnknown value, $Res Function(IntentUnknown) _then) = _$IntentUnknownCopyWithImpl;
@useResult
$Res call({
 String kind, String? reason
});




}
/// @nodoc
class _$IntentUnknownCopyWithImpl<$Res>
    implements $IntentUnknownCopyWith<$Res> {
  _$IntentUnknownCopyWithImpl(this._self, this._then);

  final IntentUnknown _self;
  final $Res Function(IntentUnknown) _then;

/// Create a copy of Intent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? reason = freezed,}) {
  return _then(IntentUnknown(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class IntentUnrecognized implements Intent {
  const IntentUnrecognized({ String? $type}): $type = $type ?? 'unrecognized';
  factory IntentUnrecognized.fromJson(Map<String, dynamic> json) => _$IntentUnrecognizedFromJson(json);



@JsonKey(name: 'kind')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$IntentUnrecognizedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IntentUnrecognized);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Intent.unrecognized()';
}


}




// dart format on
