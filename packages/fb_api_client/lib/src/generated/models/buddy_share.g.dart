// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_share.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyShare _$BuddyShareFromJson(Map<String, dynamic> json) => _BuddyShare(
  fraction: (json['fraction'] as num?)?.toDouble(),
  people: (json['people'] as num?)?.toInt(),
);

Map<String, dynamic> _$BuddyShareToJson(_BuddyShare instance) =>
    <String, dynamic>{'fraction': instance.fraction, 'people': instance.people};
