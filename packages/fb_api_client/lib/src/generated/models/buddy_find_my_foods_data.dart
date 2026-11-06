// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_personal_item.dart';

part 'buddy_find_my_foods_data.freezed.dart';
part 'buddy_find_my_foods_data.g.dart';

@Freezed()
abstract class BuddyFindMyFoodsData with _$BuddyFindMyFoodsData {
  const factory BuddyFindMyFoodsData({required List<BuddyPersonalItem> items}) =
      _BuddyFindMyFoodsData;

  factory BuddyFindMyFoodsData.fromJson(Map<String, Object?> json) =>
      _$BuddyFindMyFoodsDataFromJson(json);
}
