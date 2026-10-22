// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_intent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
BuddyIntent _$BuddyIntentFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'foodLog':
          return BuddyIntentFoodLog.fromJson(
            json
          );
                case 'clarify':
          return BuddyIntentClarify.fromJson(
            json
          );
                case 'outOfScope':
          return BuddyIntentOutOfScope.fromJson(
            json
          );
                case 'medical':
          return BuddyIntentMedical.fromJson(
            json
          );
                case 'weighIn':
          return BuddyIntentWeighIn.fromJson(
            json
          );
        
          default:
            return BuddyIntentUnrecognized.fromJson(
  json
);
        }
      
}

/// @nodoc
mixin _$BuddyIntent {



  /// Serializes this BuddyIntent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntent);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BuddyIntent()';
}


}

/// @nodoc
class $BuddyIntentCopyWith<$Res>  {
$BuddyIntentCopyWith(BuddyIntent _, $Res Function(BuddyIntent) __);
}


/// Adds pattern-matching-related methods to [BuddyIntent].
extension BuddyIntentPatterns on BuddyIntent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BuddyIntentFoodLog value)?  foodLog,TResult Function( BuddyIntentClarify value)?  clarify,TResult Function( BuddyIntentOutOfScope value)?  outOfScope,TResult Function( BuddyIntentMedical value)?  medical,TResult Function( BuddyIntentWeighIn value)?  weighIn,TResult Function( BuddyIntentUnrecognized value)?  unrecognized,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BuddyIntentFoodLog() when foodLog != null:
return foodLog(_that);case BuddyIntentClarify() when clarify != null:
return clarify(_that);case BuddyIntentOutOfScope() when outOfScope != null:
return outOfScope(_that);case BuddyIntentMedical() when medical != null:
return medical(_that);case BuddyIntentWeighIn() when weighIn != null:
return weighIn(_that);case BuddyIntentUnrecognized() when unrecognized != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BuddyIntentFoodLog value)  foodLog,required TResult Function( BuddyIntentClarify value)  clarify,required TResult Function( BuddyIntentOutOfScope value)  outOfScope,required TResult Function( BuddyIntentMedical value)  medical,required TResult Function( BuddyIntentWeighIn value)  weighIn,required TResult Function( BuddyIntentUnrecognized value)  unrecognized,}){
final _that = this;
switch (_that) {
case BuddyIntentFoodLog():
return foodLog(_that);case BuddyIntentClarify():
return clarify(_that);case BuddyIntentOutOfScope():
return outOfScope(_that);case BuddyIntentMedical():
return medical(_that);case BuddyIntentWeighIn():
return weighIn(_that);case BuddyIntentUnrecognized():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BuddyIntentFoodLog value)?  foodLog,TResult? Function( BuddyIntentClarify value)?  clarify,TResult? Function( BuddyIntentOutOfScope value)?  outOfScope,TResult? Function( BuddyIntentMedical value)?  medical,TResult? Function( BuddyIntentWeighIn value)?  weighIn,TResult? Function( BuddyIntentUnrecognized value)?  unrecognized,}){
final _that = this;
switch (_that) {
case BuddyIntentFoodLog() when foodLog != null:
return foodLog(_that);case BuddyIntentClarify() when clarify != null:
return clarify(_that);case BuddyIntentOutOfScope() when outOfScope != null:
return outOfScope(_that);case BuddyIntentMedical() when medical != null:
return medical(_that);case BuddyIntentWeighIn() when weighIn != null:
return weighIn(_that);case BuddyIntentUnrecognized() when unrecognized != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( BuddyFoodLogKind kind,  String language,  String script,  String? timeHint,  String? slotHint,  String? dishGroup,  List<BuddyFoodItem> items)?  foodLog,TResult Function( BuddyClarifyKind kind,  String language,  String script,  String reason)?  clarify,TResult Function( BuddyOutOfScopeKind kind,  String language,  String script,  String reason)?  outOfScope,TResult Function( BuddyMedicalKind kind,  String language,  String script)?  medical,TResult Function( BuddyWeighInKind kind,  String language,  String script,  double value,  String unit,  String? timeHint)?  weighIn,TResult Function()?  unrecognized,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BuddyIntentFoodLog() when foodLog != null:
return foodLog(_that.kind,_that.language,_that.script,_that.timeHint,_that.slotHint,_that.dishGroup,_that.items);case BuddyIntentClarify() when clarify != null:
return clarify(_that.kind,_that.language,_that.script,_that.reason);case BuddyIntentOutOfScope() when outOfScope != null:
return outOfScope(_that.kind,_that.language,_that.script,_that.reason);case BuddyIntentMedical() when medical != null:
return medical(_that.kind,_that.language,_that.script);case BuddyIntentWeighIn() when weighIn != null:
return weighIn(_that.kind,_that.language,_that.script,_that.value,_that.unit,_that.timeHint);case BuddyIntentUnrecognized() when unrecognized != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( BuddyFoodLogKind kind,  String language,  String script,  String? timeHint,  String? slotHint,  String? dishGroup,  List<BuddyFoodItem> items)  foodLog,required TResult Function( BuddyClarifyKind kind,  String language,  String script,  String reason)  clarify,required TResult Function( BuddyOutOfScopeKind kind,  String language,  String script,  String reason)  outOfScope,required TResult Function( BuddyMedicalKind kind,  String language,  String script)  medical,required TResult Function( BuddyWeighInKind kind,  String language,  String script,  double value,  String unit,  String? timeHint)  weighIn,required TResult Function()  unrecognized,}) {final _that = this;
switch (_that) {
case BuddyIntentFoodLog():
return foodLog(_that.kind,_that.language,_that.script,_that.timeHint,_that.slotHint,_that.dishGroup,_that.items);case BuddyIntentClarify():
return clarify(_that.kind,_that.language,_that.script,_that.reason);case BuddyIntentOutOfScope():
return outOfScope(_that.kind,_that.language,_that.script,_that.reason);case BuddyIntentMedical():
return medical(_that.kind,_that.language,_that.script);case BuddyIntentWeighIn():
return weighIn(_that.kind,_that.language,_that.script,_that.value,_that.unit,_that.timeHint);case BuddyIntentUnrecognized():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( BuddyFoodLogKind kind,  String language,  String script,  String? timeHint,  String? slotHint,  String? dishGroup,  List<BuddyFoodItem> items)?  foodLog,TResult? Function( BuddyClarifyKind kind,  String language,  String script,  String reason)?  clarify,TResult? Function( BuddyOutOfScopeKind kind,  String language,  String script,  String reason)?  outOfScope,TResult? Function( BuddyMedicalKind kind,  String language,  String script)?  medical,TResult? Function( BuddyWeighInKind kind,  String language,  String script,  double value,  String unit,  String? timeHint)?  weighIn,TResult? Function()?  unrecognized,}) {final _that = this;
switch (_that) {
case BuddyIntentFoodLog() when foodLog != null:
return foodLog(_that.kind,_that.language,_that.script,_that.timeHint,_that.slotHint,_that.dishGroup,_that.items);case BuddyIntentClarify() when clarify != null:
return clarify(_that.kind,_that.language,_that.script,_that.reason);case BuddyIntentOutOfScope() when outOfScope != null:
return outOfScope(_that.kind,_that.language,_that.script,_that.reason);case BuddyIntentMedical() when medical != null:
return medical(_that.kind,_that.language,_that.script);case BuddyIntentWeighIn() when weighIn != null:
return weighIn(_that.kind,_that.language,_that.script,_that.value,_that.unit,_that.timeHint);case BuddyIntentUnrecognized() when unrecognized != null:
return unrecognized();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class BuddyIntentFoodLog implements BuddyIntent {
  const BuddyIntentFoodLog({required this.kind, required this.language, required this.script, required this.timeHint, required this.slotHint, required this.dishGroup, required  List<BuddyFoodItem> items}): _items = items;
  factory BuddyIntentFoodLog.fromJson(Map<String, dynamic> json) => _$BuddyIntentFoodLogFromJson(json);

 final  BuddyFoodLogKind kind;
 final  String language;
 final  String script;
 final  String? timeHint;
 final  String? slotHint;
 final  String? dishGroup;
 final  List<BuddyFoodItem> _items;
 List<BuddyFoodItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentFoodLogCopyWith<BuddyIntentFoodLog> get copyWith => _$BuddyIntentFoodLogCopyWithImpl<BuddyIntentFoodLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentFoodLogToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentFoodLog&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint)&&(identical(other.slotHint, slotHint) || other.slotHint == slotHint)&&(identical(other.dishGroup, dishGroup) || other.dishGroup == dishGroup)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,timeHint,slotHint,dishGroup,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'BuddyIntent.foodLog(kind: $kind, language: $language, script: $script, timeHint: $timeHint, slotHint: $slotHint, dishGroup: $dishGroup, items: $items)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentFoodLogCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentFoodLogCopyWith(BuddyIntentFoodLog value, $Res Function(BuddyIntentFoodLog) _then) = _$BuddyIntentFoodLogCopyWithImpl;
@useResult
$Res call({
 BuddyFoodLogKind kind, String language, String script, String? timeHint, String? slotHint, String? dishGroup, List<BuddyFoodItem> items
});




}
/// @nodoc
class _$BuddyIntentFoodLogCopyWithImpl<$Res>
    implements $BuddyIntentFoodLogCopyWith<$Res> {
  _$BuddyIntentFoodLogCopyWithImpl(this._self, this._then);

  final BuddyIntentFoodLog _self;
  final $Res Function(BuddyIntentFoodLog) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? timeHint = freezed,Object? slotHint = freezed,Object? dishGroup = freezed,Object? items = null,}) {
  return _then(BuddyIntentFoodLog(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyFoodLogKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,dishGroup: freezed == dishGroup ? _self.dishGroup : dishGroup // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BuddyFoodItem>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyIntentClarify implements BuddyIntent {
  const BuddyIntentClarify({required this.kind, required this.language, required this.script, required this.reason});
  factory BuddyIntentClarify.fromJson(Map<String, dynamic> json) => _$BuddyIntentClarifyFromJson(json);

 final  BuddyClarifyKind kind;
 final  String language;
 final  String script;
 final  String reason;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentClarifyCopyWith<BuddyIntentClarify> get copyWith => _$BuddyIntentClarifyCopyWithImpl<BuddyIntentClarify>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentClarifyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentClarify&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,reason);
}

@override
String toString() {
    return 'BuddyIntent.clarify(kind: $kind, language: $language, script: $script, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentClarifyCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentClarifyCopyWith(BuddyIntentClarify value, $Res Function(BuddyIntentClarify) _then) = _$BuddyIntentClarifyCopyWithImpl;
@useResult
$Res call({
 BuddyClarifyKind kind, String language, String script, String reason
});




}
/// @nodoc
class _$BuddyIntentClarifyCopyWithImpl<$Res>
    implements $BuddyIntentClarifyCopyWith<$Res> {
  _$BuddyIntentClarifyCopyWithImpl(this._self, this._then);

  final BuddyIntentClarify _self;
  final $Res Function(BuddyIntentClarify) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? reason = null,}) {
  return _then(BuddyIntentClarify(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyClarifyKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyIntentOutOfScope implements BuddyIntent {
  const BuddyIntentOutOfScope({required this.kind, required this.language, required this.script, required this.reason});
  factory BuddyIntentOutOfScope.fromJson(Map<String, dynamic> json) => _$BuddyIntentOutOfScopeFromJson(json);

 final  BuddyOutOfScopeKind kind;
 final  String language;
 final  String script;
 final  String reason;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentOutOfScopeCopyWith<BuddyIntentOutOfScope> get copyWith => _$BuddyIntentOutOfScopeCopyWithImpl<BuddyIntentOutOfScope>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentOutOfScopeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentOutOfScope&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,reason);
}

@override
String toString() {
    return 'BuddyIntent.outOfScope(kind: $kind, language: $language, script: $script, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentOutOfScopeCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentOutOfScopeCopyWith(BuddyIntentOutOfScope value, $Res Function(BuddyIntentOutOfScope) _then) = _$BuddyIntentOutOfScopeCopyWithImpl;
@useResult
$Res call({
 BuddyOutOfScopeKind kind, String language, String script, String reason
});




}
/// @nodoc
class _$BuddyIntentOutOfScopeCopyWithImpl<$Res>
    implements $BuddyIntentOutOfScopeCopyWith<$Res> {
  _$BuddyIntentOutOfScopeCopyWithImpl(this._self, this._then);

  final BuddyIntentOutOfScope _self;
  final $Res Function(BuddyIntentOutOfScope) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? reason = null,}) {
  return _then(BuddyIntentOutOfScope(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyOutOfScopeKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyIntentMedical implements BuddyIntent {
  const BuddyIntentMedical({required this.kind, required this.language, required this.script});
  factory BuddyIntentMedical.fromJson(Map<String, dynamic> json) => _$BuddyIntentMedicalFromJson(json);

 final  BuddyMedicalKind kind;
 final  String language;
 final  String script;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentMedicalCopyWith<BuddyIntentMedical> get copyWith => _$BuddyIntentMedicalCopyWithImpl<BuddyIntentMedical>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentMedicalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentMedical&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script);
}

@override
String toString() {
    return 'BuddyIntent.medical(kind: $kind, language: $language, script: $script)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentMedicalCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentMedicalCopyWith(BuddyIntentMedical value, $Res Function(BuddyIntentMedical) _then) = _$BuddyIntentMedicalCopyWithImpl;
@useResult
$Res call({
 BuddyMedicalKind kind, String language, String script
});




}
/// @nodoc
class _$BuddyIntentMedicalCopyWithImpl<$Res>
    implements $BuddyIntentMedicalCopyWith<$Res> {
  _$BuddyIntentMedicalCopyWithImpl(this._self, this._then);

  final BuddyIntentMedical _self;
  final $Res Function(BuddyIntentMedical) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,}) {
  return _then(BuddyIntentMedical(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyMedicalKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyIntentWeighIn implements BuddyIntent {
  const BuddyIntentWeighIn({required this.kind, required this.language, required this.script, required this.value, required this.unit, required this.timeHint});
  factory BuddyIntentWeighIn.fromJson(Map<String, dynamic> json) => _$BuddyIntentWeighInFromJson(json);

 final  BuddyWeighInKind kind;
 final  String language;
 final  String script;
 final  double value;
 final  String unit;
 final  String? timeHint;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentWeighInCopyWith<BuddyIntentWeighIn> get copyWith => _$BuddyIntentWeighInCopyWithImpl<BuddyIntentWeighIn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentWeighInToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentWeighIn&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,value,unit,timeHint);
}

@override
String toString() {
    return 'BuddyIntent.weighIn(kind: $kind, language: $language, script: $script, value: $value, unit: $unit, timeHint: $timeHint)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentWeighInCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentWeighInCopyWith(BuddyIntentWeighIn value, $Res Function(BuddyIntentWeighIn) _then) = _$BuddyIntentWeighInCopyWithImpl;
@useResult
$Res call({
 BuddyWeighInKind kind, String language, String script, double value, String unit, String? timeHint
});




}
/// @nodoc
class _$BuddyIntentWeighInCopyWithImpl<$Res>
    implements $BuddyIntentWeighInCopyWith<$Res> {
  _$BuddyIntentWeighInCopyWithImpl(this._self, this._then);

  final BuddyIntentWeighIn _self;
  final $Res Function(BuddyIntentWeighIn) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? value = null,Object? unit = null,Object? timeHint = freezed,}) {
  return _then(BuddyIntentWeighIn(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyWeighInKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyIntentUnrecognized implements BuddyIntent {
  const BuddyIntentUnrecognized({ String? $type}): $type = $type ?? 'unrecognized';
  factory BuddyIntentUnrecognized.fromJson(Map<String, dynamic> json) => _$BuddyIntentUnrecognizedFromJson(json);



@JsonKey(name: 'kind')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentUnrecognizedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentUnrecognized);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BuddyIntent.unrecognized()';
}


}




// dart format on
