// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_body_read.dart';
import 'buddy_date_range.dart';

part 'buddy_read_body_args.freezed.dart';
part 'buddy_read_body_args.g.dart';

@Freezed()
abstract class BuddyReadBodyArgs with _$BuddyReadBodyArgs {
  const factory BuddyReadBodyArgs({
    required BuddyDateRange range,
    required BuddyBodyRead what,
  }) = _BuddyReadBodyArgs;

  factory BuddyReadBodyArgs.fromJson(Map<String, Object?> json) =>
      _$BuddyReadBodyArgsFromJson(json);
}
