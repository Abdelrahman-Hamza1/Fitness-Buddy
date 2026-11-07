// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_label_extraction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyLabelExtraction _$BuddyLabelExtractionFromJson(
  Map<String, dynamic> json,
) => _BuddyLabelExtraction(
  found: json['found'] as bool,
  basis: json['basis'] == null
      ? null
      : BuddyLabelBasis.fromJson(json['basis'] as String),
  serving: json['serving'] == null
      ? null
      : BuddyLabelServing.fromJson(json['serving'] as Map<String, dynamic>),
  name: BuddyLabelText.fromJson(json['name'] as Map<String, dynamic>),
  nutrients: BuddyLabelNutrients.fromJson(
    json['nutrients'] as Map<String, dynamic>,
  ),
  others: (json['others'] as List<dynamic>)
      .map((e) => BuddyLabelOther.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BuddyLabelExtractionToJson(
  _BuddyLabelExtraction instance,
) => <String, dynamic>{
  'found': instance.found,
  'basis': _$BuddyLabelBasisEnumMap[instance.basis],
  'serving': instance.serving?.toJson(),
  'name': instance.name.toJson(),
  'nutrients': instance.nutrients.toJson(),
  'others': instance.others.map((e) => e.toJson()).toList(),
};

const _$BuddyLabelBasisEnumMap = {
  BuddyLabelBasis.per100g: 'per100g',
  BuddyLabelBasis.per100ml: 'per100ml',
  BuddyLabelBasis.perServing: 'perServing',
  BuddyLabelBasis.$unknown: r'$unknown',
};
