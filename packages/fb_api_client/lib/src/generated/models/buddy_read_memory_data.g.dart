// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_memory_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadMemoryData _$BuddyReadMemoryDataFromJson(Map<String, dynamic> json) =>
    _BuddyReadMemoryData(
      items: (json['items'] as List<dynamic>)
          .map((e) => BuddyMemory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddyReadMemoryDataToJson(
  _BuddyReadMemoryData instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
