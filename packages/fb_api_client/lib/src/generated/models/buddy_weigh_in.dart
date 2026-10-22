// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_intent.dart';
import 'buddy_weigh_in_kind.dart';

part 'buddy_weigh_in.freezed.dart';
part 'buddy_weigh_in.g.dart';

@Freezed()
abstract class BuddyWeighIn with _$BuddyWeighIn {
  const factory BuddyWeighIn({
    required BuddyWeighInKind kind,
    required String language,
    required String script,
    required double value,
    required String unit,
    required String? timeHint,
  }) = _BuddyWeighIn;

  factory BuddyWeighIn.fromJson(Map<String, Object?> json) =>
      _$BuddyWeighInFromJson(json);
}
