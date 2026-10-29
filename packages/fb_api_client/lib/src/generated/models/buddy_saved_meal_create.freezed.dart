// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_saved_meal_create.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddySavedMealCreate {

 BuddySavedMealCreateKind get kind; String get language; String get script;/// Never null: a nameless "save this" is clarified.
 String get name;/// The request activeProposal ("save this").
 String? get activeProposal;/// Request recentEntries IDs to save.
 List<String> get targets;/// Day/slot to save from, for the app's local lookup.
 BuddyDayHint? get source;
/// Create a copy of BuddySavedMealCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddySavedMealCreateCopyWith<BuddySavedMealCreate> get copyWith => _$BuddySavedMealCreateCopyWithImpl<BuddySavedMealCreate>(this as BuddySavedMealCreate, _$identity);

  /// Serializes this BuddySavedMealCreate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddySavedMealCreate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddySavedMealCreate&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.activeProposal, _this.activeProposal) || other.activeProposal == _this.activeProposal)&&const DeepCollectionEquality().equals(other.targets, _this.targets)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddySavedMealCreate;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.name,_this.activeProposal,const DeepCollectionEquality().hash(_this.targets),_this.source);
}

@override
String toString() {
  final _this = this as BuddySavedMealCreate;
  return 'BuddySavedMealCreate(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, name: ${_this.name}, activeProposal: ${_this.activeProposal}, targets: ${_this.targets}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $BuddySavedMealCreateCopyWith<$Res>  {
  factory $BuddySavedMealCreateCopyWith(BuddySavedMealCreate value, $Res Function(BuddySavedMealCreate) _then) = _$BuddySavedMealCreateCopyWithImpl;
@useResult
$Res call({
 BuddySavedMealCreateKind kind, String language, String script, String name, String? activeProposal, List<String> targets, BuddyDayHint? source
});


$BuddyDayHintCopyWith<$Res>? get source;

}
/// @nodoc
class _$BuddySavedMealCreateCopyWithImpl<$Res>
    implements $BuddySavedMealCreateCopyWith<$Res> {
  _$BuddySavedMealCreateCopyWithImpl(this._self, this._then);

  final BuddySavedMealCreate _self;
  final $Res Function(BuddySavedMealCreate) _then;

/// Create a copy of BuddySavedMealCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? name = null,Object? activeProposal = freezed,Object? targets = null,Object? source = freezed,}) {
  return _then(BuddySavedMealCreate(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddySavedMealCreateKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,activeProposal: freezed == activeProposal ? _self.activeProposal : activeProposal // ignore: cast_nullable_to_non_nullable
as String?,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as List<String>,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BuddyDayHint?,
  ));
}
/// Create a copy of BuddySavedMealCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayHintCopyWith<$Res>? get source {
    if (_self.source == null) {
    return null;
  }

  return $BuddyDayHintCopyWith<$Res>(_self.source!, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddySavedMealCreate].
extension BuddySavedMealCreatePatterns on BuddySavedMealCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddySavedMealCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddySavedMealCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddySavedMealCreate value)  $default,){
final _that = this;
switch (_that) {
case _BuddySavedMealCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddySavedMealCreate value)?  $default,){
final _that = this;
switch (_that) {
case _BuddySavedMealCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddySavedMealCreateKind kind,  String language,  String script,  String name,  String? activeProposal,  List<String> targets,  BuddyDayHint? source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddySavedMealCreate() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.name,_that.activeProposal,_that.targets,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddySavedMealCreateKind kind,  String language,  String script,  String name,  String? activeProposal,  List<String> targets,  BuddyDayHint? source)  $default,) {final _that = this;
switch (_that) {
case _BuddySavedMealCreate():
return $default(_that.kind,_that.language,_that.script,_that.name,_that.activeProposal,_that.targets,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddySavedMealCreateKind kind,  String language,  String script,  String name,  String? activeProposal,  List<String> targets,  BuddyDayHint? source)?  $default,) {final _that = this;
switch (_that) {
case _BuddySavedMealCreate() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.name,_that.activeProposal,_that.targets,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddySavedMealCreate implements BuddySavedMealCreate {
  const _BuddySavedMealCreate({required this.kind, required this.language, required this.script, required this.name, required this.activeProposal, required  List<String> targets, required this.source}): _targets = targets;
  factory _BuddySavedMealCreate.fromJson(Map<String, dynamic> json) => _$BuddySavedMealCreateFromJson(json);

@override final  BuddySavedMealCreateKind kind;
@override final  String language;
@override final  String script;
/// Never null: a nameless "save this" is clarified.
@override final  String name;
/// The request activeProposal ("save this").
@override final  String? activeProposal;
/// Request recentEntries IDs to save.
 final  List<String> _targets;
/// Request recentEntries IDs to save.
@override List<String> get targets {
  if (_targets is EqualUnmodifiableListView) return _targets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targets);
}

/// Day/slot to save from, for the app's local lookup.
@override final  BuddyDayHint? source;

/// Create a copy of BuddySavedMealCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddySavedMealCreateCopyWith<_BuddySavedMealCreate> get copyWith => __$BuddySavedMealCreateCopyWithImpl<_BuddySavedMealCreate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddySavedMealCreateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddySavedMealCreate&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.name, name) || other.name == name)&&(identical(other.activeProposal, activeProposal) || other.activeProposal == activeProposal)&&const DeepCollectionEquality().equals(other.targets, _targets)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,name,activeProposal,const DeepCollectionEquality().hash(_targets),source);
}

@override
String toString() {
    return 'BuddySavedMealCreate(kind: $kind, language: $language, script: $script, name: $name, activeProposal: $activeProposal, targets: $targets, source: $source)';
}


}

/// @nodoc
abstract mixin class _$BuddySavedMealCreateCopyWith<$Res> implements $BuddySavedMealCreateCopyWith<$Res> {
  factory _$BuddySavedMealCreateCopyWith(_BuddySavedMealCreate value, $Res Function(_BuddySavedMealCreate) _then) = __$BuddySavedMealCreateCopyWithImpl;
@override @useResult
$Res call({
 BuddySavedMealCreateKind kind, String language, String script, String name, String? activeProposal, List<String> targets, BuddyDayHint? source
});


@override $BuddyDayHintCopyWith<$Res>? get source;

}
/// @nodoc
class __$BuddySavedMealCreateCopyWithImpl<$Res>
    implements _$BuddySavedMealCreateCopyWith<$Res> {
  __$BuddySavedMealCreateCopyWithImpl(this._self, this._then);

  final _BuddySavedMealCreate _self;
  final $Res Function(_BuddySavedMealCreate) _then;

/// Create a copy of BuddySavedMealCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? name = null,Object? activeProposal = freezed,Object? targets = null,Object? source = freezed,}) {
  return _then(_BuddySavedMealCreate(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddySavedMealCreateKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,activeProposal: freezed == activeProposal ? _self.activeProposal : activeProposal // ignore: cast_nullable_to_non_nullable
as String?,targets: null == targets ? _self._targets : targets // ignore: cast_nullable_to_non_nullable
as List<String>,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BuddyDayHint?,
  ));
}

/// Create a copy of BuddySavedMealCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayHintCopyWith<$Res>? get source {
    if (_self.source == null) {
    return null;
  }

  return $BuddyDayHintCopyWith<$Res>(_self.source!, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}

// dart format on
