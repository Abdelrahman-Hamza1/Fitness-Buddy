// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_personal_food.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyPersonalFood _$BuddyPersonalFoodFromJson(
  Map<String, dynamic> json,
) => _BuddyPersonalFood(
  id: json['id'] as String,
  names: (json['names'] as List<dynamic>).map((e) => e as String).toList(),
  aliases: (json['aliases'] as List<dynamic>).map((e) => e as String).toList(),
  state: json['state'] as String,
  nutrients: BuddyNutrients.fromJson(json['nutrients'] as Map<String, dynamic>),
  servings: (json['servings'] as List<dynamic>)
      .map((e) => BuddyServing.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BuddyPersonalFoodToJson(_BuddyPersonalFood instance) =>
    <String, dynamic>{
      'id': instance.id,
      'names': instance.names,
      'aliases': instance.aliases,
      'state': instance.state,
      'nutrients': instance.nutrients.toJson(),
      'servings': instance.servings.map((e) => e.toJson()).toList(),
    };
