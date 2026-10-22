// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_food_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyFoodItem _$BuddyFoodItemFromJson(Map<String, dynamic> json) =>
    _BuddyFoodItem(
      mention: json['mention'] as String,
      match: json['match'] == null
          ? null
          : BuddyCandidate.fromJson(json['match'] as Map<String, dynamic>),
      alternatives: (json['alternatives'] as List<dynamic>)
          .map((e) => BuddyCandidate.fromJson(e as Map<String, dynamic>))
          .toList(),
      amount: BuddyAmount.fromJson(json['amount'] as Map<String, dynamic>),
      share: json['share'] == null
          ? null
          : BuddyShare.fromJson(json['share'] as Map<String, dynamic>),
      dimensions: (json['dimensions'] as List<dynamic>)
          .map((e) => BuddyDimension.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimate: json['estimate'] == null
          ? null
          : BuddyEstimate.fromJson(json['estimate'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyFoodItemToJson(_BuddyFoodItem instance) =>
    <String, dynamic>{
      'mention': instance.mention,
      'match': instance.match?.toJson(),
      'alternatives': instance.alternatives.map((e) => e.toJson()).toList(),
      'amount': instance.amount.toJson(),
      'share': instance.share?.toJson(),
      'dimensions': instance.dimensions.map((e) => e.toJson()).toList(),
      'estimate': instance.estimate?.toJson(),
    };
