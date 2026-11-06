// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_body_args.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadBodyArgs _$BuddyReadBodyArgsFromJson(Map<String, dynamic> json) =>
    _BuddyReadBodyArgs(
      range: BuddyDateRange.fromJson(json['range'] as Map<String, dynamic>),
      what: BuddyBodyRead.fromJson(json['what'] as String),
    );

Map<String, dynamic> _$BuddyReadBodyArgsToJson(_BuddyReadBodyArgs instance) =>
    <String, dynamic>{
      'range': instance.range.toJson(),
      'what': _$BuddyBodyReadEnumMap[instance.what]!,
    };

const _$BuddyBodyReadEnumMap = {
  BuddyBodyRead.weight: 'weight',
  BuddyBodyRead.trend: 'trend',
  BuddyBodyRead.measurements: 'measurements',
  BuddyBodyRead.$unknown: r'$unknown',
};
