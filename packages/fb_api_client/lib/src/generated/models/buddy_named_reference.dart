// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_named_reference.freezed.dart';
part 'buddy_named_reference.g.dart';

@Freezed()
abstract class BuddyNamedReference with _$BuddyNamedReference {
  const factory BuddyNamedReference({
    required String id,
    required String name,
  }) = _BuddyNamedReference;

  factory BuddyNamedReference.fromJson(Map<String, Object?> json) =>
      _$BuddyNamedReferenceFromJson(json);
}
