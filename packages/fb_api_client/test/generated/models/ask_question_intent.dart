// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'intent.dart';

part 'ask_question_intent.freezed.dart';
part 'ask_question_intent.g.dart';

@Freezed()
abstract class AskQuestionIntent with _$AskQuestionIntent {
  const factory AskQuestionIntent({
    required String kind,
    required String question,
    required String? topic,
  }) = _AskQuestionIntent;

  factory AskQuestionIntent.fromJson(Map<String, Object?> json) =>
      _$AskQuestionIntentFromJson(json);
}
