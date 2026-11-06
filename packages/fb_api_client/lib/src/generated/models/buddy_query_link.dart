// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_link_screen.dart';

part 'buddy_query_link.freezed.dart';
part 'buddy_query_link.g.dart';

@Freezed()
abstract class BuddyQueryLink with _$BuddyQueryLink {
  const factory BuddyQueryLink({
    required BuddyLinkScreen screen,
    required String? date,
    required String? from,
    required String? to,
    required String? exerciseRef,
    required String? workoutId,
  }) = _BuddyQueryLink;

  factory BuddyQueryLink.fromJson(Map<String, Object?> json) =>
      _$BuddyQueryLinkFromJson(json);
}
