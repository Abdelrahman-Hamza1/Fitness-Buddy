// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_query_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyQueryLink _$BuddyQueryLinkFromJson(Map<String, dynamic> json) =>
    _BuddyQueryLink(
      screen: BuddyLinkScreen.fromJson(json['screen'] as String),
      date: json['date'] as String?,
      from: json['from'] as String?,
      to: json['to'] as String?,
      exerciseRef: json['exerciseRef'] as String?,
      workoutId: json['workoutId'] as String?,
    );

Map<String, dynamic> _$BuddyQueryLinkToJson(_BuddyQueryLink instance) =>
    <String, dynamic>{
      'screen': _$BuddyLinkScreenEnumMap[instance.screen]!,
      'date': instance.date,
      'from': instance.from,
      'to': instance.to,
      'exerciseRef': instance.exerciseRef,
      'workoutId': instance.workoutId,
    };

const _$BuddyLinkScreenEnumMap = {
  BuddyLinkScreen.diary: 'diary',
  BuddyLinkScreen.weightGraph: 'weightGraph',
  BuddyLinkScreen.progress: 'progress',
  BuddyLinkScreen.exercise: 'exercise',
  BuddyLinkScreen.workout: 'workout',
  BuddyLinkScreen.$unknown: r'$unknown',
};
