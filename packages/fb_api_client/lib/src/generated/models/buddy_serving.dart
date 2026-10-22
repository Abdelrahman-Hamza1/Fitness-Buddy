// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_serving.freezed.dart';
part 'buddy_serving.g.dart';

@Freezed()
abstract class BuddyServing with _$BuddyServing {
  const factory BuddyServing({
    required String unitCode,
    required double? g,
    required double? ml,
    required double? rangeLo,
    required double? rangeHi,
    required String source,
  }) = _BuddyServing;

  factory BuddyServing.fromJson(Map<String, Object?> json) =>
      _$BuddyServingFromJson(json);
}
