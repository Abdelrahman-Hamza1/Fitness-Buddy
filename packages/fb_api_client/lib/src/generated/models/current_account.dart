// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'current_account.freezed.dart';
part 'current_account.g.dart';

@Freezed()
abstract class CurrentAccount with _$CurrentAccount {
  const factory CurrentAccount({
    required String userId,
    required bool isAnonymous,
    required String status,
  }) = _CurrentAccount;

  factory CurrentAccount.fromJson(Map<String, Object?> json) =>
      _$CurrentAccountFromJson(json);
}
