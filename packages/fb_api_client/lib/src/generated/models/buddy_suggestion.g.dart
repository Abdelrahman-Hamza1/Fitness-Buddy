// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_suggestion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddySuggestion _$BuddySuggestionFromJson(Map<String, dynamic> json) =>
    _BuddySuggestion(
      kind: BuddySuggestionKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => BuddySuggestionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddySuggestionToJson(_BuddySuggestion instance) =>
    <String, dynamic>{
      'kind': _$BuddySuggestionKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'options': instance.options.map((e) => e.toJson()).toList(),
    };

const _$BuddySuggestionKindEnumMap = {
  BuddySuggestionKind.suggestion: 'suggestion',
  BuddySuggestionKind.$unknown: r'$unknown',
};
