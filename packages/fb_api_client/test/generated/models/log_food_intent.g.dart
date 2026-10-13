// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_food_intent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LogFoodIntent _$LogFoodIntentFromJson(Map<String, dynamic> json) =>
    _LogFoodIntent(
      kind: json['kind'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      eatenAt: DateTime.parse(json['eatenAt'] as String),
      date: json['date'] as String?,
    );

Map<String, dynamic> _$LogFoodIntentToJson(_LogFoodIntent instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'eatenAt': instance.eatenAt.toIso8601String(),
      'date': instance.date,
    };
