// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_portion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyPortion _$BuddyPortionFromJson(Map<String, dynamic> json) =>
    _BuddyPortion(
      amount: json['amount'] == null
          ? null
          : BuddyAmount.fromJson(json['amount'] as Map<String, dynamic>),
      share: json['share'] == null
          ? null
          : BuddyShare.fromJson(json['share'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyPortionToJson(_BuddyPortion instance) =>
    <String, dynamic>{
      'amount': instance.amount?.toJson(),
      'share': instance.share?.toJson(),
    };
