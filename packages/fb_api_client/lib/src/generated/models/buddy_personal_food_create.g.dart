// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_personal_food_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyPersonalFoodCreate _$BuddyPersonalFoodCreateFromJson(
  Map<String, dynamic> json,
) => _BuddyPersonalFoodCreate(
  kind: BuddyPersonalFoodCreateKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  name: json['name'] as String,
  aliases: (json['aliases'] as List<dynamic>).map((e) => e as String).toList(),
  components: (json['components'] as List<dynamic>)
      .map((e) => BuddyFoodItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  stated: json['stated'] == null
      ? null
      : BuddyStatedNutrients.fromJson(json['stated'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyPersonalFoodCreateToJson(
  _BuddyPersonalFoodCreate instance,
) => <String, dynamic>{
  'kind': _$BuddyPersonalFoodCreateKindEnumMap[instance.kind]!,
  'language': instance.language,
  'script': instance.script,
  'name': instance.name,
  'aliases': instance.aliases,
  'components': instance.components.map((e) => e.toJson()).toList(),
  'stated': instance.stated?.toJson(),
};

const _$BuddyPersonalFoodCreateKindEnumMap = {
  BuddyPersonalFoodCreateKind.personalFoodCreate: 'personalFoodCreate',
  BuddyPersonalFoodCreateKind.$unknown: r'$unknown',
};
