// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_read_memory_args.freezed.dart';
part 'buddy_read_memory_args.g.dart';

@Freezed()
abstract class BuddyReadMemoryArgs with _$BuddyReadMemoryArgs {
  const factory BuddyReadMemoryArgs({required String? topic}) =
      _BuddyReadMemoryArgs;

  factory BuddyReadMemoryArgs.fromJson(Map<String, Object?> json) =>
      _$BuddyReadMemoryArgsFromJson(json);
}
