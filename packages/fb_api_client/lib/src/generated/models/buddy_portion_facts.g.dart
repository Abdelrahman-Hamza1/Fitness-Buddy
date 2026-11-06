// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_portion_facts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyPortionFacts _$BuddyPortionFactsFromJson(Map<String, dynamic> json) =>
    _BuddyPortionFacts(
      label: json['label'] as String,
      g: (json['g'] as num?)?.toDouble(),
      nutrients: BuddyNutrientsRequest.fromJson(
        json['nutrients'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$BuddyPortionFactsToJson(_BuddyPortionFacts instance) =>
    <String, dynamic>{
      'label': instance.label,
      'g': instance.g,
      'nutrients': instance.nutrients.toJson(),
    };
