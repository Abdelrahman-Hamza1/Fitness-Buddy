// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_share.freezed.dart';
part 'buddy_share.g.dart';

@Freezed()
abstract class BuddyShare with _$BuddyShare {
  const factory BuddyShare({required double? fraction, required int? people}) =
      _BuddyShare;

  factory BuddyShare.fromJson(Map<String, Object?> json) =>
      _$BuddyShareFromJson(json);
}
