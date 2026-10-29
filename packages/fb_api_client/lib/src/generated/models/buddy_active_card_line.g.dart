// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_active_card_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyActiveCardLine _$BuddyActiveCardLineFromJson(Map<String, dynamic> json) =>
    _BuddyActiveCardLine(
      name: json['name'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      unitCode: json['unitCode'] as String?,
      state: json['state'] as String?,
    );

Map<String, dynamic> _$BuddyActiveCardLineToJson(
  _BuddyActiveCardLine instance,
) => <String, dynamic>{
  'name': instance.name,
  'amount': instance.amount,
  'unitCode': instance.unitCode,
  'state': instance.state,
};
