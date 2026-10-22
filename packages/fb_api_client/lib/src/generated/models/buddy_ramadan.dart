// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_ramadan.freezed.dart';
part 'buddy_ramadan.g.dart';

@Freezed()
abstract class BuddyRamadan with _$BuddyRamadan {
  const factory BuddyRamadan({
    required bool active,
    required String? fajr,
    required String? maghrib,
  }) = _BuddyRamadan;

  factory BuddyRamadan.fromJson(Map<String, Object?> json) =>
      _$BuddyRamadanFromJson(json);
}
