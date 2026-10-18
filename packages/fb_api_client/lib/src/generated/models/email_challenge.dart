// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'email_challenge.freezed.dart';
part 'email_challenge.g.dart';

@Freezed()
abstract class EmailChallenge with _$EmailChallenge {
  const factory EmailChallenge({
    required String challengeId,
    required DateTime expiresAt,
  }) = _EmailChallenge;

  factory EmailChallenge.fromJson(Map<String, Object?> json) =>
      _$EmailChallengeFromJson(json);
}
