// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_personal_kind.dart';

part 'buddy_find_my_foods_args.freezed.dart';
part 'buddy_find_my_foods_args.g.dart';

@Freezed()
abstract class BuddyFindMyFoodsArgs with _$BuddyFindMyFoodsArgs {
  const factory BuddyFindMyFoodsArgs({
    required String query,

    /// Empty means every kind.
    required List<BuddyPersonalKind> kinds,
  }) = _BuddyFindMyFoodsArgs;

  factory BuddyFindMyFoodsArgs.fromJson(Map<String, Object?> json) =>
      _$BuddyFindMyFoodsArgsFromJson(json);
}
