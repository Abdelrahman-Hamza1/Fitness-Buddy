// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_entry_reference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyEntryReference _$BuddyEntryReferenceFromJson(Map<String, dynamic> json) =>
    _BuddyEntryReference(
      mention: json['mention'] as String,
      dateHint: json['dateHint'] as String?,
      slotHint: json['slotHint'] as String?,
      scope: BuddyReferenceScope.fromJson(json['scope'] as String),
    );

Map<String, dynamic> _$BuddyEntryReferenceToJson(
  _BuddyEntryReference instance,
) => <String, dynamic>{
  'mention': instance.mention,
  'dateHint': instance.dateHint,
  'slotHint': instance.slotHint,
  'scope': _$BuddyReferenceScopeEnumMap[instance.scope]!,
};

const _$BuddyReferenceScopeEnumMap = {
  BuddyReferenceScope.one: 'one',
  BuddyReferenceScope.all: 'all',
  BuddyReferenceScope.$unknown: r'$unknown',
};
