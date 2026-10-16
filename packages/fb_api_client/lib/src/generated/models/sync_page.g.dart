// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncPage _$SyncPageFromJson(Map<String, dynamic> json) => _SyncPage(
  changes: (json['changes'] as List<dynamic>)
      .map((e) => SyncDocument.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['nextCursor'] as String,
);

Map<String, dynamic> _$SyncPageToJson(_SyncPage instance) => <String, dynamic>{
  'changes': instance.changes.map((e) => e.toJson()).toList(),
  'nextCursor': instance.nextCursor,
};
