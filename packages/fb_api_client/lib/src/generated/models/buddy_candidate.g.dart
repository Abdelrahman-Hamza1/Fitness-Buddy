// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyCandidate _$BuddyCandidateFromJson(Map<String, dynamic> json) =>
    _BuddyCandidate(
      key: json['key'] as String,
      nameEn: json['nameEn'] as String,
      nameAr: json['nameAr'] as String?,
      state: json['state'] as String,
      source: json['source'] as String,
      nutrients: BuddyNutrients.fromJson(
        json['nutrients'] as Map<String, dynamic>,
      ),
      ranges: json['ranges'] == null
          ? null
          : BuddyRange.fromJson(json['ranges'] as Map<String, dynamic>),
      servings: (json['servings'] as List<dynamic>)
          .map((e) => BuddyServing.fromJson(e as Map<String, dynamic>))
          .toList(),
      densityGPerMl: (json['densityGPerMl'] as num?)?.toDouble(),
      yieldGroup: json['yieldGroup'] as String?,
    );

Map<String, dynamic> _$BuddyCandidateToJson(_BuddyCandidate instance) =>
    <String, dynamic>{
      'key': instance.key,
      'nameEn': instance.nameEn,
      'nameAr': instance.nameAr,
      'state': instance.state,
      'source': instance.source,
      'nutrients': instance.nutrients.toJson(),
      'ranges': instance.ranges?.toJson(),
      'servings': instance.servings.map((e) => e.toJson()).toList(),
      'densityGPerMl': instance.densityGPerMl,
      'yieldGroup': instance.yieldGroup,
    };
