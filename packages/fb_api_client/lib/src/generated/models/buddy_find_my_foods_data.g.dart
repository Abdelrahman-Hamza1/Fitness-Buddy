// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_find_my_foods_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyFindMyFoodsData _$BuddyFindMyFoodsDataFromJson(
  Map<String, dynamic> json,
) => _BuddyFindMyFoodsData(
  items: (json['items'] as List<dynamic>)
      .map((e) => BuddyPersonalItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BuddyFindMyFoodsDataToJson(
  _BuddyFindMyFoodsData instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
