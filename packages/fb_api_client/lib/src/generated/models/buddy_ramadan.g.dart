// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_ramadan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyRamadan _$BuddyRamadanFromJson(Map<String, dynamic> json) =>
    _BuddyRamadan(
      active: json['active'] as bool,
      fajr: json['fajr'] as String?,
      maghrib: json['maghrib'] as String?,
    );

Map<String, dynamic> _$BuddyRamadanToJson(_BuddyRamadan instance) =>
    <String, dynamic>{
      'active': instance.active,
      'fajr': instance.fajr,
      'maghrib': instance.maghrib,
    };
