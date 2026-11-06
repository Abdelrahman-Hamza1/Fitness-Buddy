// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_personal_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyPersonalItem _$BuddyPersonalItemFromJson(
  Map<String, dynamic> json,
) => _BuddyPersonalItem(
  kind: BuddyPersonalKind.fromJson(json['kind'] as String),
  ref: json['ref'] as String,
  names: (json['names'] as List<dynamic>).map((e) => e as String).toList(),
  aliases: (json['aliases'] as List<dynamic>).map((e) => e as String).toList(),
  state: json['state'] as String?,
  per100: json['per100'] == null
      ? null
      : BuddyNutrientsRequest.fromJson(json['per100'] as Map<String, dynamic>),
  servings: (json['servings'] as List<dynamic>)
      .map((e) => BuddyServing.fromJson(e as Map<String, dynamic>))
      .toList(),
  portions: (json['portions'] as List<dynamic>)
      .map((e) => BuddyPortionFacts.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BuddyPersonalItemToJson(_BuddyPersonalItem instance) =>
    <String, dynamic>{
      'kind': _$BuddyPersonalKindEnumMap[instance.kind]!,
      'ref': instance.ref,
      'names': instance.names,
      'aliases': instance.aliases,
      'state': instance.state,
      'per100': instance.per100?.toJson(),
      'servings': instance.servings.map((e) => e.toJson()).toList(),
      'portions': instance.portions.map((e) => e.toJson()).toList(),
    };

const _$BuddyPersonalKindEnumMap = {
  BuddyPersonalKind.personalFood: 'personalFood',
  BuddyPersonalKind.savedMeal: 'savedMeal',
  BuddyPersonalKind.batch: 'batch',
  BuddyPersonalKind.usual: 'usual',
  BuddyPersonalKind.$unknown: r'$unknown',
};
