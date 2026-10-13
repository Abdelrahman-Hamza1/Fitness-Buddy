// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FoodItem _$FoodItemFromJson(Map<String, dynamic> json) => _FoodItem(
  query: json['query'] as String,
  quantity: (json['quantity'] as num).toDouble(),
  unit: json['unit'] as String,
);

Map<String, dynamic> _$FoodItemToJson(_FoodItem instance) => <String, dynamic>{
  'query': instance.query,
  'quantity': instance.quantity,
  'unit': instance.unit,
};
