// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_suggestion_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddySuggestionOption _$BuddySuggestionOptionFromJson(
  Map<String, dynamic> json,
) => _BuddySuggestionOption(
  label: json['label'] as String,
  slotHint: json['slotHint'] as String?,
  items: (json['items'] as List<dynamic>)
      .map((e) => BuddyFoodItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BuddySuggestionOptionToJson(
  _BuddySuggestionOption instance,
) => <String, dynamic>{
  'label': instance.label,
  'slotHint': instance.slotHint,
  'items': instance.items.map((e) => e.toJson()).toList(),
};
