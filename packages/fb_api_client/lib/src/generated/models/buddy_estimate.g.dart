// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_estimate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyEstimate _$BuddyEstimateFromJson(Map<String, dynamic> json) =>
    _BuddyEstimate(
      range: BuddyRange.fromJson(json['range'] as Map<String, dynamic>),
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$BuddyEstimateToJson(_BuddyEstimate instance) =>
    <String, dynamic>{
      'range': instance.range.toJson(),
      'reason': instance.reason,
    };
